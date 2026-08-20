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
// TOP-LEVEL MESSAGE HELPER
// ==================================================

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
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
                  'Choose your original character and enter your world.',
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
                          builder: (_) =>
                              const CreateAccountScreen(),
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

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        context,
        'Please enter email and password.',
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        context,
        'Password must be at least 6 characters.',
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

      if (name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
      }

      if (!mounted) return;

      _showMessage(
        context,
        'Account created successfully!',
      );

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
      _showMessage(
        context,
        'Something went wrong.',
      );
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
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
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
                  onPressed:
                      loading ? null : createAccount,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(),
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
  const LoginScreen({Key? key}) : super(key: key);

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
    final password =
        passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        context,
        'Please enter email and password.',
      );
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
  _showMessage(
    context,
    'Firebase error: ${e.code}\n${e.message ?? "No message"}',
  );
} catch (e) {
  _showMessage(
    context,
    'Other error: $e',
  );
    } catch (_) {
      _showMessage(
        context,
        'Something went wrong.',
      );
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
                  prefixIcon:
                      Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border:
                      const OutlineInputBorder(),
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
                      loading ? null : login,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// HOME SCREEN
// HOME → CHAT → PROFILE → SETTINGS
// ==================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomeTab(),
    ChatScreen(),
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
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon:
                Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.account_circle_outlined,
            ),
            selectedIcon:
                Icon(Icons.account_circle),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
            ),
            selectedIcon:
                Icon(Icons.settings),
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

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() =>
      _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    final character =
        AvatarState.current;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
              user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : user?.email ?? 'User',
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
                borderRadius:
                    BorderRadius.circular(28),
                color:
                    const Color(0xFF1E1E1E),
                border: Border.all(
                  color: character.themeColor
                      .withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(28),
                child: ModelViewer(
                  key: ValueKey(
                    character.modelPath,
                  ),
                  src: character.modelPath,
                  alt: 'My 3D Avatar',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor:
                      const Color(0xFF1E1E1E),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      character.themeColor,
                  foregroundColor: Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SelectCharacterScreen(),
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
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  final TextEditingController
      searchController =
      TextEditingController();

  final List<Map<String, dynamic>>
      conversations = [
    {
      'name': 'Avatar Friend',
      'message': 'Start a new conversation',
      'time': '',
      'icon': Icons.person,
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: openNewChat,
            icon: const Icon(Icons.edit),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              12,
            ),
            child: TextField(
              controller: searchController,
              decoration:
                  InputDecoration(
                hintText:
                    'Search people or chats',
                prefixIcon:
                    const Icon(Icons.search),
                filled: true,
                fillColor:
                    const Color(0xFF1E1E1E),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: conversations.isEmpty
                ? _emptyChat()
                : ListView.builder(
                    itemCount:
                        conversations.length,
                    itemBuilder:
                        (context, index) {
                      final chat =
                          conversations[index];

                      return ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        leading:
                            CircleAvatar(
                          radius: 27,
                          child: Icon(
                            chat['icon']
                                as IconData,
                          ),
                        ),
                        title: Text(
                          chat['name']
                              as String,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          chat['message']
                              as String,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          chat['time'] as String,
                          style:
                              const TextStyle(
                            color:
                                Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatConversationScreen(
                                userName:
                                    chat['name']
                                        as String,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: openNewChat,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 90,
              color: Colors.white38,
            ),
            const SizedBox(height: 20),
            const Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation with another Avatar user.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: openNewChat,
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// NEW CHAT
// ==================================================

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController
        searchController =
        TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration:
                  InputDecoration(
                hintText:
                    'Search by name or email',
                prefixIcon:
                    const Icon(Icons.search),
                filled: true,
                fillColor:
                    const Color(0xFF1E1E1E),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.white38,
            ),
            const SizedBox(height: 15),
            const Text(
              'Find an Avatar user',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'User search and online chat will be connected to Firebase next.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// CHAT CONVERSATION
// ==================================================

class ChatConversationScreen
    extends StatefulWidget {
  final String userName;

  const ChatConversationScreen({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  State<ChatConversationScreen>
      createState() =>
          _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends State<ChatConversationScreen> {
  final TextEditingController
      messageController =
      TextEditingController();

  final List<String> messages = [];

  void sendMessage() {
    final message =
        messageController.text.trim();

    if (message.isEmpty) return;

    setState(() {
      messages.add(message);
    });

    messageController.clear();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 19,
              child:
                  Icon(Icons.person, size: 21),
            ),
            const SizedBox(width: 10),
            Text(widget.userName),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showMessage(
                context,
                'Voice call will be connected next.',
              );
            },
            icon: const Icon(Icons.call),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons
                              .chat_bubble_outline,
                          size: 70,
                          color:
                              Colors.white24,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Start chatting',
                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        messages.length,
                    itemBuilder:
                        (context, index) {
                      return Align(
                        alignment:
                            Alignment.centerRight,
                        child: Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.deepPurple,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                          child: Text(
                            messages[index],
                            style:
                                const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // MESSAGE BAR
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                6,
                10,
                10,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _showMessage(
                        context,
                        'Media sharing will be connected next.',
                      );
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller:
                          messageController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) =>
                          sendMessage(),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Message...',
                        filled: true,
                        fillColor:
                            const Color(
                          0xFF1E1E1E,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Colors.deepPurple,
                    child: IconButton(
                      onPressed:
                          sendMessage,
                      icon: const Icon(
                        Icons.send,
                        size: 20,
                      ),
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
}

// ==================================================
// CHARACTER SELECTOR
// ==================================================

class SelectCharacterScreen
    extends StatefulWidget {
  const SelectCharacterScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<SelectCharacterScreen>
      createState() =>
          _SelectCharacterScreenState();
}

class _SelectCharacterScreenState
    extends State<SelectCharacterScreen> {
  int tempIndex =
      AvatarState.selectedIndex;

  @override
  Widget build(BuildContext context) {
    final activeChar =
        AvatarState.characters[tempIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Character',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin:
                  const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(28),
                color:
                    const Color(0xFF1E1E1E),
                border: Border.all(
                  color: activeChar.themeColor
                      .withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(28),
                child: ModelViewer(
                  key: ValueKey(
                    activeChar.modelPath,
                  ),
                  src: activeChar.modelPath,
                  alt: 'Character Preview',
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor:
                      const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            decoration:
                const BoxDecoration(
              color: Color(0xFF181818),
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'COLOR OPTIONS',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    AvatarState.characters
                        .length,
                    (index) {
                      final char =
                          AvatarState.characters[
                              index];

                      final isSelected =
                          tempIndex == index;

                      return Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 4,
                          ),
                          child:
                              GestureDetector(
                            onTap: () {
                              setState(() {
                                tempIndex =
                                    index;
                              });
                            },
                            child: Container(
                              height: 52,
                              decoration:
                                  BoxDecoration(
                                color: isSelected
                                    ? char
                                        .themeColor
                                    : char
                                        .themeColor
                                        .withOpacity(
                                        0.18,
                                      ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                                border:
                                    Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : char
                                          .themeColor,
                                  width:
                                      isSelected
                                          ? 2.5
                                          : 1,
                                ),
                              ),
                              child:
                                  Center(
                                child: Text(
                                  char.name,
                                  style:
                                      TextStyle(
                                    fontSize:
                                        15,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: isSelected
                                        ? Colors
                                            .white
                                        : char
                                            .themeColor,
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
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          activeChar.themeColor,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                    onPressed: () {
                      AvatarState
                              .selectedIndex =
                          tempIndex;

                      _showMessage(
                        context,
                        '${AvatarState.current.name} Avatar equipped!',
                      );

                      Navigator.pop(context);
                    },
                    child: Text(
                      'Equip ${activeChar.name}',
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
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
// PROFILE
// ==================================================

class ProfileScreen
    extends StatelessWidget {
  const ProfileScreen({Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage:
                    user?.photoURL != null
                        ? NetworkImage(
                            user!.photoURL!,
                          )
                        : null,
                child:
                    user?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                          )
                        : null,
              ),
              const SizedBox(height: 20),
              Text(
                user?.displayName ?? 'User',
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                textAlign:
                    TextAlign.center,
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

class SettingsScreen
    extends StatelessWidget {
  const SettingsScreen({Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading:
                Icon(Icons.person),
            title: Text('Account'),
          ),
          const ListTile(
            leading: Icon(
              Icons.notifications,
            ),
            title:
                Text('Notifications'),
          ),
          const ListTile(
            leading:
                Icon(Icons.lock),
            title:
                Text('Privacy'),
          ),
          const ListTile(
            leading:
                Icon(Icons.info),
            title:
                Text('About Avatar'),
          ),
          ListTile(
            leading:
                const Icon(Icons.logout),
            title:
                const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance
                  .signOut();
            },
          ),
        ],
      ),
    );
  }
}
