import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AvatarApp());
}

// ==================================================
// GLOBAL AVATAR STATE
// ==================================================

class AvatarState {
  static String currentModel = 'assets/models/New_Project_18082026.glb';
  static Color skinColor = const Color(0xFFFFDFC4);
  static String faceStyle = 'Classic';
  static String eyeStyle = 'Normal';
  static String hairStyle = 'Hair Style 1';
  static String hairColor = 'Black';
  static String topClothes = 'T-Shirt';
  static String bottomClothes = 'Jeans';
  static String shoesStyle = 'Sneakers';
  static String accessory = 'Watch';
}

// ==================================================
// APP
// ==================================================

class AvatarApp extends StatelessWidget {
  const AvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avatar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
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
// WELCOME
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

// ==================================================
// CREATE ACCOUNT
// ==================================================

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please enter email and password.');
      return;
    }

    if (password.length < 6) {
      _showMessage(context, 'Password must be at least 6 characters.');
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

      if (name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
      }

      if (!mounted) return;

      _showMessage(context, 'Account created successfully!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Account creation failed.';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }

      _showMessage(context, message);
    } catch (_) {
      _showMessage(context, 'Something went wrong.');
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
                  onPressed: loading ? null : createAccount,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(),
                        )
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

// ==================================================
// LOGIN
// ==================================================

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
      _showMessage(context, 'Please enter email and password.');
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
      String message = 'Login failed.';

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email.';
      }

      _showMessage(context, message);
    } catch (_) {
      _showMessage(context, 'Something went wrong.');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
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
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(),
                        )
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

// ==================================================
// HOME
// ==================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomeTab(),
    AvatarScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Avatar',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ==================================================
// HOME TAB
// ==================================================

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Avatar',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : user?.email ?? 'User',
              style: const TextStyle(
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ModelViewer(
                  src: AvatarState.currentModel,
                  alt: 'My 3D Avatar',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAvatarScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Avatar',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AvatarScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Customize Avatar',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// AVATAR SCREEN
// ==================================================

class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Avatar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ModelViewer(
                  src: AvatarState.currentModel,
                  alt: 'My 3D Avatar',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAvatarScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Create / Customize Avatar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// CREATE / CUSTOMIZE AVATAR
// ==================================================

class CreateAvatarScreen extends StatefulWidget {
  const CreateAvatarScreen({super.key});

  @override
  State<CreateAvatarScreen> createState() => _CreateAvatarScreenState();
}

class _CreateAvatarScreenState extends State<CreateAvatarScreen> {
  Key modelKey = UniqueKey();

  void _refresh() {
    setState(() {
      modelKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Avatar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3D MODEL
            SizedBox(
              height: 350,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ModelViewer(
                  key: modelKey,
                  src: AvatarState.currentModel,
                  alt: 'My 3D Avatar',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Customize your Avatar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _optionButton(
              context,
              'Appearance',
              Icons.face,
              () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                );
                if (res == true) _refresh();
              },
            ),
            _optionButton(
              context,
              'Hair',
              Icons.face_retouching_natural,
              () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HairScreen()),
                );
                if (res == true) _refresh();
              },
            ),
            _optionButton(
              context,
              'Clothes',
              Icons.checkroom,
              () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClothesScreen()),
                );
                if (res == true) _refresh();
              },
            ),
            _optionButton(
              context,
              'Shoes',
              Icons.directions_walk,
              () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShoesScreen()),
                );
                if (res == true) _refresh();
              },
            ),
            _optionButton(
              context,
              'Accessories',
              Icons.watch,
              () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccessoriesScreen()),
                );
                if (res == true) _refresh();
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: () {
                  _showMessage(context, 'Avatar saved successfully!');
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save Avatar',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(title),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
        ),
      ),
    );
  }
}

// ==================================================
// APPEARANCE CUSTOMIZATION
// ==================================================

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  Color _selectedTone = AvatarState.skinColor;
  String _selectedFace = AvatarState.faceStyle;
  String _selectedEyes = AvatarState.eyeStyle;

  final List<Color> _tones = const [
    Color(0xFFFFDFC4), // Fair Tone
    Color(0xFFFFCD94), // Peach Tone
    Color(0xFFEAC086), // Warm Beige
    Color(0xFFD89B5F), // Tan Tone
    Color(0xFF8D5524), // Brown Tone
    Color(0xFF4A2A18), // Deep Tone
  ];

  void _showSkinTonePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 210,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Skin Tone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _tones.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTone = color;
                        AvatarState.skinColor = color;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedTone == color ? Colors.deepPurple : Colors.grey.shade300,
                          width: _selectedTone == color ? 3.5 : 1.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFacePicker() {
    final faces = ['Classic', 'Round Face', 'Chiseled', 'Cute Style'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: faces.map((face) {
            return ListTile(
              title: Text(face),
              trailing: _selectedFace == face ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
              onTap: () {
                setState(() {
                  _selectedFace = face;
                  AvatarState.faceStyle = face;
                });
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showEyesPicker() {
    final eyes = ['Normal', 'Anime Style', 'Smile / Closed', 'Sharp Eyes'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: eyes.map((eye) {
            return ListTile(
              title: Text(eye),
              trailing: _selectedEyes == eye ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
              onTap: () {
                setState(() {
                  _selectedEyes = eye;
                  AvatarState.eyeStyle = eye;
                });
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customize Appearance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // SKIN TONE
            const Text('Skin Tone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _showSkinTonePicker,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: _selectedTone, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  const Text('Choose Skin Tone'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FACE
            const Text('Face', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _showFacePicker,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Face: $_selectedFace'),
              ),
            ),

            const SizedBox(height: 20),

            // EYES
            const Text('Eyes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _showEyesPicker,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Eyes: $_selectedEyes'),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: () {
                  _showMessage(context, 'Appearance saved successfully!');
                  Navigator.pop(context, true);
                },
                child: const Text('Save Appearance', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// HAIR CUSTOMIZATION
// ==================================================

class HairScreen extends StatefulWidget {
  const HairScreen({super.key});

  @override
  State<HairScreen> createState() => _HairScreenState();
}

class _HairScreenState extends State<HairScreen> {
  String _selectedStyle = AvatarState.hairStyle;
  String _selectedColor = AvatarState.hairColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hair'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customize Hair',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            const Text('Hair Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...['Hair Style 1', 'Hair Style 2', 'Hair Style 3'].map((style) {
              final isSelected = _selectedStyle == style;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedStyle = style;
                      AvatarState.hairStyle = style;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(style),
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.deepPurple),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            const Text('Hair Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...['Black', 'Brown', 'Blonde'].map((col) {
              final isSelected = _selectedColor == col;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedColor = col;
                      AvatarState.hairColor = col;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(col),
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.deepPurple),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: () {
                  _showMessage(context, 'Hair saved successfully!');
                  Navigator.pop(context, true);
                },
                child: const Text('Save Hair', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// CLOTHES CUSTOMIZATION
// ==================================================

class ClothesScreen extends StatefulWidget {
  const ClothesScreen({super.key});

  @override
  State<ClothesScreen> createState() => _ClothesScreenState();
}

class _ClothesScreenState extends State<ClothesScreen> {
  String _selectedTop = AvatarState.topClothes;
  String _selectedBottom = AvatarState.bottomClothes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customize Clothes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            const Text('Top', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...['T-Shirt', 'Shirt', 'Jacket'].map((top) {
              final isSelected = _selectedTop == top;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedTop = top;
                      AvatarState.topClothes = top;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(top),
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.deepPurple),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            const Text('Bottom', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...['Jeans', 'Pants', 'Shorts'].map((bottom) {
              final isSelected = _selectedBottom == bottom;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedBottom = bottom;
                      AvatarState.bottomClothes = bottom;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(bottom),
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.deepPurple),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: () {
                  _showMessage(context, 'Clothes saved successfully!');
                  Navigator.pop(context, true);
                },
                child: const Text('Save Clothes', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// SHOES CUSTOMIZATION
// ==================================================

class ShoesScreen extends StatefulWidget {
  const ShoesScreen({super.key});

  @override
  State<ShoesScreen> createState() => _ShoesScreenState();
}

class _ShoesScreenState extends State<ShoesScreen> {
  String _selectedShoe = AvatarState.shoesStyle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customize Shoes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            const Text('Shoe Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...['Sneakers', 'Sports Shoes', 'Formal Shoes', 'Boots'].map((shoe) {
              final isSelected = _selectedShoe == shoe;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedShoe = shoe;
                      AvatarState.shoesStyle = shoe;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(shoe),
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.deepPurple),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: () {
                  _showMessage(context, 'Shoes saved successfully!');
                  Navigator.pop(context, true);
                },
                child: const Text('Save Shoes', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// ACCESSORIES CUSTOMIZATION
// ==================================================

class AccessoriesScreen extends StatefulWidget {
  const AccessoriesScreen({super.key});

  @override
  State<AccessoriesScreen> createState() => _AccessoriesScreenState();
}

class _AccessoriesScreenState extends State<AccessoriesScreen> {
  String _selectedAccessory = AvatarState.accessory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessories'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Customize Accessories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            const Text('Accessories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...['Watch', 'Glasses', 'Cap', 'Necklace', 'Bracelet'].map((item) {
              final isSelected = _selectedAccessory == item;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedAccessory = item;
                      AvatarState.accessory = item;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item),
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.deepPurple),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: () {
                  _showMessage(context, 'Accessories saved successfully!');
                  Navigator.pop(context, true);
                },
                child: const Text('Save Accessories', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
// PROFILE
// ==================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                user?.displayName ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// SETTINGS
// ==================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Account'),
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
          ),
          const ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy'),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About Avatar'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}

// ==================================================
// COMMON MESSAGE
// ==================================================

void _showMessage(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}
