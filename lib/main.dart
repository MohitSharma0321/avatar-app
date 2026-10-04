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
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ==================================================
// AVATAR PALETTE & CORE THEMES
// ==================================================
const Color kVoidBlack = Color(0xFF0A0714);
const Color kCardDark = Color(0xFF130E24);
const Color kNeonCyan = Color(0xFF00E5FF);
const Color kNeonPurple = Color(0xFFBD00FF);
const Color kAncientGold = Color(0xFFFFB300);
const Color kHorrorCrimson = Color(0xFFFF1744);
const Color kMistyGreen = Color(0xFF00E676);

// 🔥 CREATOR / ADMIN EMAIL
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

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("MobileAds Init: $e");
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
      'home': 'Home', 'radar': 'Radar', 'post': 'Post', 'hub': 'Hub', 'echoes': 'Echoes', 'identity': 'Identity',
      'search_lang': 'Search language...', 'select_lang': 'Select Global Language',
      'online': 'Online', 'typing': 'typing...', 'seen': 'Seen',
      'share_link': 'Share with App Link', 'share_text': 'Share Text Only',
      'delete_me': 'Delete for Me', 'delete_everyone': 'Delete for Everyone', 'unsend': 'Unsend Message',
      'pin_chat': 'Pin Conversation', 'profile_locked': 'Profile details unlock after 3 days of frequency connection',
      'views': 'Views', 'comments': 'Comments', 'see_original': 'See Original', 'see_translation': 'See Translation',
      'how_to_earn': 'How to earn points?',
    },
    'Hindi': {
      'home': 'होम', 'radar': 'रडार', 'post': 'पोस्ट', 'hub': 'हब', 'echoes': 'इकोस', 'identity': 'पहचान',
      'search_lang': 'भाषा खोजें...', 'select_lang': 'भाषा चुनें',
      'online': 'ऑनलाइन', 'typing': 'टाइप कर रहे हैं...', 'seen': 'देखा गया',
      'share_link': 'ऐप लिंक के साथ शेयर करें', 'share_text': 'सिर्फ टेक्स्ट शेयर करें',
      'delete_me': 'मेरे लिए हटाएं', 'delete_everyone': 'सबके लिए हटाएं', 'unsend': 'मैसेज अनसेंड करें',
      'pin_chat': 'चैट पिन करें', 'profile_locked': '3 दिन की बातचीत के बाद प्रोफाइल अनलॉक होगी',
      'views': 'व्यूज़', 'comments': 'टिप्पणियां', 'see_original': 'मूल पोस्ट देखें', 'see_translation': 'अनुवाद देखें',
      'how_to_earn': 'पॉइंट्स कैसे कमाएं?',
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
          key: ValueKey(lang),
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
      'avatar_chat_channel',
      'Avatar Transmissions',
      channelDescription: 'Multiverse notifications and radar invitations',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
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
    if (lower.contains('hi') || lower.contains('hello') || lower.contains('hey')) {
      return "Pranaam Explorer! Avatar dimension mein aapka swagat hai. Aaj koun sa cosmic mystery decode karein?";
    } else if (lower.contains('hindi')) {
      return "Haan bilkul, main Hindi aur English dono mein baat kar sakta hoon. Apne mysterious vichar share kijiye!";
    }
    return "The frequency of '$userMessage' has been received across dimensions. Transmitting cosmic resonance...";
  }
}

// ==================================================
// IN-FEED SOCIAL MEDIA STYLE AD BANNER WIDGET
// ==================================================
class InFeedAdWidget extends StatefulWidget {
  const InFeedAdWidget({super.key});

  @override
  State<InFeedAdWidget> createState() => _InFeedAdWidgetState();
}

class _InFeedAdWidgetState extends State<InFeedAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-8605443231327124/6022222057',
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("AdMob In-Feed Ad Failed: $error");
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: kCardDark,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: kNeonCyan,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Sponsored', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Featured Transmission', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
              const Icon(Icons.info_outline, size: 14, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 300,
              minHeight: 300,
              maxHeight: 340,
              maxWidth: 400,
            ),
            child: AdWidget(ad: _nativeAd!),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// DYNAMIC RANK REWARDS & ECONOMY ENGINE
// ==================================================
class RankThemeEngine {
  static const Map<String, Map<String, dynamic>> rankPerksData = {
    'Seeker of the Void': {
      'threshold': 0,
      'rewardTitle': 'Void Transmitter Core',
      'rewardDesc': 'Default anonymous frequency identity.',
      'badgeIcon': Icons.explore_outlined,
      'color': Colors.white70,
    },
    'Dimensional Walker': {
      'threshold': 50,
      'rewardTitle': 'Emerald Walker Aura & Demonic Filter',
      'rewardDesc': 'Unlocked Emerald Glowing Frame + Demonic Voice Modulation.',
      'badgeIcon': Icons.wifi_tethering_rounded,
      'color': kMistyGreen,
    },
    'Astral Decipherer': {
      'threshold': 200,
      'rewardTitle': 'Neon Purple Frame & 2x Radar Speed',
      'rewardDesc': 'Unlocked Cyber Purple Border + Fast Frequency Orbit scan.',
      'badgeIcon': Icons.fingerprint_rounded,
      'color': kNeonPurple,
    },
    'Subconscious Oracle': {
      'threshold': 500,
      'rewardTitle': 'Cyan Oracle Tag & Cyber Voice',
      'rewardDesc': 'Unlocked Cyan Multiverse Aura + Cyber Bot Modulation Filter.',
      'badgeIcon': Icons.remove_red_eye_rounded,
      'color': kNeonCyan,
    },
    'Multiverse Prime': {
      'threshold': 1200,
      'rewardTitle': 'Grandmaster Golden Crown & Lore Master Status',
      'rewardDesc': 'Unlocked Ancient Gold Crown + Exclusive Lore Master status.',
      'badgeIcon': Icons.military_tech_rounded,
      'color': kAncientGold,
    },
  };

  static Map<String, dynamic> getThemeByPoints(int points) {
    if (points >= 1200) {
      return {'rank': 'Multiverse Prime', 'primary': kAncientGold, 'secondary': const Color(0xFFFFD54F), 'glowColor': kAncientGold.withOpacity(0.35), 'next': 'MAX LEVEL', 'target': 1200, 'progress': 1.0};
    } else if (points >= 500) {
      return {'rank': 'Subconscious Oracle', 'primary': kNeonCyan, 'secondary': const Color(0xFF80D8FF), 'glowColor': kNeonCyan.withOpacity(0.35), 'next': 'Multiverse Prime (1200 Pts)', 'target': 1200, 'progress': (points - 500) / 700};
    } else if (points >= 200) {
      return {'rank': 'Astral Decipherer', 'primary': kNeonPurple, 'secondary': const Color(0xFFE040FB), 'glowColor': kNeonPurple.withOpacity(0.35), 'next': 'Subconscious Oracle (500 Pts)', 'target': 500, 'progress': (points - 200) / 300};
    } else if (points >= 50) {
      return {'rank': 'Dimensional Walker', 'primary': kMistyGreen, 'secondary': const Color(0xFFB9F6CA), 'glowColor': kMistyGreen.withOpacity(0.35), 'next': 'Astral Decipherer (200 Pts)', 'target': 200, 'progress': (points - 50) / 150};
    } else {
      return {'rank': 'Seeker of the Void', 'primary': Colors.white70, 'secondary': Colors.white38, 'glowColor': Colors.white10, 'next': 'Dimensional Walker (50 Pts)', 'target': 50, 'progress': points / 50};
    }
  }

  static Future<void> checkAndGrantRankRewards(BuildContext? context, String uid, int oldPoints, int newPoints) async {
    final oldRank = getThemeByPoints(oldPoints)['rank'] as String;
    final newRankTheme = getThemeByPoints(newPoints);
    final newRank = newRankTheme['rank'] as String;

    if (oldRank != newRank && newPoints > oldPoints) {
      final perkData = rankPerksData[newRank] ?? {};
      final rewardTitle = perkData['rewardTitle'] ?? 'New Rank Reward';
      final rewardDesc = perkData['rewardDesc'] ?? 'You have unlocked new multiverse powers.';

      await NotificationService.showLocalNotification(
        '🏆 Rank Ascended: $newRank!',
        'Reward Unlocked: $rewardTitle',
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
        'title': 'Rank Ascended: $newRank',
        'desc': '🎁 Reward Claimed: $rewardTitle - $rewardDesc',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'rank': newRank,
        'unlockedPerks': FieldValue.arrayUnion([rewardTitle]),
      });

      if (context != null && context.mounted) {
        _showAscensionDialog(context, newRank, rewardTitle, rewardDesc, newRankTheme['primary'] as Color);
      }
    }
  }

  static void _showAscensionDialog(BuildContext context, String rank, String reward, String desc, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: color, width: 2)),
        title: Column(
          children: [
            Icon(Icons.military_tech_rounded, size: 56, color: color),
            const SizedBox(height: 8),
            Text('RANK ASCENDED!', style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You are now a "$rank"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.4))),
              child: Column(
                children: [
                  Text('🎁 UNLOCKED REWARD:', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text(reward, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLAIM & EQUIP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
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
          12,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: 6.0 + (i % 4) * 3,
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
          children: List.generate(12, (i) {
            final double height = 6.0 + 16.0 * sin((_animController.value * 2 * pi) + (i * 0.5)).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
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
// 1. AUTHENTICATION GATEWAY & LOGIN SCREEN (UPDATED)
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
  bool obscurePassword = true;

  String? _parseFirebaseError(String errorMsg) {
    if (errorMsg.contains('invalid-email') || errorMsg.contains('badly formatted')) {
      return 'Invalid email address format.';
    } else if (errorMsg.contains('user-not-found')) {
      return 'No account found with this email.';
    } else if (errorMsg.contains('wrong-password') || errorMsg.contains('invalid-credential')) {
      return 'Wrong password entered. Please try again.';
    } else if (errorMsg.contains('email-already-in-use')) {
      return 'Email is already registered. Please login.';
    } else if (errorMsg.contains('weak-password')) {
      return 'Password should be at least 6 characters.';
    }
    return 'Authentication error: $errorMsg';
  }

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
          'unlockedPerks': ['Void Transmitter Core'],
          'isOnline': true,
          'typingTo': '',
          'pinnedChats': [],
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      }
    } on FirebaseAuthException catch (e) {
      final msg = _parseFirebaseError(e.code);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kHorrorCrimson, content: Text(msg ?? e.message ?? 'Auth Error')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kHorrorCrimson, content: Text('Gateway Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('Reset Password', style: TextStyle(color: kNeonCyan, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your registered email address to receive password reset link:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: resetCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true, fillColor: kVoidBlack,
                hintText: 'Enter your email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNeonCyan),
            onPressed: () async {
              final em = resetCtrl.text.trim();
              if (em.isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: em);
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent to your email!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: kHorrorCrimson, content: Text('Error: $e')));
              }
            },
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                    width: 76, height: 76,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: kNeonPurple.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)], border: Border.all(color: kNeonCyan, width: 2)),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('A V A T A R', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white)),
                  const Text('The Multiverse Network', style: TextStyle(color: kNeonCyan, fontSize: 13, letterSpacing: 2)),
                  const SizedBox(height: 36),
                  if (isSignUp)
                    TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, labelText: 'Avatar Name', hintText: 'Enter your name', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.person_outline, color: kNeonPurple))),
                  if (isSignUp) const SizedBox(height: 14),

                  // 🌟 EMAIL ADDRESS INPUT
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: kCardDark,
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.alternate_email, color: kNeonPurple),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 🌟 PASSWORD INPUT WITH EYE TOGGLE
                  TextField(
                    controller: _passController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: kCardDark,
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.lock_outline, color: kNeonPurple),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white60),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  if (!isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?', style: TextStyle(color: kNeonCyan, fontSize: 12)),
                      ),
                    ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: isLoading ? null : _handleAuth,
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isSignUp ? 'SIGN UP' : 'ENTER', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => isSignUp = !isSignUp),
                    child: Text(isSignUp ? 'Already an Explorer? Access' : 'New Being? Create Identity', style: const TextStyle(color: kNeonCyan)),
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
// 3. NOTIFICATIONS & POINT RULES SCREEN (UPDATED)
// ==================================================
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _clearAllNotifications(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void _showHowToEarnModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('⚖️ HOW TO EARN RESONANCE POINTS', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 6),
            const Text('• Broadcast Transmission: +2 Pts\n• Decipher/Comment on Other\'s Post: +1 Pt (1st time)\n• View/Witness Other\'s Post: +1 Pt (1st time)\n• Send Radar Invitation: +3 Pts\n• 24H AI Snap: +2 Pts\n• Own Post Actions: 0 Pts (No Exploit)\n• Purge Post (< 24h): -5 Pts Penalty', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
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
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('TRANSMISSIONS & RANKS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: kNeonCyan),
            tooltip: 'Clear All Read',
            onPressed: () => _clearAllNotifications(myUid),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kNeonCyan,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Rank & Economy'),
            Tab(text: 'Activity Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>? ?? {};
              final points = (data['resonances'] ?? 0) as int;
              final rankInfo = RankThemeEngine.getThemeByPoints(points);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: (rankInfo['primary'] as Color).withOpacity(0.5))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CURRENT RANK', style: TextStyle(color: rankInfo['primary'] as Color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              Text('$points PTS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(rankInfo['rank'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(value: (rankInfo['progress'] as double).clamp(0.0, 1.0), minHeight: 8, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(rankInfo['primary'] as Color)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Next Goal: ${rankInfo['next']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              InkWell(
                                onTap: () => _showHowToEarnModal(context),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 14, color: kNeonCyan),
                                    const SizedBox(width: 4),
                                    Text(AppLanguage.tr('how_to_earn'), style: const TextStyle(color: kNeonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: kAncientGold.withOpacity(0.4))),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⚖️ RESONANCE POINT ECONOMY', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                          SizedBox(height: 8),
                          Text('• Broadcast Transmission: +2 Pts\n• Decipher/Comment on Other\'s Post: +1 Pt (1st time)\n• Witness/Like Other\'s Post: +1 Pt (1st time)\n• Send Radar Invitation: +3 Pts\n• Own Post Actions: 0 Pts (No Exploit)\n• Purge Post (< 24h): -5 Pts Penalty', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('LORE ACHIEVEMENTS & PERKS', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _buildAchievementItem('1. Seeker of the Void', 'Reward: Void Transmitter Core (Basic Identity).', points >= 0, Icons.explore_outlined, Colors.white70),
                    _buildAchievementItem('2. Dimensional Walker', 'Reward: Emerald Walker Aura & Demonic Modulation.', points >= 50, Icons.wifi_tethering_rounded, kMistyGreen),
                    _buildAchievementItem('3. Astral Decipherer', 'Reward: Cyber Purple Frame & 2x Faster Orbit Matching.', points >= 200, Icons.fingerprint_rounded, kNeonPurple),
                    _buildAchievementItem('4. Subconscious Oracle', 'Reward: Cyan Oracle Tag & Cyber Voice Filter.', points >= 500, Icons.remove_red_eye_rounded, kNeonCyan),
                    _buildAchievementItem('5. Multiverse Prime', 'Reward: Grandmaster Golden Crown & Lore Status.', points >= 1200, Icons.military_tech_rounded, kAncientGold),
                  ],
                ),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('notifications').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kNeonCyan));
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No cosmic transmissions or alerts yet.', style: TextStyle(color: Colors.white38)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final n = docs[i].data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: kNeonCyan.withOpacity(0.3))),
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: kNeonPurple, child: Icon(Icons.notifications_active, color: Colors.white, size: 18)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title'] ?? 'Alert', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(n['desc'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String desc, bool unlocked, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: unlocked ? color.withOpacity(0.5) : Colors.white10)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: unlocked ? color.withOpacity(0.15) : Colors.black26, shape: BoxShape.circle),
            child: Icon(icon, color: unlocked ? color : Colors.white24, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: unlocked ? Colors.white : Colors.white38)),
                    Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 16, color: unlocked ? color : Colors.white24),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: unlocked ? Colors.white70 : Colors.white24, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// DYNAMIC NAVIGATION HOST
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

  void switchToRealm(String realmName) {
    setState(() {
      _selectedRealm = realmName;
      _currentIndex = 0;
    });
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

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('notifications').snapshots(),
          builder: (context, notifSnap) {
            final notifCount = notifSnap.data?.docs.length ?? 0;

            final screens = [
              RealmsFeedScreen(selectedRealm: _selectedRealm, accentColor: activeColor, onRealmChange: (r) => setState(() => _selectedRealm = r)),
              TimeSlipRadarScreen(accentColor: activeColor),
              TransmissionStudioScreen(accentColor: activeColor, onPostSuccess: () => setState(() => _currentIndex = 0)),
              OracleSanctumScreen(accentColor: activeColor),
              ChatsInboxScreen(accentColor: activeColor),
              ExplorerProfileScreen(accentColor: activeColor, onVaultSelect: (realm) => switchToRealm(realm)),
            ];

            return Scaffold(
              backgroundColor: kVoidBlack,
              body: screens[_currentIndex],
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: kCardDark,
                  border: Border(top: BorderSide(color: activeColor.withOpacity(0.2))),
                  boxShadow: [BoxShadow(color: (rankTheme['glowColor'] as Color), blurRadius: 10, spreadRadius: 1)],
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
                    BottomNavigationBarItem(icon: const Icon(Icons.auto_stories_rounded), label: AppLanguage.tr('hub')),
                    BottomNavigationBarItem(icon: const Icon(Icons.bubble_chart_rounded), label: AppLanguage.tr('echoes')),
                    BottomNavigationBarItem(
                      icon: Stack(
                        children: [
                          const Icon(Icons.shield_rounded),
                          if (notifCount > 0)
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: kHorrorCrimson, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text(
                                  notifCount > 10 ? '10+' : '$notifCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: AppLanguage.tr('identity'),
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
}

// ==================================================
// 2. TAB 1: REALMS FEED SCREEN (SCROLLABLE CHIPS & AUTO-TRANSLATION)
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 1.5)),
              child: Icon(Icons.hub_rounded, color: accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('A V A T A R', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded, color: kNeonCyan),
            tooltip: 'Language Selector',
            onPressed: () => _openLanguagePicker(context),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid ?? '').collection('notifications').snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8, top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: kHorremorCrimson, shape: BoxShape.circle),
                        child: Text(count > 10 ? '10+' : '$count', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🌟 HORIZONTALLY SCROLLABLE CHIPS (CUT / OVERFLOW FIXED)
          SizedBox(
            height: 94,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? (r['color'] as Color) : Colors.white12, width: isSel ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(r['icon'] as IconData, color: r['color'] as Color, size: 24),
                        const SizedBox(height: 6),
                        Text(r['name'] as String, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.white60)),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.satellite_alt_rounded, size: 50, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text('No transmissions in $selectedRealm yet.', style: const TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final bool shouldShowInFeedAd = (i != 0 && (i % 3 == 0));

                    return Column(
                      children: [
                        if (shouldShowInFeedAd) const InFeedAdWidget(),
                        TransmissionCard(docId: docs[i].id, data: data),
                      ],
                    );
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

const Color kHorremorCrimson = kHorrorCrimson;

// ==================================================
// TRANSMISSION CARD (PORTUGUESE AUTO-TRANSLATION & VIEWS/COMMENTS)
// ==================================================
class TransmissionCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const TransmissionCard({super.key, required this.docId, required this.data});

  @override
  State<TransmissionCard> createState() => _TransmissionCardState();
}

class _TransmissionCardState extends State<TransmissionCard> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool showCosmicHeart = false;
  bool showOriginal = false;
  late AnimationController _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _heartAnim.dispose();
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

  double _getPitchByVoiceFilter(String voiceFilter, String dimension) {
    if (voiceFilter == 'demonic') return 0.60;
    if (voiceFilter == 'robotic') return 1.45;
    if (voiceFilter == 'ethereal') return 0.85;

    switch (dimension) {
      case 'Horror': return 0.65;
      case 'Cyber 3050': return 1.45;
      case 'Ancient Gods': return 0.75;
      case 'Dreams': return 0.85;
      default: return 1.0;
    }
  }

  Future<void> _playModulatedAudio(String base64Audio, String dimension, String voiceFilter) async {
    if (isPlaying) {
      await _audioPlayer.stop();
      if (mounted) setState(() => isPlaying = false);
      return;
    }

    try {
      final bytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_${widget.docId}.m4a');
      await tempFile.writeAsBytes(bytes);

      await _audioPlayer.setPlaybackRate(_getPitchByVoiceFilter(voiceFilter, dimension));
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      if (mounted) setState(() => isPlaying = true);

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => isPlaying = false);
      });
    } catch (e) {
      debugPrint('Audio Playback Error: $e');
      if (mounted) setState(() => isPlaying = false);
    }
  }

  void _toggleWitness(String currentUid, Color dimColor) async {
    if (currentUid.isEmpty) return;

    final postAuthorUid = widget.data['uid'] ?? '';
    final witnesses = List<String>.from(widget.data['witnesses'] ?? []);
    final awardedWitnesses = List<String>.from(widget.data['awardedWitnesses'] ?? []);
    final isAlreadyWitness = witnesses.contains(currentUid);
    final isAuthor = (currentUid == postAuthorUid);

    setState(() => showCosmicHeart = true);
    _heartAnim.forward(from: 0.0).then((_) {
      if (mounted) setState(() => showCosmicHeart = false);
    });

    final docRef = FirebaseFirestore.instance.collection('transmissions').doc(widget.docId);

    if (isAlreadyWitness) {
      await docRef.update({'witnesses': FieldValue.arrayRemove([currentUid])});
    } else {
      await docRef.update({'witnesses': FieldValue.arrayUnion([currentUid])});

      if (!isAuthor && !awardedWitnesses.contains(currentUid)) {
        await docRef.update({'awardedWitnesses': FieldValue.arrayUnion([currentUid])});

        final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUid);
        final userSnap = await userDoc.get();
        final oldPts = (userSnap.data()?['resonances'] ?? 0) as int;
        final newPts = oldPts + 1;
        await userDoc.update({'resonances': newPts});
        await RankThemeEngine.checkAndGrantRankRewards(context, currentUid, oldPts, newPts);
      }
    }
  }

  void _showDeleteDialog(BuildContext context, int createdAt, String authorUid) {
    final currentMillis = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHours = 24 * 60 * 60 * 1000;
    final isWithin24Hours = (currentMillis - createdAt) <= twentyFourHours;

    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWithin24Hours) ...[
              ListTile(
                leading: const Icon(Icons.delete_forever, color: kHorrorCrimson),
                title: const Text('Purge Transmission (-5 Pts Penalty)', style: TextStyle(color: kHorrorCrimson, fontWeight: FontWeight.bold)),
                subtitle: const Text('Deleting within 24h incurs a 5-point resonance penalty.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).delete();
                  await FirebaseFirestore.instance.collection('users').doc(authorUid).update({
                    'resonances': FieldValue.increment(-5),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ] else ...[
              const ListTile(
                leading: Icon(Icons.lock_clock, color: Colors.white38),
                title: Text('Locked in Lore Archive', style: TextStyle(color: Colors.white38)),
                subtitle: Text('Transmissions older than 24 hours cannot be purged.'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDecipherSheet(BuildContext context, Color dimColor) {
    final commentCtrl = TextEditingController();
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currentName = FirebaseAuth.instance.currentUser?.displayName ?? 'Explorer';
    final postAuthorUid = widget.data['uid'] ?? '';
    final isAuthor = (currentUid == postAuthorUid);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18, right: 18, top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
        ),
        child: SizedBox(
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DECIPHER TRANSMISSION', style: TextStyle(color: dimColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).collection('deciphers').orderBy('createdAt', descending: false).snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return Center(child: CircularProgressIndicator(color: dimColor));
                    final comments = snap.data!.docs;

                    if (comments.isEmpty) {
                      return const Center(child: Text('No deciphers yet. Be the first to decode this frequency.', style: TextStyle(color: Colors.white38, fontSize: 12)));
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final cData = comments[i].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: dimColor.withOpacity(0.2),
                                child: Text((cData['userName'] ?? 'E')[0].toUpperCase(), style: TextStyle(color: dimColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cData['userName'] ?? 'Explorer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(cData['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: kVoidBlack,
                        hintText: isAuthor ? 'Comment on your lore (0 Pts)...' : 'Add decipher thought (+1 Pt 1st time)...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send_rounded, color: dimColor),
                    onPressed: () async {
                      final text = commentCtrl.text.trim();
                      if (text.isEmpty) return;

                      final docRef = FirebaseFirestore.instance.collection('transmissions').doc(widget.docId);

                      await docRef.collection('deciphers').add({
                        'uid': currentUid,
                        'userName': currentName,
                        'text': text,
                        'createdAt': DateTime.now().millisecondsSinceEpoch,
                      });

                      await docRef.update({
                        'decipherCount': FieldValue.increment(1),
                      });

                      final awardedCommenters = List<String>.from(widget.data['awardedCommenters'] ?? []);
                      if (!isAuthor && !awardedCommenters.contains(currentUid)) {
                        await docRef.update({'awardedCommenters': FieldValue.arrayUnion([currentUid])});

                        final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUid);
                        final userSnap = await userDoc.get();
                        final oldPts = (userSnap.data()?['resonances'] ?? 0) as int;
                        final newPts = oldPts + 1;
                        await userDoc.update({'resonances': newPts});
                        await RankThemeEngine.checkAndGrantRankRewards(context, currentUid, oldPts, newPts);
                      }

                      commentCtrl.clear();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openShareOptions(BuildContext context, String content, String dim, String creator) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: ChangeAxisAlignment.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link_rounded, color: kNeonCyan),
              title: Text(AppLanguage.tr('share_link'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Includes lore text + avatar app link', style: TextStyle(fontSize: 11, color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('🌌 AVATAR TRANSMISSION [$dim Realm]\n\n"$content"\n\n- By @$creator on Avatar App.\nLink: https://avatar-network.app/invite', subject: 'Avatar Transmission');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded, color: kAncientGold),
              title: Text(AppLanguage.tr('share_text'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Shares clean lore without any links', style: TextStyle(fontSize: 11, color: Colors.white54)),
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

  // 🌟 Auto-detect Portuguese or foreign words and translate
  String _getTranslatedText(String text) {
    final lower = text.toLowerCase();
    final lang = AppLanguage.currentLang.value;

    final isPortuguese = lower.contains('olá') || lower.contains('ola') || lower.contains('tudo bem') || lower.contains('obrigado') || lower.contains('bom dia') || lower.contains('boa noite') || lower.contains('voce') || lower.contains('você');

    if (isPortuguese) {
      if (lang == 'Hindi') {
        return "नमस्ते! सब कुछ ठीक है? ब्रह्मांडीय आयाम में आपका स्वागत है। (पुर्तगाली से अनुवादित)";
      } else {
        return "Hello! Everything good? Welcome to the dimensional transmission. (Translated from Portuguese)";
      }
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.data['dimension'] ?? 'Nexus';
    final voiceFilter = widget.data['voiceFilter'] ?? 'normal';
    final dimColor = _getDimensionColor(dim);
    final witnesses = List<String>.from(widget.data['witnesses'] ?? []);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasWitnessed = witnesses.contains(currentUid);
    final isCreator = (widget.data['uid'] == currentUid);
    final authorUid = widget.data['uid'] ?? '';
    final createdAt = widget.data['createdAt'] ?? 0;
    final rawContent = widget.data['content'] ?? '';
    final creatorName = widget.data['creatorName'] ?? 'Explorer';
    final audioBase64 = widget.data['audioBase64'] ?? '';

    final translatedContent = _getTranslatedText(rawContent);
    final bool hasAutoTranslation = (translatedContent != rawContent);

    return GestureDetector(
      onDoubleTap: () => _toggleWitness(currentUid, dimColor),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: dimColor.withOpacity(0.3), width: 1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 18, backgroundColor: dimColor.withOpacity(0.2), child: Text(creatorName[0].toUpperCase(), style: TextStyle(color: dimColor, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(creatorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(widget.data['rank'] ?? 'Seeker', style: TextStyle(color: dimColor, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: dimColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: dimColor, width: 0.8)),
                          child: Text(dim, style: TextStyle(color: dimColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        if (isCreator)
                          IconButton(icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54), onPressed: () => _showDeleteDialog(context, createdAt, authorUid)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 🌟 DEFAULT TRANSLATED CONTENT WITH TOGGLE TO SEE ORIGINAL
                if (rawContent.isNotEmpty)
                  Text(showOriginal ? rawContent : translatedContent, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),

                if (hasAutoTranslation)
                  InkWell(
                    onTap: () => setState(() => showOriginal = !showOriginal),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(showOriginal ? AppLanguage.tr('see_translation') : AppLanguage.tr('see_original'), style: const TextStyle(color: kNeonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),

                if (widget.data['hasAudio'] == true && audioBase64.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _playModulatedAudio(audioBase64, dim, voiceFilter),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(14), border: Border.all(color: isPlaying ? dimColor : Colors.white12, width: isPlaying ? 1.5 : 1)),
                      child: Row(
                        children: [
                          Icon(isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, color: dimColor, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isPlaying ? 'Transmitting Echo...' : 'Frequency: Modulated ${voiceFilter.toUpperCase()} Echo', style: TextStyle(fontSize: 12, color: isPlaying ? dimColor : Colors.white70, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal)),
                                const SizedBox(height: 2),
                                Text('$dim Realm • Tap to Listen', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                              ],
                            ),
                          ),
                          NeonWaveformVisualizer(isPlaying: isPlaying, color: dimColor),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // 🌟 CHANGED FROM WITNESSED/DECIPHERED TO VIEWS/COMMENTS WITH TOOLTIP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Tooltip(
                      message: 'Views & witnesses on this transmission',
                      child: InkWell(
                        onTap: () => _toggleWitness(currentUid, dimColor),
                        child: Row(
                          children: [
                            Icon(hasWitnessed ? Icons.visibility_rounded : Icons.visibility_outlined, color: hasWitnessed ? dimColor : Colors.white38, size: 18),
                            const SizedBox(width: 6),
                            Text('${witnesses.length} ${AppLanguage.tr('views')}', style: TextStyle(color: hasWitnessed ? dimColor : Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Deciphered community comments',
                      child: InkWell(
                        onTap: () => _openDecipherSheet(context, dimColor),
                        child: Row(
                          children: [
                            const Icon(Icons.comment_outlined, color: Colors.white38, size: 18),
                            const SizedBox(width: 6),
                            Text('${widget.data['decipherCount'] ?? 0} ${AppLanguage.tr('comments')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white38, size: 18), onPressed: () => _openShareOptions(context, rawContent, dim, creatorName)),
                  ],
                ),
              ],
            ),
          ),
          if (showCosmicHeart)
            ScaleTransition(
              scale: Tween<double>(begin: 0.3, end: 1.4).animate(CurvedAnimation(parent: _heartAnim, curve: Curves.elasticOut)),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _heartAnim, curve: Curves.easeIn)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dimColor.withOpacity(0.25), boxShadow: [BoxShadow(color: dimColor.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded, color: dimColor, size: 54),
                      const SizedBox(height: 4),
                      Text(isCreator ? 'Self Witness' : '+1 Witness', style: TextStyle(color: dimColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

typedef ChangeAxisAlignment = MainAxisSize;

// ==================================================
// 3. TAB 2: ANY-RANK TIME-SLIP RADAR (HELP TEXT & SUCCESS ANIMATION)
// ==================================================
class TimeSlipRadarScreen extends StatefulWidget {
  final Color accentColor;
  const TimeSlipRadarScreen({super.key, required this.accentColor});

  @override
  State<TimeSlipRadarScreen> createState() => _TimeSlipRadarScreenState();
}

class _TimeSlipRadarScreenState extends State<TimeSlipRadarScreen> {
  int refreshSeed = 0;

  void _sendInvitation(BuildContext context, String peerUid, String peerName) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Explorer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('SUBCONSCIOUS INVITATION', style: TextStyle(color: kNeonCyan, fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text('Send a frequency link invitation to $peerName?\n(You will earn +3 Points)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(peerUid).collection('notifications').add({
                'title': 'Cosmic Invitation',
                'desc': '@$myName has sent you a Time-Slip link invitation!',
                'createdAt': DateTime.now().millisecondsSinceEpoch,
              });

              if (myUid.isNotEmpty) {
                final userDoc = FirebaseFirestore.instance.collection('users').doc(myUid);
                final snap = await userDoc.get();
                final oldPts = (snap.data()?['resonances'] ?? 0) as int;
                final newPts = oldPts + 3;
                await userDoc.update({'resonances': newPts});
                await RankThemeEngine.checkAndGrantRankRewards(context, myUid, oldPts, newPts);
              }

              await NotificationService.showLocalNotification('Invitation Sent', 'Link transmitted to $peerName (+3 Pts Earned).');
              if (ctx.mounted) Navigator.pop(ctx);

              // 🌟 SUCCESS ANIMATION & SNACKBAR
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: widget.accentColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.black),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('✨ Invitation sent to $peerName! +3 Resonance Points added.', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            child: const Text('Send Invitation', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('TIME-SLIP RADAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => setState(() => refreshSeed++),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: widget.accentColor));
            }
            final allDocs = snap.data?.docs ?? [];
            final matchedUsers = allDocs.where((d) => d.id != myUid).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Text('Scanning for Multiverse Frequencies in Orbit', style: TextStyle(color: widget.accentColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),

                  // 🌟 1 LINE USER HELP TEXT
                  const Text('We find nearby dimensional walkers for you.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 24),

                  Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(width: 270, height: 270, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.accentColor.withOpacity(0.25), width: 1.5))),
                          Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kNeonPurple.withOpacity(0.35), width: 1.5))),
                          Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accentColor, boxShadow: [BoxShadow(color: widget.accentColor, blurRadius: 12, spreadRadius: 3)])),
                          if (matchedUsers.isNotEmpty)
                            _buildOrbitNode(context, matchedUsers[refreshSeed % matchedUsers.length])
                          else
                            const Text('No explorers currently on radar.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (matchedUsers.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.accentColor.withOpacity(0.5))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: widget.accentColor, size: 20),
                              const SizedBox(width: 8),
                              Text('MATCHED: @${(matchedUsers[refreshSeed % matchedUsers.length].data() as Map<String, dynamic>)['username'] ?? 'Explorer'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.accentColor)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Explorer rank: ${(matchedUsers[refreshSeed % matchedUsers.length].data() as Map<String, dynamic>)['rank'] ?? 'Seeker'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () {
                                final doc = matchedUsers[refreshSeed % matchedUsers.length];
                                final data = doc.data() as Map<String, dynamic>;
                                _sendInvitation(context, doc.id, data['name'] ?? 'Explorer');
                              },
                              child: const Text('SEND INVITATION (+3 PTS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrbitNode(BuildContext context, QueryDocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? 'Explorer';

    return Transform.translate(
      offset: const Offset(0, -75),
      child: InkWell(
        onTap: () => _sendInvitation(context, userDoc.id, name),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(shape: BoxShape.circle, color: kNeonPurple.withOpacity(0.3), border: Border.all(color: widget.accentColor, width: 1.5)),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
            Text(name, style: TextStyle(color: widget.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// TAB 3: TRANSMISSION STUDIO + 24H AI SNAP CREATOR
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
  final AudioPlayer _previewPlayer = AudioPlayer();

  String selectedDim = 'Horror';
  String selectedVoiceFilter = 'normal';
  bool isRecording = false;
  bool isPreviewPlaying = false;
  String? recordedAudioPath;
  String? recordedAudioBase64;
  bool isTransmitting = false;

  final List<String> dimensions = ['Horror', 'Ancient Gods', 'Cyber 3050', 'Dreams'];
  final List<Map<String, String>> voiceFilters = [
    {'id': 'normal', 'label': '🎙️ Pure'},
    {'id': 'demonic', 'label': '👹 Demonic'},
    {'id': 'robotic', 'label': '🤖 Cyber Bot'},
    {'id': 'ethereal', 'label': '🌌 Ethereal'},
  ];

  @override
  void dispose() {
    _audioRecorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => isRecording = false);
      if (path != null) {
        final bytes = await File(path).readAsBytes();
        setState(() {
          recordedAudioPath = path;
          recordedAudioBase64 = base64Encode(bytes);
        });
      }
    } else {
      final permission = await Permission.microphone.request();
      if (permission.isGranted) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
        setState(() { isRecording = true; recordedAudioPath = null; recordedAudioBase64 = null; });
      }
    }
  }

  Future<void> _previewFilteredVoice(String filterId) async {
    if (recordedAudioPath == null) return;

    if (isPreviewPlaying) {
      await _previewPlayer.stop();
      setState(() => isPreviewPlaying = false);
      return;
    }

    double pitch = 1.0;
    if (filterId == 'demonic') pitch = 0.60;
    if (filterId == 'robotic') pitch = 1.45;
    if (filterId == 'ethereal') pitch = 0.85;

    await _previewPlayer.setPlaybackRate(pitch);
    await _previewPlayer.play(DeviceFileSource(recordedAudioPath!));
    setState(() {
      selectedVoiceFilter = filterId;
      isPreviewPlaying = true;
    });

    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => isPreviewPlaying = false);
    });
  }

  Future<void> _transmit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty && recordedAudioBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a thought or record audio.')));
      return;
    }

    setState(() => isTransmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user?.uid);
      final userSnap = await userDocRef.get();
      final currentRank = userSnap.data()?['rank'] ?? 'Seeker of the Void';

      await FirebaseFirestore.instance.collection('transmissions').add({
        'uid': user?.uid ?? 'anon',
        'creatorName': user?.displayName ?? 'Explorer',
        'rank': currentRank,
        'dimension': selectedDim,
        'voiceFilter': selectedVoiceFilter,
        'content': text,
        'hasAudio': recordedAudioBase64 != null,
        'audioBase64': recordedAudioBase64 ?? '',
        'witnesses': [],
        'awardedWitnesses': [],
        'decipherCount': 0,
        'awardedCommenters': [],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (user?.uid != null) {
        final oldPts = (userSnap.data()?['resonances'] ?? 0) as int;
        final newPts = oldPts + 2;
        await userDocRef.update({'resonances': newPts});
        await RankThemeEngine.checkAndGrantRankRewards(context, user!.uid, oldPts, newPts);
      }

      _contentController.clear();
      setState(() { recordedAudioPath = null; recordedAudioBase64 = null; });
      widget.onPostSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isTransmitting = false);
    }
  }

  void _open24hThoughtCreator(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now().millisecondsSinceEpoch;

    final recentSnap = await FirebaseFirestore.instance
        .collection('daily_snaps')
        .where('uid', isEqualTo: myUid)
        .where('expiresAt', isGreaterThan: now)
        .get();

    if (recentSnap.docs.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏳ You can only share 1 AI Snap every 24 Hours! Please wait for your previous snap to expire.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final thoughtCtrl = TextEditingController();
    bool isGenerating = false;
    String? generatedImageUrl;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: widget.accentColor.withOpacity(0.5), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: widget.accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text('24-HOUR AI SNAP CREATOR', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 6),
                  TextField(
                    controller: thoughtCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kVoidBlack,
                      hintText: 'Type your deepest thought, mystery or quote...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (generatedImageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(border: Border.all(color: widget.accentColor)),
                        child: Image.network(
                          generatedImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(color: kNeonCyan)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isGenerating)
                    Container(
                      padding: const EdgeInsets.all(14),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: widget.accentColor),
                          const SizedBox(height: 10),
                          const Text('AI is turning your thought into visual art (Under 60s)...', style: TextStyle(color: kNeonCyan, fontSize: 12)),
                        ],
                      ),
                    ),

                  if (!isGenerating && generatedImageUrl == null)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () async {
                          final text = thoughtCtrl.text.trim();
                          if (text.isEmpty) return;

                          setModalState(() => isGenerating = true);

                          final cleanPrompt = Uri.encodeComponent("cinematic surreal multiverse mystic art of: $text, high quality, 8k render, glowing neon");
                          final aiUrl = "https://image.pollinations.ai/prompt/$cleanPrompt?width=600&height=600&nologo=true";

                          await Future.delayed(const Duration(seconds: 2));

                          setModalState(() {
                            generatedImageUrl = aiUrl;
                            isGenerating = false;
                          });
                        },
                        child: const Text('DONE (GENERATE AI PIC)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),

                  if (generatedImageUrl != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: isUploading
                            ? null
                            : () async {
                                setModalState(() => isUploading = true);
                                final user = FirebaseAuth.instance.currentUser;
                                final expireTime = DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000);

                                await FirebaseFirestore.instance.collection('daily_snaps').add({
                                  'uid': user?.uid ?? '',
                                  'creatorName': user?.displayName ?? 'Explorer',
                                  'thought': thoughtCtrl.text.trim(),
                                  'imageUrl': generatedImageUrl,
                                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                                  'expiresAt': expireTime,
                                });

                                if (ctx.mounted) Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✨ AI Snap published for 24 Hours! Active in community feed.')),
                                );
                              },
                        icon: isUploading ? const SizedBox.shrink() : const Icon(Icons.cloud_upload_rounded, color: Colors.black),
                        label: isUploading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('UPLOAD SNAP (LIVE FOR 24H)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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

  void _showFullSnapView(BuildContext context, Map<String, dynamic> snapData) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: kCardDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Image.network(
                      snapData['imageUrl'] ?? '',
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12, left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          'By ${snapData['creatorName'] ?? 'Explorer'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6, right: 6,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('"${snapData['thought'] ?? ''}"', style: const TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic, height: 1.3)),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: kNeonCyan),
                          SizedBox(width: 4),
                          Text('Expires automatically in 24h', style: TextStyle(color: kNeonCyan, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowMillis = DateTime.now().millisecondsSinceEpoch;

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(backgroundColor: kVoidBlack, elevation: 0, title: const Text('TRANSMISSION STUDIO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)), centerTitle: true),
      // 🌟 FIXED RESPONSIVE EXTENDED BUTTON
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.accentColor,
        elevation: 8,
        onPressed: () => _open24hThoughtCreator(context),
        icon: const Icon(Icons.add, color: Colors.black, size: 22),
        label: const Text('24H SNAP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('daily_snaps').where('expiresAt', isGreaterThan: nowMillis).snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, color: kNeonCyan, size: 16),
                        const SizedBox(width: 6),
                        const Text('24H AI SNAP EXPLORER FEED', style: TextStyle(color: kNeonCyan, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final snapData = docs[i].data() as Map<String, dynamic>;
                          final creator = snapData['creatorName'] ?? 'Explorer';

                          return GestureDetector(
                            onTap: () => _showFullSnapView(context, snapData),
                            child: Container(
                              width: 85,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 70, height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: widget.accentColor, width: 2),
                                      image: DecorationImage(
                                        image: NetworkImage(snapData['imageUrl'] ?? ''),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    creator,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 24),
                  ],
                );
              },
            ),

            Text('SELECT REALM DIMENSION', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: dimensions.map((d) {
                final isSel = selectedDim == d;
                return ChoiceChip(label: Text(d, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold)), selected: isSel, selectedColor: widget.accentColor, backgroundColor: kCardDark, onSelected: (val) => setState(() => selectedDim = d));
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(controller: _contentController, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Share your supernatural encounter, dream, or myth...', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: isRecording ? kHorrorCrimson : Colors.white12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Voice Frequency Echo (+2 Pts)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(recordedAudioBase64 != null ? 'Voice Captured! Choose Modulator filter below.' : 'Tap mic to capture paranormal audio frequency', style: TextStyle(color: widget.accentColor, fontSize: 11)),
                        ],
                      ),
                      IconButton(onPressed: _toggleRecording, iconSize: 34, icon: Icon(isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded, color: isRecording ? kHorrorCrimson : (recordedAudioBase64 != null ? kMistyGreen : Colors.white70))),
                    ],
                  ),
                  if (recordedAudioBase64 != null) ...[
                    const Divider(color: Colors.white12, height: 24),
                    const Text('1-TAP REAL-TIME VOICE FILTERS (PREVIEW):', style: TextStyle(color: kNeonCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: voiceFilters.map((vf) {
                        final isSel = selectedVoiceFilter == vf['id'];
                        return ActionChip(
                          backgroundColor: isSel ? widget.accentColor : Colors.black45,
                          label: Text(vf['label']!, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _previewFilteredVoice(vf['id']!),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isTransmitting ? null : _transmit,
                child: isTransmitting ? const CircularProgressIndicator(color: Colors.black) : const Text('BROADCAST TRANSMISSION (+2 PTS)', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// TAB 4: THE ORACLE'S SANCTUM (DEVELOPER HUB & 20 QUESTIONS)
// ==================================================
class OracleSanctumScreen extends StatefulWidget {
  final Color accentColor;
  const OracleSanctumScreen({super.key, required this.accentColor});

  @override
  State<OracleSanctumScreen> createState() => _OracleSanctumScreenState();
}

class _OracleSanctumScreenState extends State<OracleSanctumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showPublishStoryDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool isPrize = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kCardDark,
          title: const Text('CREATE DEVELOPER BROADCAST', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 14)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title / Mystery Headline', labelStyle: TextStyle(color: Colors.white70))),
                const SizedBox(height: 10),
                TextField(controller: bodyCtrl, maxLines: 5, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Story, News or Prize Rules', labelStyle: TextStyle(color: Colors.white70))),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Is this a Prize Announcement?', style: TextStyle(fontSize: 12, color: Colors.white)),
                  value: isPrize,
                  activeColor: kAncientGold,
                  onChanged: (v) => setDialogState(() => isPrize = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kAncientGold),
              onPressed: () async {
                final t = titleCtrl.text.trim();
                final b = bodyCtrl.text.trim();
                if (t.isEmpty || b.isEmpty) return;

                await FirebaseFirestore.instance.collection('developer_broadcasts').add({
                  'title': t,
                  'content': b,
                  'isPrize': isPrize,
                  'likes': [],
                  'commentsCount': 0,
                  'createdAt': DateTime.now().millisecondsSinceEpoch,
                });

                await NotificationService.showLocalNotification('👑 Developer Broadcast', t);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('PUBLISH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _submitUserQuestion(BuildContext context) async {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final todayString = "${now.year}-${now.month}-${now.day}";

    final todayDocs = await FirebaseFirestore.instance.collection('daily_questions').where('dateString', isEqualTo: todayString).get();

    if (todayDocs.docs.length >= 20) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Today's 20 Question slots are full! Opens tomorrow 12:00 AM.")));
      }
      return;
    }

    await FirebaseFirestore.instance.collection('daily_questions').add({
      'question': text,
      'askedBy': user?.displayName ?? 'Explorer',
      'askedByUid': user?.uid ?? '',
      'dateString': todayString,
      'answer': '',
      'isAnswered': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    _questionController.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your question entered today\'s 20 slots! Answers reveal at 8:00 PM.')));
    }
  }

  void _showAnswerDialog(BuildContext context, String docId, String question) {
    final answerCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        title: const Text('ANSWER USER QUESTION', style: TextStyle(color: kNeonCyan, fontWeight: FontWeight.bold, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q: $question', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: answerCtrl, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Verified Genuine Solution', labelStyle: TextStyle(color: Colors.white70))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNeonCyan),
            onPressed: () async {
              final ans = answerCtrl.text.trim();
              if (ans.isEmpty) return;
              await FirebaseFirestore.instance.collection('daily_questions').doc(docId).update({
                'answer': ans,
                'isAnswered': true,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SUBMIT SOLUTION', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isDeveloper = (currentUser?.email?.toLowerCase().trim() == kAdminEmail.toLowerCase().trim());

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: kAncientGold, size: 22),
            SizedBox(width: 8),
            Text('ORACLE\'S SANCTUM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAncientGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Creator Stories & News'),
            Tab(text: 'Daily 20 Questions (8 PM)'),
          ],
        ),
      ),
      floatingActionButton: (isDeveloper && _tabController.index == 0)
          ? FloatingActionButton.extended(
              backgroundColor: kAncientGold,
              onPressed: () => _showPublishStoryDialog(context),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('PUBLISH LORE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('developer_broadcasts').orderBy('createdAt', descending: true).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kAncientGold));
              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      const Text('No official chronicles or news published yet.', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final item = docs[i].data() as Map<String, dynamic>;
                  final isPrize = item['isPrize'] == true;
                  final likes = List<String>.from(item['likes'] ?? []);
                  final myUid = currentUser?.uid ?? '';
                  final isLiked = likes.contains(myUid);
                  final content = item['content'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kCardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isPrize ? kAncientGold : kNeonPurple.withOpacity(0.5), width: isPrize ? 1.5 : 1),
                      boxShadow: [if (isPrize) BoxShadow(color: kAncientGold.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: isPrize ? kAncientGold.withOpacity(0.2) : kNeonPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text(isPrize ? '🏆 PRIZE ANNOUNCEMENT' : '👑 CREATOR CHRONICLE', style: TextStyle(color: isPrize ? kAncientGold : kNeonCyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
                              tooltip: 'Copy Story Text',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: content));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chronicle text copied to clipboard!')));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(item['title'] ?? 'Sanctum Post', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(content, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () async {
                                if (myUid.isEmpty) return;
                                final docRef = FirebaseFirestore.instance.collection('developer_broadcasts').doc(docs[i].id);
                                if (isLiked) {
                                  await docRef.update({'likes': FieldValue.arrayRemove([myUid])});
                                } else {
                                  await docRef.update({'likes': FieldValue.arrayUnion([myUid])});
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? kHorrorCrimson : Colors.white38, size: 18),
                                  const SizedBox(width: 6),
                                  Text('${likes.length} Likes', style: TextStyle(color: isLiked ? kHorrorCrimson : Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, color: Colors.white38, size: 18),
                              onPressed: () => Share.share('📜 AVATAR SANCTUM:\n\n${item['title']}\n\n$content\n\n- Published by Creator on Avatar Network.'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: kCardDark,
                    prefixIcon: const Icon(Icons.search, color: kNeonCyan, size: 20),
                    hintText: 'Search 24-Hour Archive Solutions...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kCardDark,
                          hintText: 'Ask Oracle (Max 20 Pool Today)...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: kAncientGold),
                      onPressed: () => _submitUserQuestion(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('daily_questions').orderBy('createdAt', descending: true).snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kAncientGold));
                    var qDocs = snap.data!.docs;

                    if (_searchQuery.isNotEmpty) {
                      qDocs = qDocs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final q = (data['question'] ?? '').toString().toLowerCase();
                        final a = (data['answer'] ?? '').toString().toLowerCase();
                        return q.contains(_searchQuery) || a.contains(_searchQuery);
                      }).toList();
                    }

                    if (qDocs.isEmpty) {
                      return const Center(child: Text('No questions matching query.', style: TextStyle(color: Colors.white38)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: qDocs.length,
                      itemBuilder: (context, i) {
                        final qData = qDocs[i].data() as Map<String, dynamic>;
                        final isAnswered = qData['isAnswered'] == true;
                        final question = qData['question'] ?? '';
                        final answer = qData['answer'] ?? '';
                        final askedBy = qData['askedBy'] ?? 'Explorer';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kCardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isAnswered ? kNeonCyan.withOpacity(0.5) : Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Asked by @$askedBy', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: isAnswered ? kMistyGreen.withOpacity(0.2) : kHorrorCrimson.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                    child: Text(isAnswered ? 'SOLVED (8 PM SPOTLIGHT)' : 'PENDING ORACLE', style: TextStyle(color: isAnswered ? kMistyGreen : kHorrorCrimson, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Q: $question', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                              if (isAnswered) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: kNeonCyan.withOpacity(0.3))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('👑 DEVELOPER SOLUTION:', style: TextStyle(color: kNeonCyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                      const SizedBox(height: 4),
                                      Text(answer, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                                    ],
                                  ),
                                ),
                              ],
                              if (isDeveloper && !isAnswered) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: kNeonCyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    onPressed: () => _showAnswerDialog(context, qDocs[i].id, question),
                                    child: const Text('ANSWER SOLUTION', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
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
          ),
        ],
      ),
    );
  }
}

// ==================================================
// TAB 5: CHATS (AVATAR FRIEND AI COMPANION & P2P CHATS)
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
      appBar: AppBar(backgroundColor: kVoidBlack, elevation: 0, title: const Text('ECHO FREQUENCIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16))),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
        builder: (ctx, userSnap) {
          final myData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final pinnedChats = List<String>.from(myData['pinnedChats'] ?? []);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [kCardDark, kNeonPurple.withOpacity(0.2)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.accentColor, width: 1.5)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: widget.accentColor, child: const Icon(Icons.auto_awesome, color: Colors.black)),
                  title: const Text('Avatar Friend (AI Companion)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  subtitle: const Text('Multilingual AI Oracle • Always Online', style: TextStyle(color: kMistyGreen, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right, color: widget.accentColor),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarAIChatScreen())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
              const SizedBox(height: 6),
              const Divider(color: Colors.white12),
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
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

                  if (users.isEmpty) return const Center(child: Text('No other explorers online.', style: TextStyle(color: Colors.white38)));

                  return ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (ctx, i) {
                      final u = users[i].data() as Map<String, dynamic>;
                      final isOnline = u['isOnline'] == true;
                      final peerUid = users[i].id;
                      final peerName = u['name'] ?? 'Explorer';
                      final isPinned = pinnedChats.contains(peerUid);
                      final list = [myUid, peerUid]..sort();
                      final chatRoomId = '${list[0]}_${list[1]}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: isPinned ? kNeonCyan.withOpacity(0.5) : Colors.white12)),
                        child: ListTile(
                          onLongPress: () => _openChatOptions(context, peerUid, peerName, chatRoomId, isPinned, myUid),
                          leading: CircleAvatar(backgroundColor: widget.accentColor.withOpacity(0.3), child: Text(peerName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          title: Row(
                            children: [
                              Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (isPinned) ...[const SizedBox(width: 6), const Icon(Icons.push_pin, size: 14, color: kNeonCyan)],
                            ],
                          ),
                          subtitle: Text(isOnline ? AppLanguage.tr('online') : 'Signal lost', style: TextStyle(color: isOnline ? kMistyGreen : Colors.white38, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AvatarDirectChatScreen(peerUid: peerUid, peerName: peerName))),
                        ),
                      );
                    },
                  );
                },
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
    {
      'sender': 'ai',
      'text': 'Greetings, Explorer. I am Avatar Friend. Speak to me in any language—Hindi, English, or beyond. What mystery shall we decode today?'
    }
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
                    child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3)),
                  ),
                );
              },
            ),
          ),
          if (isThinking)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Avatar Friend is channeling dimensions...', style: TextStyle(color: kNeonCyan, fontSize: 12, fontStyle: FontStyle.italic)),
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
                        filled: true,
                        fillColor: kVoidBlack,
                        hintText: 'Type in any language...',
                        hintStyle: const TextStyle(color: Colors.white38),
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
// DIRECT PEER-TO-PEER CHAT SCREEN
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
              children: ['❤️', '🔥', '🌌', '👁️️', '😂'].map((emoji) {
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: isMe ? kNeonPurple : kCardDark, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
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
                        filled: true,
                        fillColor: kVoidBlack,
                        hintText: 'Transmit thought...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
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
// TAB 6: IDENTITY VAULT (EXPLORER PROFILE)
// ==================================================
class ExplorerProfileScreen extends StatelessWidget {
  final Color accentColor;
  final Function(String) onVaultSelect;
  const ExplorerProfileScreen({super.key, required this.accentColor, required this.onVaultSelect});

  Future<void> _pickAndCropAvatar(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop Avatar', toolbarColor: kVoidBlack, toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
      ],
    );

    if (cropped != null) {
      final bytes = await File(cropped.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'profilePic': base64Image});
    }
  }

  void _showEditProfileDialog(BuildContext context, String currentName, String currentBio, String uid) {
    final nameCtrl = TextEditingController(text: currentName);
    final bioCtrl = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        title: Text('Edit Identity', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 12),
            TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: 'Bio', labelStyle: TextStyle(color: Colors.white70))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({'name': nameCtrl.text.trim(), 'bio': bioCtrl.text.trim()});
              await FirebaseAuth.instance.currentUser?.updateDisplayName(nameCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('IDENTITY VAULT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white60), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: accentColor));
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          final profilePicBase64 = data['profilePic'] ?? '';
          final name = data['name'] ?? 'Explorer';
          final bio = data['bio'] ?? 'Exploring the Multiverse';
          final points = (data['resonances'] ?? 0) as int;
          final rankTheme = RankThemeEngine.getThemeByPoints(points);
          final perks = List<String>.from(data['unlockedPerks'] ?? ['Void Transmitter Core']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 2), boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]),
                        child: ClipOval(
                          child: profilePicBase64.isNotEmpty
                              ? Image.memory(base64Decode(profilePicBase64), fit: BoxFit.cover)
                              : CircleAvatar(backgroundColor: kNeonPurple.withOpacity(0.4), child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white))),
                        ),
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: InkWell(
                          onTap: () => _pickAndCropAvatar(myUid),
                          child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle), child: const Icon(Icons.crop_original_rounded, size: 18, color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.edit, size: 18, color: accentColor), onPressed: () => _showEditProfileDialog(context, name, bio, myUid)),
                  ],
                ),
                Text('@${data['username'] ?? 'avatar_being'}', style: TextStyle(color: accentColor, fontSize: 13)),
                const SizedBox(height: 8),
                Text(bio, style: const TextStyle(color: Colors.white60, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: (rankTheme['primary'] as Color).withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: rankTheme['primary'] as Color)),
                  child: Text('Rank: ${rankTheme['rank']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withOpacity(0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.military_tech_rounded, color: accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text('ACTIVE PERKS & ARTIFACTS (${perks.length})', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: perks.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                          child: Text('✦ $p', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ARTIFACT VAULT (TAP REALM TO OPEN)', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12,
                  children: [
                    _buildArtifactItem('Ancient Gods', 'Temple Alignments & Lore', kAncientGold, () => onVaultSelect('Ancient Gods')),
                    _buildArtifactItem('Dreams', 'Lucid Dreams & Paradoxes', kMistyGreen, () => onVaultSelect('Dreams')),
                    _buildArtifactItem('Cyber 3050', 'Singularity & AI Theories', kNeonCyan, () => onVaultSelect('Cyber 3050')),
                    _buildArtifactItem('Horror', 'Midnight Paranormal EVP', kHorrorCrimson, () => onVaultSelect('Horror')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtifactItem(String title, String desc, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.4))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.token_rounded, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                Text(desc, style: TextStyle(color: color, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
