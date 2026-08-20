import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AvatarApp());
}

// ==================================================
// TOP-LEVEL HELPERS
// ==================================================

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String getChatRoomId(String a, String b) {
  return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
}

// ==================================================
// AVATAR FRIEND AI SERVICE
// ==================================================

Future<String> askAvatarFriend(String userMessage) async {
  final url = Uri.parse('https://avatar-friend-ai.projectkhurafat.workers.dev/');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': userMessage}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? 'Koi response nahi mila.';
    } else {
      return 'Server error: ${response.statusCode}';
    }
  } catch (e) {
    return 'Connection error: Internet check karein.';
  }
}

// ==================================================
// GLOBAL AVATAR STATE
// ==================================================

class AvatarCharacter {
  final String name;
  final Color themeColor;
  final String modelPath;

  const AvatarCharacter({
    required this.name,
    required this.themeColor,
    required this.modelPath,
  });
}

class AvatarState {
  static final List<AvatarCharacter> characters = [
    const AvatarCharacter(
      name: 'ORANGE',
      themeColor: Color(0xFFFF7A00),
      modelPath: 'assets/models/avatar_orange.glb',
    ),
    const AvatarCharacter(
      name: 'BLUE',
      themeColor: Color(0xFF2196F3),
      modelPath: 'assets/models/avatar_blue.glb',
    ),
    const AvatarCharacter(
      name: 'GREEN',
      themeColor: Color(0xFF5DB835),
      modelPath: 'assets/models/avatar_green.glb',
    ),
  ];

  static int selectedIndex = 0;

  static AvatarCharacter get current => characters[selectedIndex];

  static AvatarCharacter getByName(String? name) {
    return characters.firstWhere(
      (c) => c.name.toUpperCase() == (name ?? '').toUpperCase(),
      orElse: () => characters[0],
    );
  }
}

// ==================================================
// APP
// ==================================================

class AvatarApp extends StatelessWidget {
  const AvatarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avatar',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
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
  const AuthGate({Key? key}) : super(key: key);

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
  const WelcomeScreen({Key? key}) : super(key: key);

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
                  backgroundColor: Color(0xFF1E1E1E),
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Avatar',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose your original character and make bonds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAccountScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16),
                    ),
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
  const CreateAccountScreen({Key? key}) : super(key: key);

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

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please enter name, email and password.');
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
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'bio': 'Hey there! I am using Avatar.',
          'avatar': AvatarState.current.name,
          'bonds': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
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
                  labelText: 'Your Username / Name',
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
                      hidePassword ? Icons.visibility : Icons.visibility_off,
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
// LOGIN (AUTO-REDIRECTS ON SUCCESS)
// ==================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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

      if (!mounted) return;
      // Auto close login screen and jump to Home
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email.';
      }
      _showMessage(context, message);
    } catch (e) {
      _showMessage(context, 'Other error: $e');
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
                      hidePassword ? Icons.visibility : Icons.visibility_off,
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
// HOME SCREEN (CLEAN 3-TAB NAVIGATION)
// ==================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomeTab(),
    ChatScreen(),
    ProfileScreen(),
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
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==================================================
// HOME TAB
// ==================================================

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final character = AvatarState.current;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Avatar',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user?.displayName?.isNotEmpty == true ? user!.displayName! : 'User',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF1E1E1E),
                border: Border.all(
                  color: character.themeColor.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ModelViewer(
                  key: ValueKey(character.modelPath),
                  src: character.modelPath,
                  alt: 'My 3D Avatar',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: const Color(0xFF1E1E1E),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: character.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectCharacterScreen(),
                    ),
                  );
                  setState(() {});
                },
                icon: const Icon(
                  Icons.swap_horiz,
                  size: 26,
                ),
                label: Text(
                  'Change Character (${character.name})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
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
// CHAT SCREEN
// ==================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  void openNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewChatScreen(),
      ),
    );
  }

  Future<void> toggleBond(String peerUid, bool isBonded) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUid);

    if (isBonded) {
      await userRef.update({
        'bonds': FieldValue.arrayRemove([peerUid])
      });
      if (mounted) _showMessage(context, 'Bond removed.');
    } else {
      await userRef.update({
        'bonds': FieldValue.arrayUnion([peerUid])
      });
      if (mounted) _showMessage(context, 'Bond created!');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = AvatarState.current;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: openNewChat,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Discover & Search',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, userSnap) {
          final myData = userSnap.data?.data() as Map<String, dynamic>?;
          final List<dynamic> myBonds = myData?['bonds'] ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, allUsersSnap) {
              if (allUsersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = allUsersSnap.data?.docs ?? [];

              final bondedUsers = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final uid = data['uid'] ?? doc.id;
                final name = (data['name'] ?? '').toString().toLowerCase();

                if (uid == currentUid || !myBonds.contains(uid)) return false;
                if (searchQuery.isNotEmpty) {
                  return name.contains(searchQuery.toLowerCase());
                }
                return true;
              }).toList();

              final suggestedUsers = allDocs.where((doc) {
                final uid = doc.id;
                return uid != currentUid && !myBonds.contains(uid);
              }).toList();

              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: searchController,
                      onChanged: (v) => setState(() => searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search bonded chats...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // 1. Avatar Friend AI Tile
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentAvatar.themeColor,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: ModelViewer(
                          key: ValueKey('list_${currentAvatar.modelPath}'),
                          src: currentAvatar.modelPath,
                          alt: 'Avatar Thumbnail',
                          autoRotate: true,
                          cameraControls: false,
                          backgroundColor: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    title: const Text(
                      'Avatar Friend',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: const Text(
                      'Your personalized 3D AI companion',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentAvatar.themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          color: currentAvatar.themeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatConversationScreen(
                            userName: 'Avatar Friend',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // 2. Bonded Users List
                  if (bondedUsers.isNotEmpty) ...[
                    ...bondedUsers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final peerUid = data['uid'] ?? doc.id;
                      final name = data['name'] ?? 'User';
                      final peerAvatar = AvatarState.getByName(data['avatar']);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileViewScreen(userData: data),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: peerAvatar.themeColor.withOpacity(0.25),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: peerAvatar.themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: const Text(
                          'Bonded with you',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        trailing: Icon(
                          Icons.chat_bubble_outline,
                          color: peerAvatar.themeColor,
                          size: 22,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(
                                userName: name,
                                peerUid: peerUid,
                                peerAvatar: data['avatar'],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ] else if (searchQuery.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No bonded contacts match your search.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    ),
                  ],

                  // 3. Suggested Bonds Section
                  if (suggestedUsers.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 24, 18, 10),
                      child: Text(
                        'SUGGESTED BONDS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    ...suggestedUsers.take(10).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final peerUid = data['uid'] ?? doc.id;
                      final name = data['name'] ?? 'User';
                      final peerAvatar = AvatarState.getByName(data['avatar']);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileViewScreen(userData: data),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 23,
                            backgroundColor: peerAvatar.themeColor.withOpacity(0.2),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: peerAvatar.themeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileViewScreen(userData: data),
                              ),
                            );
                          },
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        trailing: SizedBox(
                          height: 34,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: peerAvatar.themeColor.withOpacity(0.2),
                              foregroundColor: peerAvatar.themeColor,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => toggleBond(peerUid, false),
                            child: const Text(
                              '+ Bond',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openNewChat,
        child: const Icon(Icons.search),
      ),
    );
  }
}

// ==================================================
// NEW CHAT / DISCOVER SCREEN
// ==================================================

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  Future<void> toggleBond(String peerUid, bool isBonded) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUid);

    if (isBonded) {
      await userRef.update({
        'bonds': FieldValue.arrayRemove([peerUid])
      });
      if (mounted) _showMessage(context, 'Bond removed.');
    } else {
      await userRef.update({
        'bonds': FieldValue.arrayUnion([peerUid])
      });
      if (mounted) _showMessage(context, 'Bond created! You can now message.');
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover & Bond'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, userSnap) {
          final myData = userSnap.data?.data() as Map<String, dynamic>?;
          final List<dynamic> myBonds = myData?['bonds'] ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by account name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = (snapshot.data?.docs ?? []).where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = data['uid'] ?? doc.id;
                      if (uid == currentUid) return false;

                      final name = (data['name'] ?? '').toString().toLowerCase();
                      if (searchQuery.isEmpty) return true;
                      return name.contains(searchQuery);
                    }).toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'No users found.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userData = users[index].data() as Map<String, dynamic>;
                        final userName = userData['name'] ?? 'User';
                        final peerUid = userData['uid'] ?? users[index].id;
                        final avatarName = userData['avatar'] ?? 'ORANGE';
                        final peerAvatar = AvatarState.getByName(avatarName);
                        final isBonded = myBonds.contains(peerUid);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileViewScreen(userData: userData),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: peerAvatar.themeColor.withOpacity(0.2),
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: peerAvatar.themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          title: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileViewScreen(userData: userData),
                                ),
                              );
                            },
                            child: Text(
                              userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: peerAvatar.themeColor),
                                  foregroundColor: isBonded ? Colors.white70 : peerAvatar.themeColor,
                                  backgroundColor: isBonded
                                      ? Colors.white12
                                      : peerAvatar.themeColor.withOpacity(0.15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => toggleBond(peerUid, isBonded),
                                child: Text(
                                  isBonded ? 'Bonded' : '+ Bond',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isBonded) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatConversationScreen(
                                          userName: userName,
                                          peerUid: peerUid,
                                          peerAvatar: avatarName,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.chat_bubble_outline,
                                    color: peerAvatar.themeColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================================================
// USER PROFILE PREVIEW SCREEN
// ==================================================

class UserProfileViewScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserProfileViewScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final peerUid = userData['uid'] ?? '';
    final name = userData['name'] ?? 'User';
    final bio = userData['bio'] ?? 'Hey there! I am using Avatar.';
    final avatarName = userData['avatar'] ?? 'ORANGE';
    final peerAvatar = AvatarState.getByName(avatarName);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, snapshot) {
          final myData = snapshot.data?.data() as Map<String, dynamic>?;
          final List<dynamic> myBonds = myData?['bonds'] ?? [];
          final isBonded = myBonds.contains(peerUid);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFF1E1E1E),
                      border: Border.all(
                        color: peerAvatar.themeColor.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: ModelViewer(
                        key: ValueKey('preview_${peerAvatar.modelPath}'),
                        src: peerAvatar.modelPath,
                        alt: '$name Avatar',
                        autoRotate: true,
                        cameraControls: true,
                        backgroundColor: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: peerAvatar.themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${peerAvatar.name} Avatar',
                      style: TextStyle(
                        fontSize: 14,
                        color: peerAvatar.themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isBonded
                                  ? const Color(0xFF2A2A2A)
                                  : peerAvatar.themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              final userRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUid);
                              if (isBonded) {
                                await userRef.update({
                                  'bonds': FieldValue.arrayRemove([peerUid])
                                });
                              } else {
                                await userRef.update({
                                  'bonds': FieldValue.arrayUnion([peerUid])
                                });
                              }
                            },
                            child: Text(
                              isBonded ? 'Break Bond' : '+ Make Bond',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isBonded) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: peerAvatar.themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatConversationScreen(
                                    userName: name,
                                    peerUid: peerUid,
                                    peerAvatar: avatarName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================================================
// CHAT CONVERSATION SCREEN (AUTO-SCROLL ON KEYBOARD)
// ==================================================

class ChatConversationScreen extends StatefulWidget {
  final String userName;
  final String? peerUid;
  final String? peerAvatar;

  const ChatConversationScreen({
    Key? key,
    required this.userName,
    this.peerUid,
    this.peerAvatar,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, String>> localMessages = [];
  final FlutterTts flutterTts = FlutterTts();
  
  bool isLoading = false;
  bool isVoiceEnabled = true;

  bool get isAvatarFriend => widget.userName == 'Avatar Friend';
  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get chatRoomId => getChatRoomId(currentUid, widget.peerUid ?? '');

  @override
  void initState() {
    super.initState();
    _initTts();
    if (isAvatarFriend) {
      _loadChatHistory();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (!isVoiceEnabled || !isAvatarFriend) return;
    final cleanText = text.replaceAll('*', '').replaceAll('#', '').replaceAll('`', '');
    await flutterTts.stop();
    await flutterTts.speak(cleanText);
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('avatar_friend_history');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        localMessages.clear();
        for (var item in decoded) {
          localMessages.add(Map<String, String>.from(item));
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_friend_history', jsonEncode(localMessages));
  }

  Future<void> _clearChatHistory() async {
    await flutterTts.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatar_friend_history');
    setState(() {
      localMessages.clear();
    });
    if (mounted) {
      _showMessage(context, 'Chat history cleared.');
    }
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    if (isAvatarFriend) {
      setState(() {
        localMessages.add({'sender': 'user', 'text': text});
        isLoading = true;
      });
      _saveChatHistory();
      _scrollToBottom();

      final reply = await askAvatarFriend(text);

      if (!mounted) return;

      setState(() {
        localMessages.add({'sender': 'bot', 'text': reply});
        isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
      _speak(reply);
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUid,
        'receiverId': widget.peerUid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    flutterTts.stop();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = AvatarState.current;
    final peerAvatarObj = AvatarState.getByName(widget.peerAvatar);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (isAvatarFriend)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentAvatar.themeColor,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: ModelViewer(
                    key: ValueKey('appbar_${currentAvatar.modelPath}'),
                    src: currentAvatar.modelPath,
                    alt: 'Avatar Thumbnail',
                    autoRotate: true,
                    cameraControls: false,
                    backgroundColor: const Color(0xFF1E1E1E),
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 19,
                backgroundColor: peerAvatarObj.themeColor.withOpacity(0.3),
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: peerAvatarObj.themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text(widget.userName),
          ],
        ),
        actions: [
          if (isAvatarFriend) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  isVoiceEnabled = !isVoiceEnabled;
                });
                if (!isVoiceEnabled) {
                  flutterTts.stop();
                }
                _showMessage(
                  context,
                  isVoiceEnabled ? 'Avatar Voice Enabled 🔊' : 'Avatar Voice Muted 🔇',
                );
              },
              icon: Icon(
                isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                color: isVoiceEnabled ? currentAvatar.themeColor : Colors.white54,
              ),
              tooltip: 'Toggle Voice',
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Chat?'),
                    content: const Text('Are you sure you want to delete all messages?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearChatHistory();
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Chat',
            ),
          ],
          IconButton(
            onPressed: () {
              _showMessage(context, 'Voice call will be connected next.');
            },
            icon: const Icon(Icons.call),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isAvatarFriend ? _buildAiChat(currentAvatar) : _buildRealUserChat(),
          ),

          // MESSAGE BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _showMessage(context, 'Media sharing will be connected next.');
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction: TextInputAction.send,
                      onTap: () {
                        // Auto scroll up when keyboard opens
                        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
                      },
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isAvatarFriend
                        ? currentAvatar.themeColor
                        : Colors.deepPurple,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(Icons.send, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AI Chat Layout
  Widget _buildAiChat(AvatarCharacter currentAvatar) {
    if (localMessages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(
                    color: currentAvatar.themeColor,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: ModelViewer(
                    key: ValueKey('chat_${currentAvatar.modelPath}'),
                    src: currentAvatar.modelPath,
                    alt: 'Avatar 3D Preview',
                    autoRotate: true,
                    cameraControls: false,
                    backgroundColor: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Say hello to ${currentAvatar.name} Avatar!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: currentAvatar.themeColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your personalized 3D AI companion with voice',
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: localMessages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == localMessages.length && isLoading) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final msg = localMessages[index];
        final isUser = msg['sender'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isUser ? Colors.deepPurple : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(18),
              border: (!isUser)
                  ? Border.all(
                      color: currentAvatar.themeColor.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    msg['text'] ?? '',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _speak(msg['text'] ?? ''),
                    child: Icon(
                      Icons.volume_up,
                      size: 16,
                      color: currentAvatar.themeColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 1-on-1 Firestore Live Chat Layout
  Widget _buildRealUserChat() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 70,
                  color: Colors.white24,
                ),
                const SizedBox(height: 15),
                Text(
                  'Say hello to ${widget.userName}!',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;
        _scrollToBottom();

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == currentUid;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isMe ? Colors.deepPurple : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  data['text'] ?? '',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================================================
// CHARACTER SELECTOR
// ==================================================

class SelectCharacterScreen extends StatefulWidget {
  const SelectCharacterScreen({Key? key}) : super(key: key);

  @override
  State<SelectCharacterScreen> createState() => _SelectCharacterScreenState();
}

class _SelectCharacterScreenState extends State<SelectCharacterScreen> {
  int tempIndex = AvatarState.selectedIndex;

  @override
  Widget build(BuildContext context) {
    final activeChar = AvatarState.characters[tempIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Character'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF1E1E1E),
                border: Border.all(
                  color: activeChar.themeColor.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ModelViewer(
                  key: ValueKey(activeChar.modelPath),
                  src: activeChar.modelPath,
                  alt: 'Character Preview',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF181818),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'COLOR OPTIONS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    AvatarState.characters.length,
                    (index) {
                      final char = AvatarState.characters[index];
                      final isSelected = tempIndex == index;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                tempIndex = index;
                              });
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? char.themeColor
                                    : char.themeColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? Colors.white : char.themeColor,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  char.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : char.themeColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 55,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: activeChar.themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      AvatarState.selectedIndex = tempIndex;

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'avatar': AvatarState.current.name});
                      }

                      if (!mounted) return;

                      _showMessage(
                        context,
                        '${AvatarState.current.name} Avatar equipped!',
                      );

                      Navigator.pop(context);
                    },
                    child: Text(
                      'Equip ${activeChar.name}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// PROFILE SCREEN (INSTANT REAL-TIME SYNC & AUTO-CLOSE)
// ==================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openEditProfileSheet(String currentName, String currentBio) {
    final nameCtrl = TextEditingController(text: currentName);
    final bioCtrl = TextEditingController(text: currentBio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bioCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Bio / Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final newBio = bioCtrl.text.trim();
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null && newName.isNotEmpty) {
                    Navigator.pop(ctx); // Close sheet instantly

                    await user.updateDisplayName(newName);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'name': newName,
                      'bio': newBio,
                    });

                    if (mounted) {
                      _showMessage(context, 'Profile updated successfully!');
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentAvatar = AvatarState.current;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? user?.displayName ?? 'User';
          final bio = data?['bio'] ?? 'Hey there! I am using Avatar.';
          final List<dynamic> bonds = data?['bonds'] ?? [];

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 3D Avatar Display
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1E1E),
                      border: Border.all(
                        color: currentAvatar.themeColor,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: ModelViewer(
                        key: ValueKey('profile_${currentAvatar.modelPath}'),
                        src: currentAvatar.modelPath,
                        alt: 'Avatar Profile',
                        autoRotate: true,
                        cameraControls: false,
                        backgroundColor: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${bonds.length}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: currentAvatar.themeColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Bonds',
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              currentAvatar.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: currentAvatar.themeColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Equipped',
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: currentAvatar.themeColor),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openEditProfileSheet(name, bio),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================================================
// SETTINGS SCREEN
// ==================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}
