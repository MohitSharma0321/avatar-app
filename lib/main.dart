import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ==================================================
// PALETTE & CONSTANTS
// ==================================================
const Color kVoidBlack = Color(0xFF0A0714);
const Color kCardDark = Color(0xFF130E24);
const Color kNeonCyan = Color(0xFF00E5FF);
const Color kNeonPurple = Color(0xFFBD00FF);
const Color kAncientGold = Color(0xFFFFB300);
const Color kHorrorCrimson = Color(0xFFFF1744);
const Color kMistyGreen = Color(0xFF00E676);

const String kAdminEmail = "shrmamohit926@gmail.com";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Init: $e");
  }

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const AvatarApp());
}

// ==================================================
// GLOBAL LANGUAGE TRANSLATION ENGINE
// ==================================================
class AppLanguage {
  static final ValueNotifier<String> currentLang = ValueNotifier<String>('English');

  static const List<Map<String, String>> supportedLanguages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Hindi', 'native': 'हिन्दी', 'code': 'hi'},
    {'name': 'Spanish', 'native': 'Español', 'code': 'es'},
    {'name': 'French', 'native': 'Français', 'code': 'fr'},
    {'name': 'German', 'native': 'Deutsch', 'code': 'de'},
    {'name': 'Japanese', 'native': '日本語', 'code': 'ja'},
    {'name': 'Korean', 'native': '한국어', 'code': 'ko'},
    {'name': 'Russian', 'native': 'Русский', 'code': 'ru'},
    {'name': 'Arabic', 'native': 'العربية', 'code': 'ar'},
    {'name': 'Portuguese', 'native': 'Português', 'code': 'pt'},
    {'name': 'Bengali', 'native': 'বাংলা', 'code': 'bn'},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'code': 'pa'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'code': 'ta'},
    {'name': 'Telugu', 'native': 'తెలుగు', 'code': 'te'},
    {'name': 'Marathi', 'native': 'मराठी', 'code': 'mr'},
  ];

  static const Map<String, Map<String, String>> dictionary = {
    'English': {
      'home': 'Home', 'radar': 'Radar', 'post': 'Post', 'hub': 'Hub', 'chats': 'Chats', 'profile': 'Profile',
      'search_lang': 'Search language...', 'select_lang': 'Select Global Language',
      'online': 'Online', 'typing': 'typing...', 'seen': 'Seen',
      'share_link': 'Share with App Link', 'share_text': 'Share Text Only',
      'delete_me': 'Delete for Me', 'delete_everyone': 'Delete for Everyone', 'unsend': 'Unsend Message',
      'pin_chat': 'Pin Conversation', 'profile_locked': 'Profile unlocks after 3 days of connection',
    },
    'Hindi': {
      'home': 'होम', 'radar': 'रडार', 'post': 'पोस्ट', 'hub': 'हब', 'chats': 'चैट्स', 'profile': 'प्रोफाइल',
      'search_lang': 'भाषा खोजें...', 'select_lang': 'भाषा चुनें',
      'online': 'ऑनलाइन', 'typing': 'टाइप कर रहे हैं...', 'seen': 'देखा गया',
      'share_link': 'ऐप लिंक के साथ शेयर करें', 'share_text': 'सिर्फ टेक्स्ट शेयर करें',
      'delete_me': 'मेरे लिए हटाएं', 'delete_everyone': 'सबके लिए हटाएं', 'unsend': 'मैसेज अनसेंड करें',
      'pin_chat': 'चैट पिन करें', 'profile_locked': '3 दिन की बातचीत के बाद प्रोफाइल अनलॉक होगी',
    },
  };

  static String tr(String key) {
    final lang = currentLang.value;
    if (dictionary.containsKey(lang) && dictionary[lang]!.containsKey(key)) {
      return dictionary[lang]![key]!;
    }
    return dictionary['English']?[key] ?? key;
  }
}

class AvatarApp extends StatelessWidget {
  const AvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.currentLang,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Avatar',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: kVoidBlack,
            colorScheme: const ColorScheme.dark(
              primary: kNeonPurple,
              secondary: kNeonCyan,
              surface: kCardDark,
            ),
          ),
          home: const AuthGatekeeper(),
        );
      },
    );
  }
}

// ==================================================
// NOTIFICATION HELPER SERVICE
// ==================================================
class NotificationService {
  static Future<void> requestPermissionAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    await Permission.notification.request();
  }

  static Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'avatar_channel', 'Avatar Alerts',
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, title, body, platformChannelSpecifics,
    );
  }
}

// ==================================================
// CLOUDFLARE GEMINI AI ENGINE
// ==================================================
class AvatarAIEngine {
  static const String _workerUrl = 'https://avatar-friend-ai.projectkhurafat.workers.dev/';

  static Future<String> getAIResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['reply'] != null && data['reply'].toString().trim().isNotEmpty) {
          return data['reply'];
        }
      }
    } catch (e) {
      debugPrint('Cloudflare Avatar AI Error: $e');
    }

    final lower = userMessage.toLowerCase();
    if (lower.contains('hi') || lower.contains('hello')) {
      return "Pranaam Explorer! Avatar dimension mein aapka swagat hai. Aaj koun sa mystery decode karein?";
    }
    return "The cosmos resonates across frequencies. Transmitting...";
  }
}

// ==================================================
// DYNAMIC RANK REWARDS & ECONOMY ENGINE
// ==================================================
class RankThemeEngine {
  static Map<String, dynamic> getThemeByPoints(int points) {
    if (points >= 1200) {
      return {'rank': 'Multiverse Prime', 'primary': kAncientGold, 'glowColor': kAncientGold.withOpacity(0.35), 'next': 'MAX LEVEL', 'progress': 1.0};
    } else if (points >= 500) {
      return {'rank': 'Subconscious Oracle', 'primary': kNeonCyan, 'glowColor': kNeonCyan.withOpacity(0.35), 'next': 'Multiverse Prime (1200 Pts)', 'progress': (points - 500) / 700};
    } else if (points >= 200) {
      return {'rank': 'Astral Decipherer', 'primary': kNeonPurple, 'glowColor': kNeonPurple.withOpacity(0.35), 'next': 'Subconscious Oracle (500 Pts)', 'progress': (points - 200) / 300};
    } else if (points >= 50) {
      return {'rank': 'Dimensional Walker', 'primary': kMistyGreen, 'glowColor': kMistyGreen.withOpacity(0.35), 'next': 'Astral Decipherer (200 Pts)', 'progress': (points - 50) / 150};
    } else {
      return {'rank': 'Seeker of the Void', 'primary': Colors.white70, 'glowColor': Colors.white10, 'next': 'Dimensional Walker (50 Pts)', 'progress': points / 50};
    }
  }

  static Future<void> checkAndGrantRankRewards(BuildContext? context, String uid, int oldPoints, int newPoints) async {
    final oldRank = getThemeByPoints(oldPoints)['rank'] as String;
    final newRankTheme = getThemeByPoints(newPoints);
    final newRank = newRankTheme['rank'] as String;

    if (oldRank != newRank && newPoints > oldPoints) {
      await NotificationService.showLocalNotification('🏆 Rank Ascended!', 'You reached $newRank');
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
        'title': 'Rank Ascended: $newRank',
        'desc': 'Congratulations! You unlocked the $newRank Aura & Perks.',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'rank': newRank});
    }
  }
}

// ==================================================
// NEON WAVEFORM VISUALIZER WIDGET
// ==================================================
class NeonWaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  const NeonWaveformVisualizer({super.key, required this.isPlaying, required this.color});

  @override
  State<NeonWaveformVisualizer> createState() => _NeonWaveformVisualizerState();
}

class _NeonWaveformVisualizerState extends State<NeonWaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          10,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3, height: 6.0 + (i % 4) * 3,
            decoration: BoxDecoration(color: widget.color.withOpacity(0.35), borderRadius: BorderRadius.circular(2)),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(10, (i) {
            final double height = 6.0 + 16.0 * sin((_animController.value * 2 * pi) + (i * 0.5)).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3, height: height,
              decoration: BoxDecoration(
                color: widget.color, borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: widget.color.withOpacity(0.8), blurRadius: 6, spreadRadius: 1)],
              ),
            );
          }),
        );
      },
    );
  }
}

// ==================================================
// AUTHENTICATION GATEWAY
// ==================================================
class AuthGatekeeper extends StatefulWidget {
  const AuthGatekeeper({super.key});

  @override
  State<AuthGatekeeper> createState() => _AuthGatekeeperState();
}

class _AuthGatekeeperState extends State<AuthGatekeeper> {
  @override
  void initState() {
    super.initState();
    NotificationService.requestPermissionAfterDelay();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: kNeonPurple)));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const AvatarNavigationHost();
        }
        return const AvatarLoginScreen();
      },
    );
  }
}

class AvatarLoginScreen extends StatefulWidget {
  const AvatarLoginScreen({super.key});
  @override
  State<AvatarLoginScreen> createState() => _AvatarLoginScreenState();
}

class _AvatarLoginScreenState extends State<AvatarLoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  bool isSignUp = false;
  bool isLoading = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || pass.isEmpty || (isSignUp && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        await cred.user?.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': email,
          'name': name,
          'username': name.toLowerCase().replaceAll(' ', '_'),
          'bio': 'Exploring the Multiverse in Avatar',
          'profilePic': '',
          'rank': 'Seeker of the Void',
          'resonances': 0,
          'unlockedPerks': ['Void Core'],
          'isOnline': true,
          'typingTo': '',
          'pinnedChats': [],
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.2, colors: [Color(0xFF280B4D), kVoidBlack])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kNeonCyan, width: 2), boxShadow: [BoxShadow(color: kNeonPurple.withOpacity(0.5), blurRadius: 20)]),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 18),
                  const Text('AVATAR', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.white)),
                  const SizedBox(height: 32),
                  if (isSignUp)
                    TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Your Display Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  if (isSignUp) const SizedBox(height: 14),
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 14),
                  TextField(controller: _passController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: isLoading ? null : _handleAuth,
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isSignUp ? 'CREATE ACCOUNT' : 'ENTER', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() => isSignUp = !isSignUp),
                    child: Text(isSignUp ? 'Already have an account? Log In' : 'New User? Register here', style: const TextStyle(color: kNeonCyan)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================
// NAVIGATION HOST (MINIMALISTIC 6 TABS)
// ==================================================
class AvatarNavigationHost extends StatefulWidget {
  const AvatarNavigationHost({super.key});

  @override
  State<AvatarNavigationHost> createState() => _AvatarNavigationHostState();
}

class _AvatarNavigationHostState extends State<AvatarNavigationHost> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _selectedRealm = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserOnline(false);
    super.dispose();
  }

  void _setUserOnline(bool online) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final userPoints = (userData['resonances'] ?? 0) as int;
        final rankTheme = RankThemeEngine.getThemeByPoints(userPoints);
        final Color activeColor = rankTheme['primary'] as Color;

        final screens = [
          RealmsFeedScreen(selectedRealm: _selectedRealm, accentColor: activeColor, onRealmChange: (r) => setState(() => _selectedRealm = r)),
          TimeSlipRadarScreen(accentColor: activeColor),
          TransmissionStudioScreen(accentColor: activeColor, onPostSuccess: () => setState(() => _currentIndex = 0)),
          OracleSanctumScreen(accentColor: activeColor),
          ChatsInboxScreen(accentColor: activeColor),
          ExplorerProfileScreen(accentColor: activeColor, onVaultSelect: (realm) => setState(() { _selectedRealm = realm; _currentIndex = 0; })),
        ];

        return Scaffold(
          backgroundColor: kVoidBlack,
          body: screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: kCardDark,
              border: Border(top: BorderSide(color: activeColor.withOpacity(0.2))),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) => setState(() => _currentIndex = idx),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: activeColor,
              unselectedItemColor: Colors.white38,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: AppLanguage.tr('home')),
                BottomNavigationBarItem(icon: const Icon(Icons.radar_rounded), label: AppLanguage.tr('radar')),
                BottomNavigationBarItem(icon: const Icon(Icons.add_circle_outline_rounded, size: 26), label: AppLanguage.tr('post')),
                BottomNavigationBarItem(icon: const Icon(Icons.auto_awesome_rounded), label: AppLanguage.tr('hub')),
                BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline_rounded), label: AppLanguage.tr('chats')),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), label: AppLanguage.tr('profile')),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================================================
// TAB 1: HOME FEED (WITH GLOBAL LANGUAGE SEARCH)
// ==================================================
class RealmsFeedScreen extends StatelessWidget {
  final String selectedRealm;
  final Color accentColor;
  final Function(String) onRealmChange;

  const RealmsFeedScreen({super.key, required this.selectedRealm, required this.accentColor, required this.onRealmChange});

  final List<Map<String, dynamic>> realms = const [
    {'name': 'All', 'icon': Icons.all_inclusive_rounded, 'color': kNeonPurple},
    {'name': 'Horror', 'icon': Icons.dark_mode_rounded, 'color': kHorrorCrimson},
    {'name': 'Ancient Gods', 'icon': Icons.temple_hindu_rounded, 'color': kAncientGold},
    {'name': 'Cyber 3050', 'icon': Icons.memory_rounded, 'color': kNeonCyan},
    {'name': 'Dreams', 'icon': Icons.cloudy_snowing, 'color': kMistyGreen},
  ];

  void _openLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredList = AppLanguage.supportedLanguages.where((l) {
              return l['name']!.toLowerCase().contains(filter.toLowerCase()) || l['native']!.toLowerCase().contains(filter.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 18, right: 18, top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    Text(AppLanguage.tr('select_lang'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setSheetState(() => filter = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: kVoidBlack,
                        prefixIcon: const Icon(Icons.search, color: kNeonCyan),
                        hintText: AppLanguage.tr('search_lang'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, i) {
                          final item = filteredList[i];
                          final isSelected = AppLanguage.currentLang.value == item['name'];
                          return ListTile(
                            title: Text(item['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? kNeonCyan : Colors.white)),
                            subtitle: Text(item['native']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: isSelected ? const Icon(Icons.check, color: kNeonCyan) : null,
                            onTap: () {
                              AppLanguage.currentLang.value = item['name']!;
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('AVATAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded, color: kNeonCyan),
            tooltip: 'Language Selector',
            onPressed: () => _openLanguagePicker(context),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: realms.length,
              itemBuilder: (ctx, i) {
                final r = realms[i];
                final isSel = selectedRealm == r['name'];
                return GestureDetector(
                  onTap: () => onRealmChange(r['name'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSel ? (r['color'] as Color).withOpacity(0.2) : kCardDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSel ? (r['color'] as Color) : Colors.white12, width: isSel ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(r['icon'] as IconData, color: r['color'] as Color, size: 22),
                        const SizedBox(height: 4),
                        Text(r['name'] as String, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedRealm == 'All'
                  ? FirebaseFirestore.instance.collection('transmissions').orderBy('createdAt', descending: true).snapshots()
                  : FirebaseFirestore.instance.collection('transmissions').where('dimension', isEqualTo: selectedRealm).snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: accentColor));
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No transmissions yet.', style: TextStyle(color: Colors.white38)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return TransmissionCard(docId: docs[i].id, data: data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// TRANSMISSION CARD (DUAL SHARE MODE & WITNESS)
// ==================================================
class TransmissionCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const TransmissionCard({super.key, required this.docId, required this.data});

  @override
  State<TransmissionCard> createState() => _TransmissionCardState();
}

class _TransmissionCardState extends State<TransmissionCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _getDimensionColor(String dim) {
    switch (dim) {
      case 'Horror': return kHorrorCrimson;
      case 'Ancient Gods': return kAncientGold;
      case 'Cyber 3050': return kNeonCyan;
      case 'Dreams': return kMistyGreen;
      default: return kNeonPurple;
    }
  }

  Future<void> _playAudio(String base64Audio) async {
    if (isPlaying) {
      await _audioPlayer.stop();
      setState(() => isPlaying = false);
      return;
    }
    try {
      final bytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_${widget.docId}.m4a');
      await tempFile.writeAsBytes(bytes);
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      setState(() => isPlaying = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => isPlaying = false);
      });
    } catch (e) {
      debugPrint('Audio Error: $e');
    }
  }

  void _openShareOptions(BuildContext context, String content, String dim, String creator) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link_rounded, color: kNeonCyan),
              title: Text(AppLanguage.tr('share_link'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Includes story text + avatar app direct invite link', style: TextStyle(fontSize: 11, color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('🌌 AVATAR TRANSMISSION [$dim Realm]\n\n"$content"\n\n- By @$creator on Avatar App.\nDownload: https://avatar-network.app/invite', subject: 'Avatar Transmission');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded, color: kAncientGold),
              title: Text(AppLanguage.tr('share_text'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Shares clean quote/lore without any external links', style: TextStyle(fontSize: 11, color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('"$content"\n\n- @$creator [$dim Realm]', subject: 'Lore Quote');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.data['dimension'] ?? 'Nexus';
    final dimColor = _getDimensionColor(dim);
    final witnesses = List<String>.from(widget.data['witnesses'] ?? []);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasWitnessed = witnesses.contains(currentUid);
    final content = widget.data['content'] ?? '';
    final creatorName = widget.data['creatorName'] ?? 'Explorer';
    final audioBase64 = widget.data['audioBase64'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: dimColor.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(creatorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: dimColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(dim, style: TextStyle(color: dimColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (content.isNotEmpty) Text(content, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4)),
          if (widget.data['hasAudio'] == true && audioBase64.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _playAudio(audioBase64),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, color: dimColor, size: 24),
                    const SizedBox(width: 8),
                    const Text('Audio Transmission', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const Spacer(),
                    NeonWaveformVisualizer(isPlaying: isPlaying, color: dimColor),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () async {
                  if (currentUid.isEmpty) return;
                  final docRef = FirebaseFirestore.instance.collection('transmissions').doc(widget.docId);
                  if (hasWitnessed) {
                    await docRef.update({'witnesses': FieldValue.arrayRemove([currentUid])});
                  } else {
                    await docRef.update({'witnesses': FieldValue.arrayUnion([currentUid])});
                  }
                },
                child: Row(
                  children: [
                    Icon(hasWitnessed ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: hasWitnessed ? dimColor : Colors.white38, size: 18),
                    const SizedBox(width: 6),
                    Text('${witnesses.length}', style: TextStyle(color: hasWitnessed ? dimColor : Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white38, size: 18),
                onPressed: () => _openShareOptions(context, content, dim, creatorName),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================================================
// TAB 2: ANY-RANK TIME-SLIP RADAR
// ==================================================
class TimeSlipRadarScreen extends StatefulWidget {
  final Color accentColor;
  const TimeSlipRadarScreen({super.key, required this.accentColor});

  @override
  State<TimeSlipRadarScreen> createState() => _TimeSlipRadarScreenState();
}

class _TimeSlipRadarScreenState extends State<TimeSlipRadarScreen> {
  int radarIndex = 0;

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(backgroundColor: kVoidBlack, elevation: 0, title: const Text('RADAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: widget.accentColor));
          final allUsers = snap.data!.docs.where((d) => d.id != myUid).toList();

          if (allUsers.isEmpty) {
            return const Center(child: Text('No explorers on radar currently.', style: TextStyle(color: Colors.white38)));
          }

          final targetUser = allUsers[radarIndex % allUsers.length];
          final targetData = targetUser.data() as Map<String, dynamic>;
          final targetName = targetData['name'] ?? 'Explorer';
          final targetRank = targetData['rank'] ?? 'Seeker';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.accentColor.withOpacity(0.3), width: 2)),
                    child: Center(
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kNeonPurple.withOpacity(0.4), width: 2)),
                        child: Center(
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: widget.accentColor.withOpacity(0.2),
                            child: Text(targetName[0].toUpperCase(), style: TextStyle(fontSize: 28, color: widget.accentColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(targetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  Text(targetRank, style: TextStyle(color: widget.accentColor, fontSize: 12)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kCardDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () => setState(() => radarIndex++),
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        label: const Text('Next Person', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AvatarDirectChatScreen(peerUid: targetUser.id, peerName: targetName)));
                        },
                        icon: const Icon(Icons.chat, color: Colors.black),
                        label: const Text('Message', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
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
// TAB 3: TRANSMISSION STUDIO (POST)
// ==================================================
class TransmissionStudioScreen extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onPostSuccess;
  const TransmissionStudioScreen({super.key, required this.accentColor, required this.onPostSuccess});

  @override
  State<TransmissionStudioScreen> createState() => _TransmissionStudioScreenState();
}

class _TransmissionStudioScreenState extends State<TransmissionStudioScreen> {
  final _contentController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String selectedDim = 'Horror';
  bool isRecording = false;
  String? recordedAudioBase64;
  bool isTransmitting = false;

  final List<String> dimensions = ['Horror', 'Ancient Gods', 'Cyber 3050', 'Dreams'];

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => isRecording = false);
      if (path != null) {
        final bytes = await File(path).readAsBytes();
        setState(() => recordedAudioBase64 = base64Encode(bytes));
      }
    } else {
      final permission = await Permission.microphone.request();
      if (permission.isGranted) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
        setState(() { isRecording = true; recordedAudioBase64 = null; });
      }
    }
  }

  Future<void> _transmit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty && recordedAudioBase64 == null) return;

    setState(() => isTransmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('transmissions').add({
        'uid': user?.uid ?? 'anon',
        'creatorName': user?.displayName ?? 'Explorer',
        'dimension': selectedDim,
        'content': text,
        'hasAudio': recordedAudioBase64 != null,
        'audioBase64': recordedAudioBase64 ?? '',
        'witnesses': [],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      _contentController.clear();
      setState(() => recordedAudioBase64 = null);
      widget.onPostSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isTransmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(backgroundColor: kVoidBlack, elevation: 0, title: const Text('POST TRANSMISSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: dimensions.map((d) {
                final isSel = selectedDim == d;
                return ChoiceChip(
                  label: Text(d, style: TextStyle(color: isSel ? Colors.black : Colors.white)),
                  selected: isSel, selectedColor: widget.accentColor, backgroundColor: kCardDark,
                  onSelected: (val) => setState(() => selectedDim = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(controller: _contentController, maxLines: 5, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Share your thoughts, horror lore, or theory...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(recordedAudioBase64 != null ? 'Audio captured!' : 'Record Voice Note', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  IconButton(onPressed: _toggleRecording, icon: Icon(isRecording ? Icons.stop_circle_rounded : Icons.mic, color: isRecording ? kHorrorCrimson : widget.accentColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: isTransmitting ? null : _transmit,
                child: isTransmitting ? const CircularProgressIndicator(color: Colors.black) : const Text('PUBLISH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// TAB 4: THE ORACLE'S SANCTUM (HUB)
// ==================================================
class OracleSanctumScreen extends StatelessWidget {
  final Color accentColor;
  const OracleSanctumScreen({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(backgroundColor: kVoidBlack, elevation: 0, title: const Text('DEVELOPER HUB', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('developer_broadcasts').orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: accentColor));
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No official updates yet.', style: TextStyle(color: Colors.white38)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final item = docs[i].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: kAncientGold.withOpacity(0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kAncientGold)),
                    const SizedBox(height: 6),
                    Text(item['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================================================
// TAB 5: CHATS INBOX (WITH AI COMPANION CARD & DIRECT CHATS)
// ==================================================
class ChatsInboxScreen extends StatefulWidget {
  final Color accentColor;
  const ChatsInboxScreen({super.key, required this.accentColor});

  @override
  State<ChatsInboxScreen> createState() => _ChatsInboxScreenState();
}

class _ChatsInboxScreenState extends State<ChatsInboxScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  void _openChatOptions(BuildContext context, String peerUid, String peerName, String chatRoomId, bool isPinned, String myUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: kNeonCyan),
              title: Text(isPinned ? 'Unpin Conversation' : AppLanguage.tr('pin_chat')),
              onTap: () async {
                Navigator.pop(ctx);
                final userDoc = FirebaseFirestore.instance.collection('users').doc(myUid);
                if (isPinned) {
                  await userDoc.update({'pinnedChats': FieldValue.arrayRemove([peerUid])});
                } else {
                  await userDoc.update({'pinnedChats': FieldValue.arrayUnion([peerUid])});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.white70),
              title: Text(AppLanguage.tr('delete_me')),
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('users').doc(myUid).collection('hiddenChats').doc(chatRoomId).set({'hidden': true});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: kHorrorCrimson),
              title: Text(AppLanguage.tr('delete_everyone'), style: const TextStyle(color: kHorrorCrimson)),
              onTap: () async {
                Navigator.pop(ctx);
                final batch = FirebaseFirestore.instance.batch();
                final msgs = await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').get();
                for (var doc in msgs.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(backgroundColor: kVoidBlack, elevation: 0, title: const Text('CHATS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16))),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
        builder: (ctx, userSnap) {
          final myData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final pinnedChats = List<String>.from(myData['pinnedChats'] ?? []);

          return Column(
            children: [
              // 1. AI FRIEND CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [kCardDark, kNeonPurple.withOpacity(0.25)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.accentColor, width: 1.2)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: widget.accentColor, child: const Icon(Icons.auto_awesome, color: Colors.black, size: 20)),
                  title: const Text('Avatar Friend (AI Companion)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  subtitle: const Text('Multilingual AI Oracle • Always Online', style: TextStyle(color: kMistyGreen, fontSize: 11)),
                  trailing: Icon(Icons.chevron_right, color: widget.accentColor),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarAIChatScreen())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    filled: true, fillColor: kCardDark,
                    prefixIcon: const Icon(Icons.search, color: kNeonCyan, size: 20),
                    hintText: 'Search chats...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return Center(child: CircularProgressIndicator(color: widget.accentColor));
                    var users = snap.data!.docs.where((d) => d.id != myUid).toList();

                    if (_search.isNotEmpty) {
                      users = users.where((u) => (u.data() as Map<String, dynamic>)['name'].toString().toLowerCase().contains(_search)).toList();
                    }

                    users.sort((a, b) {
                      final aPinned = pinnedChats.contains(a.id);
                      final bPinned = pinnedChats.contains(b.id);
                      if (aPinned && !bPinned) return -1;
                      if (!aPinned && bPinned) return 1;
                      return 0;
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: users.length,
                      itemBuilder: (ctx, i) {
                        final u = users[i].data() as Map<String, dynamic>;
                        final peerUid = users[i].id;
                        final peerName = u['name'] ?? 'Explorer';
                        final isOnline = u['isOnline'] == true;
                        final isPinned = pinnedChats.contains(peerUid);
                        final list = [myUid, peerUid]..sort();
                        final chatRoomId = '${list[0]}_${list[1]}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: isPinned ? kNeonCyan.withOpacity(0.5) : Colors.white12)),
                          child: ListTile(
                            onLongPress: () => _openChatOptions(context, peerUid, peerName, chatRoomId, isPinned, myUid),
                            leading: Stack(
                              children: [
                                CircleAvatar(backgroundColor: widget.accentColor.withOpacity(0.2), child: Text(peerName[0].toUpperCase(), style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold))),
                                if (isOnline)
                                  Positioned(right: 0, bottom: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: kMistyGreen, shape: BoxShape.circle))),
                              ],
                            ),
                            title: Row(
                              children: [
                                Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (isPinned) ...[const SizedBox(width: 6), const Icon(Icons.push_pin, size: 14, color: kNeonCyan)],
                              ],
                            ),
                            subtitle: Text(isOnline ? AppLanguage.tr('online') : 'Offline', style: TextStyle(color: isOnline ? kMistyGreen : Colors.white38, fontSize: 11)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AvatarDirectChatScreen(peerUid: peerUid, peerName: peerName))),
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
// MULTILINGUAL AI CHAT SCREEN
// ==================================================
class AvatarAIChatScreen extends StatefulWidget {
  const AvatarAIChatScreen({super.key});

  @override
  State<AvatarAIChatScreen> createState() => _AvatarAIChatScreenState();
}

class _AvatarAIChatScreenState extends State<AvatarAIChatScreen> {
  final _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {'sender': 'ai', 'text': 'Greetings, Explorer. I am Avatar Friend. Speak to me in any language—Hindi, English, or beyond. What mystery shall we decode today?'}
  ];
  bool isThinking = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendToAI() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'me', 'text': text});
      isThinking = true;
    });
    _msgController.clear();
    _scrollToBottom();

    final aiReply = await AvatarAIEngine.getAIResponse(text);

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': aiReply});
        isThinking = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVoidBlack,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        title: const Row(
          children: [
            CircleAvatar(radius: 14, backgroundColor: kNeonCyan, child: Icon(Icons.auto_awesome, size: 14, color: Colors.black)),
            SizedBox(width: 10),
            Text('Avatar Friend (AI)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isMe = msg['sender'] == 'me';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? kNeonPurple : kCardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: kNeonCyan.withOpacity(0.3)),
                    ),
                    child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
                  ),
                );
              },
            ),
          ),
          if (isThinking)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Avatar Friend is channeling dimensions...', style: TextStyle(color: kNeonCyan, fontSize: 11, fontStyle: FontStyle.italic)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: kCardDark,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true, fillColor: kVoidBlack,
                        hintText: 'Type in any language...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.send_rounded, color: kNeonCyan), onPressed: _sendToAI),
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
// DIRECT PEER CHAT (WITH 3-DAY PROFILE UNLOCK, TYPING, SEEN TICKS & UNSEND)
// ==================================================
class AvatarDirectChatScreen extends StatefulWidget {
  final String peerUid;
  final String peerName;
  const AvatarDirectChatScreen({super.key, required this.peerUid, required this.peerName});

  @override
  State<AvatarDirectChatScreen> createState() => _AvatarDirectChatScreenState();
}

class _AvatarDirectChatScreenState extends State<AvatarDirectChatScreen> {
  final _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String chatRoomId;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final list = [myUid, widget.peerUid]..sort();
    chatRoomId = '${list[0]}_${list[1]}';
    _markMessagesAsSeen();
  }

  void _markMessagesAsSeen() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final unreadMsgs = await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').where('senderId', isEqualTo: widget.peerUid).where('isSeen', isEqualTo: false).get();
    for (var doc in unreadMsgs.docs) {
      doc.reference.update({'isSeen': true});
    }
  }

  void _onTyping(String text) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    FirebaseFirestore.instance.collection('users').doc(myUid).update({'typingTo': widget.peerUid});
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      FirebaseFirestore.instance.collection('users').doc(myUid).update({'typingTo': ''});
    });
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': myUid,
      'text': text,
      'reaction': '',
      'isSeen': false,
      'deletedFor': [],
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    _msgController.clear();
    FirebaseFirestore.instance.collection('users').doc(myUid).update({'typingTo': ''});
  }

  void _showMessageOptions(BuildContext context, String msgId, Map<String, dynamic> msgData, String myUid) {
    final isMe = msgData['senderId'] == myUid;
    final isSeen = msgData['isSeen'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '🔥', '🌌', '👁️', '😂'].map((emoji) {
                return InkWell(
                  onTap: () {
                    FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').doc(msgId).update({'reaction': emoji});
                    Navigator.pop(ctx);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                );
              }).toList(),
            ),
            const Divider(color: Colors.white12, height: 24),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.white70),
              title: Text(AppLanguage.tr('delete_me')),
              onTap: () {
                FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').doc(msgId).update({
                  'deletedFor': FieldValue.arrayUnion([myUid]),
                });
                Navigator.pop(ctx);
              },
            ),
            if (isMe && !isSeen)
              ListTile(
                leading: const Icon(Icons.undo_rounded, color: kHorrorCrimson),
                title: Text(AppLanguage.tr('unsend'), style: const TextStyle(color: kHorrorCrimson, fontWeight: FontWeight.bold)),
                subtitle: const Text('Allowed because recipient has not seen yet', style: TextStyle(fontSize: 10, color: Colors.white38)),
                onTap: () {
                  FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').doc(msgId).delete();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileModal(BuildContext context, Map<String, dynamic> peerData, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUnlocked ? peerData['name'] ?? 'Explorer' : 'Encrypted Identity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUnlocked) ...[
              CircleAvatar(radius: 40, backgroundColor: kNeonPurple, child: Text((peerData['name'] ?? 'E')[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white))),
              const SizedBox(height: 12),
              Text('Rank: ${peerData['rank'] ?? 'Seeker'}', style: const TextStyle(color: kNeonCyan, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(peerData['bio'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            ] else ...[
              const Icon(Icons.lock_clock, size: 48, color: Colors.white38),
              const SizedBox(height: 12),
              Text(AppLanguage.tr('profile_locked'), style: const TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.peerUid).snapshots(),
          builder: (ctx, snap) {
            final data = snap.data?.data() as Map<String, dynamic>? ?? {};
            final isOnline = data['isOnline'] == true;
            final isTyping = data['typingTo'] == myUid;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(isTyping ? AppLanguage.tr('typing') : (isOnline ? AppLanguage.tr('online') : 'Offline'), style: TextStyle(fontSize: 11, color: isTyping ? kNeonCyan : (isOnline ? kMistyGreen : Colors.white38))),
              ],
            );
          },
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').orderBy('createdAt', descending: false).snapshots(),
            builder: (ctx, snap) {
              final msgs = snap.data?.docs ?? [];
              bool isThreeDaysConnected = false;
              if (msgs.isNotEmpty) {
                final firstMsgTime = (msgs.first.data() as Map<String, dynamic>)['createdAt'] ?? 0;
                final diff = DateTime.now().millisecondsSinceEpoch - (firstMsgTime as int);
                isThreeDaysConnected = diff >= (3 * 24 * 60 * 60 * 1000);
              }

              return IconButton(
                icon: Icon(isThreeDaysConnected ? Icons.account_circle : Icons.lock_outline, color: isThreeDaysConnected ? kNeonCyan : Colors.white38),
                tooltip: 'Profile Details',
                onPressed: () async {
                  final peerSnap = await FirebaseFirestore.instance.collection('users').doc(widget.peerUid).get();
                  if (context.mounted) {
                    _showProfileModal(context, peerSnap.data() ?? {}, isThreeDaysConnected);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').orderBy('createdAt', descending: true).snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kNeonCyan));
                final messages = snap.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                  return !deletedFor.contains(myUid);
                }).toList();

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == myUid;
                    final isSeen = msg['isSeen'] == true;
                    final reaction = msg['reaction'] ?? '';

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(context, messages[i].id, msg, myUid),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: isMe ? kNeonPurple : kCardDark, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (reaction.isNotEmpty) Text(reaction, style: const TextStyle(fontSize: 12)),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(isSeen ? Icons.done_all : Icons.done, size: 14, color: isSeen ? kNeonCyan : Colors.white38),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: kCardDark,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onChanged: _onTyping,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true, fillColor: kVoidBlack,
                        hintText: 'Type message...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.send_rounded, color: kNeonCyan), onPressed: _send),
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
// TAB 6: EXPLORER PROFILE
// ==================================================
class ExplorerProfileScreen extends StatelessWidget {
  final Color accentColor;
  final Function(String) onVaultSelect;
  const ExplorerProfileScreen({super.key, required this.accentColor, required this.onVaultSelect});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white60), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: accentColor));
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Explorer';
          final bio = data['bio'] ?? 'Exploring Avatar Multiverse';
          final rank = data['rank'] ?? 'Seeker of the Void';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: kNeonPurple.withOpacity(0.4),
                    child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('@${data['username'] ?? 'avatar_user'}', style: TextStyle(color: accentColor, fontSize: 12)),
                const SizedBox(height: 6),
                Text(bio, style: const TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor)),
                  child: Text('Rank: $rank', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
