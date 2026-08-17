import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AvatarApp());
}

class AvatarApp extends StatelessWidget {
  const AvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avatar App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}

// --------------------------------------------------
// WELCOME
// --------------------------------------------------

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 70,
                  child: Icon(Icons.person, size: 80),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Avatar',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Create your avatar and enter your world.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAccountScreen(),
                        ),
                      );
                    },
                    child: const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// CREATE ACCOUNT
// --------------------------------------------------

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState
    extends State<CreateAccountScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  bool loading = false;
  bool otpSent = false;
  bool phoneVerified = false;
  bool hidePassword = true;

  String? verificationId;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String getFormattedPhone() {
    String phone = phoneController.text.trim();

    if (phone.startsWith('+')) {
      return phone;
    }

    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    return '+91$phone';
  }

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showMessage('Phone Number भरें');
      return;
    }

    if (phone.length != 10) {
      showMessage('10 digit Indian mobile number डालें');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: getFormattedPhone(),

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(
              credential,
            );

            if (mounted) {
              setState(() {
                phoneVerified = true;
                otpSent = false;
              });
            }

            showMessage('Phone automatically verified!');
          } catch (_) {
            showMessage('Phone verification failed');
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          String message = 'OTP भेजने में समस्या हुई';

          if (e.code == 'invalid-phone-number') {
            message = 'Phone number सही नहीं है';
          } else if (e.code == 'too-many-requests') {
            message = 'बहुत ज्यादा attempts हो गए। बाद में try करें';
          }

          showMessage(message);

          if (mounted) {
            setState(() {
              loading = false;
            });
          }
        },

        codeSent: (String id, int? resendToken) {
          verificationId = id;

          if (mounted) {
            setState(() {
              otpSent = true;
              loading = false;
            });
          }

          showMessage('OTP भेज दिया गया');
        },

        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;

          if (mounted) {
            setState(() {
              loading = false;
            });
          }
        },
      );
    } catch (_) {
      showMessage('OTP भेजने में समस्या हुई');

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> verifyOTP() async {
    final otp = otpController.text.trim();

    if (verificationId == null) {
      showMessage('पहले OTP भेजें');
      return;
    }

    if (otp.length != 6) {
      showMessage('6 digit OTP डालें');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
      } else {
        await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      if (mounted) {
        setState(() {
          phoneVerified = true;
          otpSent = false;
          loading = false;
        });
      }

      showMessage('Phone number verified successfully!');
    } on FirebaseAuthException catch (e) {
      String message = 'OTP verification failed';

      if (e.code == 'invalid-verification-code') {
        message = 'OTP गलत है';
      } else if (e.code == 'session-expired') {
        message = 'OTP expire हो गया। नया OTP भेजें';
      } else if (e.code == 'credential-already-in-use') {
        message = 'यह phone number किसी दूसरे account से जुड़ा है';
      }

      showMessage(message);

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (_) {
      showMessage('OTP verification failed');

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty) {
      showMessage('Name भरें');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email और password भरें');
      return;
    }

    if (password.length < 6) {
      showMessage('Password कम से कम 6 characters का होना चाहिए');
      return;
    }

    if (!phoneVerified) {
      showMessage('पहले Phone Number verify करें');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMessage('Phone verification के बाद फिर से try करें');
        return;
      }

      final credential =
          EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'provider-already-linked') {
          rethrow;
        }
      }

      await user.updateDisplayName(name);

      if (!mounted) return;

      showMessage('Account successfully created!');
    } on FirebaseAuthException catch (e) {
      String message = 'Account नहीं बन पाया';

      if (e.code == 'email-already-in-use') {
        message = 'यह email पहले से registered है';
      } else if (e.code == 'invalid-email') {
        message = 'Email सही नहीं है';
      } else if (e.code == 'weak-password') {
        message = 'Password बहुत weak है';
      } else if (e.code == 'provider-already-linked') {
        message = 'यह email पहले से linked है';
      }

      showMessage(message);
    } catch (_) {
      showMessage('कुछ गलत हो गया');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                enabled: !phoneVerified,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '10 digit mobile number',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: phoneVerified
                      ? const Icon(
                          Icons.verified,
                          color: Colors.green,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 12),

              if (!phoneVerified)
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : sendOTP,
                    icon: const Icon(Icons.sms),
                    label: Text(
                      otpSent ? 'Resend OTP' : 'Send OTP',
                    ),
                  ),
                ),

              if (otpSent && !phoneVerified) ...[
                const SizedBox(height: 16),

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: loading ? null : verifyOTP,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Verify OTP'),
                  ),
                ),
              ],

              if (phoneVerified) ...[
                const SizedBox(height: 8),
                const Text(
                  'Phone number verified ✓',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: loading ? null : createAccount,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// LOGIN
// --------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email और password भरें');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'इस email से कोई account नहीं मिला';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Email या password गलत है';
      } else if (e.code == 'invalid-email') {
        message = 'Email सही नहीं है';
      }

      showMessage(message);
    } catch (_) {
      showMessage('कुछ गलत हो गया');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.account_circle,
                size: 100,
              ),

              const SizedBox(height: 25),

              const Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// HOME
// --------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                child: Icon(
                  Icons.person,
                  size: 70,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Avatar!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.email ?? user?.phoneNumber ?? '',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                'Your avatar journey starts here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
