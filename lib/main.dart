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
      title: 'Avatar',
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

// ==================================================
// AUTH GATE
// ==================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
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

// ==================================================
// WELCOME SCREEN
// ==================================================

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
                  child: Icon(
                    Icons.person,
                    size: 80,
                  ),
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
                          builder: (_) =>
                              const CreateAccountScreen(),
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

// ==================================================
// CREATE ACCOUNT
// ==================================================

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
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty) {
      showMessage('Name भरें');
      return;
    }

    if (email.isEmpty) {
      showMessage('Email भरें');
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password कम से कम 6 characters का होना चाहिए',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

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
      }

      showMessage(message);
    } catch (e) {
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
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
                keyboardType:
                    TextInputType.emailAddress,
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
                  prefixIcon:
                      const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
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
                  onPressed:
                      loading ? null : createAccount,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(),
                        )
                      : const Text(
                          'Create Account',
                        ),
                ),
              ),

              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PhoneAuthScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.phone_android,
                ),
                label: const Text(
                  'Create Account with Phone OTP',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// LOGIN
// ==================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
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
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        message = 'Email या password गलत है';
      } else if (e.code == 'invalid-email') {
        message = 'Email सही नहीं है';
      }

      showMessage(message);
    } catch (e) {
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
      SnackBar(
        content: Text(message),
      ),
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
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.account_circle,
                size: 100,
              ),

              const SizedBox(height: 20),

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
                keyboardType:
                    TextInputType.emailAddress,
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
                  prefixIcon:
                      const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
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
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(),
                        )
                      : const Text('Login'),
                ),
              ),

              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PhoneAuthScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.phone_android,
                ),
                label: const Text(
                  'Login with Phone OTP',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// PHONE OTP
// ==================================================

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() =>
      _PhoneAuthScreenState();
}

class _PhoneAuthScreenState
    extends State<PhoneAuthScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool codeSent = false;
  bool loading = false;

  String? verificationId;

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showMessage('Phone number डालें');
      return;
    }

    if (!phone.startsWith('+')) {
      showMessage(
        'Country code के साथ number डालें, जैसे +91XXXXXXXXXX',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance
                .signInWithCredential(
              credential,
            );
          } catch (e) {
            if (mounted) {
              showMessage(
                'Automatic verification failed',
              );
            }
          }
        },

        verificationFailed:
            (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            loading = false;
          });

          String message =
              'OTP भेजने में समस्या हुई';

          if (e.code ==
              'invalid-phone-number') {
            message = 'Phone number सही नहीं है';
          } else if (e.code ==
              'too-many-requests') {
            message =
                'बहुत ज्यादा attempts हो गए। थोड़ी देर बाद try करें';
          } else if (e.code ==
              'quota-exceeded') {
            message =
                'Firebase SMS quota समाप्त हो गया है';
          } else if (e.code ==
              'operation-not-allowed') {
            message =
                'Firebase में Phone Authentication enable करें';
          }

          showMessage(message);
        },

        codeSent:
            (String id, int? resendToken) {
          if (!mounted) return;

          setState(() {
            verificationId = id;
            codeSent = true;
            loading = false;
          });

          showMessage('OTP भेज दिया गया है');
        },

        codeAutoRetrievalTimeout:
            (String id) {
          verificationId = id;

          if (mounted) {
            setState(() {
              loading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });

        showMessage(
          'OTP भेजने में समस्या हुई',
        );
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
      final credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance
          .signInWithCredential(
        credential,
      );
    } on FirebaseAuthException catch (e) {
      String message =
          'OTP verify नहीं हुआ';

      if (e.code ==
          'invalid-verification-code') {
        message = 'OTP गलत है';
      } else if (e.code ==
          'session-expired') {
        message =
            'OTP expire हो गया। नया OTP भेजें';
      }

      showMessage(message);
    } catch (e) {
      showMessage(
        'OTP verify करने में समस्या हुई',
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 25),

              const Icon(
                Icons.phone_android,
                size: 90,
              ),

              const SizedBox(height: 20),

              const Text(
                'Phone Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'अपने phone number पर OTP प्राप्त करें',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              TextField(
                controller: phoneContr
