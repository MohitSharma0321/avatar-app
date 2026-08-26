import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

// ==================================================
// NEXUS PALETTE & CORE THEMES
// ==================================================
const Color kVoidBlack = Color(0xFF0A0714);
const Color kCardDark = Color(0xFF130E24);
const Color kNeonCyan = Color(0xFF00E5FF);
const Color kNeonPurple = Color(0xFFBD00FF);
const Color kAncientGold = Color(0xFFFFB300);
const Color kHorrorCrimson = Color(0xFFFF1744);
const Color kMistyGreen = Color(0xFF00E676);

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
  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXUS',
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
  }
}

// ==================================================
// CLOUDFLARE BACKED GEMINI AI ENGINE
// ==================================================
class NexusAIEngine {
  static const String _workerUrl = 'https://nexus-friend-api.projectkhurafat.workers.dev/';

  static Future<String> getAIResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'The cosmos echoes across frequencies.';
      }
    } catch (e) {
      debugPrint('Cloudflare Nexus AI Error: $e');
    }
    return 'Resonance signal weak. Try transmitting again.';
  }
}

// ==================================================
// DYNAMIC RANK THEME ENGINE
// ==================================================
class RankThemeEngine {
  static Map<String, dynamic> getThemeByPoints(int points) {
    if (points >= 1200) {
      return {
        'rank': 'Multiverse Prime',
        'primary': kAncientGold,
        'secondary': const Color(0xFFFFD54F),
        'glowColor': kAncientGold.withOpacity(0.35),
        'next': 'MAX LEVEL',
        'target': 1200,
        'progress': 1.0,
      };
    } else if (points >= 500) {
      return {
        'rank': 'Subconscious Oracle',
        'primary': kNeonCyan,
        'secondary': const Color(0xFF80D8FF),
        'glowColor': kNeonCyan.withOpacity(0.35),
        'next': 'Multiverse Prime (1200 Pts)',
        'target': 1200,
        'progress': (points - 500) / 700,
      };
    } else if (points >= 200) {
      return {
        'rank': 'Astral Decipherer',
        'primary': kNeonPurple,
        'secondary': const Color(0xFFE040FB),
        'glowColor': kNeonPurple.withOpacity(0.35),
        'next': 'Subconscious Oracle (500 Pts)',
        'target': 500,
        'progress': (points - 200) / 300,
      };
    } else if (points >= 50) {
      return {
        'rank': 'Dimensional Walker',
        'primary': kMistyGreen,
        'secondary': const Color(0xFFB9F6CA),
        'glowColor': kMistyGreen.withOpacity(0.35),
        'next': 'Astral Decipherer (200 Pts)',
        'target': 200,
        'progress': (points - 50) / 150,
      };
    } else {
      return {
        'rank': 'Seeker of the Void',
        'primary': Colors.white70,
        'secondary': Colors.white38,
        'glowColor': Colors.white10,
        'next': 'Dimensional Walker (50 Pts)',
        'target': 50,
        'progress': points / 50,
      };
    }
  }
}

// ==================================================
// AUTHENTICATION GATEWAY
// ==================================================
class AuthGatekeeper extends StatelessWidget {
  const AuthGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: kNeonPurple)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const NexusNavigationHost();
        }
        return const NexusLoginScreen();
      },
    );
  }
}

class NexusLoginScreen extends StatefulWidget {
  const NexusLoginScreen({super.key});
  @override
  State<NexusLoginScreen> createState() => _NexusLoginScreenState();
}

class _NexusLoginScreenState extends State<NexusLoginScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all frequency fields.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await cred.user?.updateDisplayName(name);
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': name,
          'username': name.toLowerCase().replaceAll(' ', '_'),
          'bio': 'Exploring the Multiverse in NEXUS',
          'profilePic': '',
          'rank': 'Seeker of the Void',
          'resonances': 0,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gateway Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF280B4D), kVoidBlack],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: kNeonPurple.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                      ],
                      border: Border.all(color: kNeonCyan, width: 2),
                    ),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('N E X U S', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white)),
                  const Text('The Multiverse Network', style: TextStyle(color: kNeonCyan, fontSize: 13, letterSpacing: 2)),
                  const SizedBox(height: 36),
                  if (isSignUp)
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: kCardDark,
                        hintText: 'Avatar Name',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.person_outline, color: kNeonPurple),
                      ),
                    ),
                  if (isSignUp) const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kCardDark,
                      hintText: 'Email Frequency',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.alternate_email, color: kNeonPurple),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kCardDark,
                      hintText: 'Passkey',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.lock_outline, color: kNeonPurple),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeonPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isLoading ? null : _handleAuth,
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isSignUp ? 'INITIALIZE TRANSMITTER' : 'ENTER DIMENSION', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => isSignUp = !isSignUp),
                    child: Text(
                      isSignUp ? 'Already an Explorer? Access' : 'New Being? Create Identity',
                      style: const TextStyle(color: kNeonCyan),
                    ),
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
// NOTIFICATIONS & ACHIEVEMENTS PANEL
// ==================================================
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('TRANSMISSIONS & RANKS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
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
                  decoration: BoxDecoration(
                    color: kCardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (rankInfo['primary'] as Color).withOpacity(0.5)),
                  ),
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
                        child: LinearProgressIndicator(
                          value: (rankInfo['progress'] as double).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(rankInfo['primary'] as Color),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Next Goal: ${rankInfo['next']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('LORE ACHIEVEMENTS (REWARD TIERS)', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _buildAchievementItem('1. Seeker of the Void', 'Initialize neural transmitter in the multiverse.', points >= 0, Icons.explore_outlined, Colors.white70),
                _buildAchievementItem('2. Dimensional Walker', 'Broadcast verified mystery transmissions into realms.', points >= 50, Icons.wifi_tethering_rounded, kMistyGreen),
                _buildAchievementItem('3. Astral Decipherer', 'Decipher & analyze parallel dimension entries.', points >= 200, Icons.fingerprint_rounded, kNeonPurple),
                _buildAchievementItem('4. Subconscious Oracle', 'Establish anonymous links via Time-Slip Radar.', points >= 500, Icons.remove_red_eye_rounded, kNeonCyan),
                _buildAchievementItem('5. Multiverse Prime', 'Grandmaster: Accumulate 1200+ resonance points.', points >= 1200, Icons.military_tech_rounded, kAncientGold),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementItem(String title, String desc, bool unlocked, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? color.withOpacity(0.5) : Colors.white10),
      ),
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
class NexusNavigationHost extends StatefulWidget {
  const NexusNavigationHost({super.key});

  @override
  State<NexusNavigationHost> createState() => _NexusNavigationHostState();
}

class _NexusNavigationHostState extends State<NexusNavigationHost> with WidgetsBindingObserver {
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

        final screens = [
          RealmsFeedScreen(
            selectedRealm: _selectedRealm,
            accentColor: activeColor,
            onRealmChange: (r) => setState(() => _selectedRealm = r),
          ),
          TimeSlipRadarScreen(accentColor: activeColor),
          TransmissionStudioScreen(
            accentColor: activeColor,
            onPostSuccess: () => setState(() => _currentIndex = 0),
          ),
          ChatsInboxScreen(accentColor: activeColor),
          ExplorerProfileScreen(
            accentColor: activeColor,
            onVaultSelect: (realm) => switchToRealm(realm),
          ),
        ];

        return Scaffold(
          backgroundColor: kVoidBlack,
          body: screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: kCardDark,
              border: Border(top: BorderSide(color: activeColor.withOpacity(0.2))),
              boxShadow: [
                BoxShadow(color: (rankTheme['glowColor'] as Color), blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) => setState(() => _currentIndex = idx),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: activeColor,
              unselectedItemColor: Colors.white38,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.blur_on_rounded), label: 'Realms'),
                BottomNavigationBarItem(icon: Icon(Icons.radar_rounded), label: 'Radar'),
                BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded, size: 28), label: 'Drop'),
                BottomNavigationBarItem(icon: Icon(Icons.bubble_chart_rounded), label: 'Echoes'),
                BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Identity'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================================================
// TAB 1: REALMS FEED SCREEN
// ==================================================
class RealmsFeedScreen extends StatelessWidget {
  final String selectedRealm;
  final Color accentColor;
  final Function(String) onRealmChange;

  const RealmsFeedScreen({
    super.key,
    required this.selectedRealm,
    required this.accentColor,
    required this.onRealmChange,
  });

  final List<Map<String, dynamic>> realms = const [
    {'name': 'All', 'icon': Icons.all_inclusive_rounded, 'color': kNeonPurple},
    {'name': 'Horror', 'icon': Icons.dark_mode_rounded, 'color': kHorrorCrimson},
    {'name': 'Ancient Gods', 'icon': Icons.temple_hindu_rounded, 'color': kAncientGold},
    {'name': 'Cyber 3050', 'icon': Icons.memory_rounded, 'color': kNeonCyan},
    {'name': 'Dreams', 'icon': Icons.cloudy_snowing, 'color': kMistyGreen},
  ];

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
            const Text('N E X U S', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 94,
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? (r['color'] as Color) : Colors.white12,
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(r['icon'] as IconData, color: r['color'] as Color, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          r['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : Colors.white60,
                          ),
                        ),
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
// TRANSMISSION CARD (REAL VOICE ECHO MODULATOR)
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

  double _getPitchByDimension(String dim) {
    switch (dim) {
      case 'Horror': return 0.65;
      case 'Cyber 3050': return 1.45;
      case 'Ancient Gods': return 0.75;
      case 'Dreams': return 0.85;
      default: return 1.0;
    }
  }

  Future<void> _playModulatedAudio(String base64Audio, String dimension) async {
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

      await _audioPlayer.setPlaybackRate(_getPitchByDimension(dimension));
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

  void _showDeleteDialog(BuildContext context, int createdAt) {
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
                title: const Text('Purge Transmission (Within 24 Hours)', style: TextStyle(color: kHorrorCrimson, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).delete();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
        ),
        child: SizedBox(
          height: 420,
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
                  stream: FirebaseFirestore.instance
                      .collection('transmissions')
                      .doc(widget.docId)
                      .collection('deciphers')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return Center(child: CircularProgressIndicator(color: dimColor));
                    final comments = snap.data!.docs;

                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('No deciphers yet. Be the first to decode this frequency.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      );
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
                        hintText: 'Add decipher thought...',
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

                      await FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).collection('deciphers').add({
                        'uid': currentUid,
                        'userName': currentName,
                        'text': text,
                        'createdAt': DateTime.now().millisecondsSinceEpoch,
                      });

                      await FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).update({
                        'decipherCount': FieldValue.increment(1),
                      });

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

  void _shareTransmission(String content, String dimension, String creator) {
    Share.share(
      '🌌 NEXUS TRANSMISSION [$dimension Realm]\n\n"$content"\n\n- Transmitted by @$creator on NEXUS Multiverse Network.',
      subject: 'NEXUS Transmission',
    );
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.data['dimension'] ?? 'Nexus';
    final dimColor = _getDimensionColor(dim);
    final witnesses = List<String>.from(widget.data['witnesses'] ?? []);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasWitnessed = witnesses.contains(currentUid);
    final isCreator = (widget.data['uid'] == currentUid);
    final createdAt = widget.data['createdAt'] ?? 0;
    final content = widget.data['content'] ?? '';
    final creatorName = widget.data['creatorName'] ?? 'Explorer';
    final audioBase64 = widget.data['audioBase64'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dimColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: dimColor.withOpacity(0.2),
                    child: Text(
                      creatorName[0].toUpperCase(),
                      style: TextStyle(color: dimColor, fontWeight: FontWeight.bold),
                    ),
                  ),
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
                    decoration: BoxDecoration(
                      color: dimColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dimColor, width: 0.8),
                    ),
                    child: Text(dim, style: TextStyle(color: dimColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  if (isCreator)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
                      onPressed: () => _showDeleteDialog(context, createdAt),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (content.isNotEmpty)
            Text(content, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
          if (widget.data['hasAudio'] == true && audioBase64.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _playModulatedAudio(audioBase64, dim),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isPlaying ? dimColor : Colors.white12, width: isPlaying ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                      color: dimColor,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPlaying ? 'Resonating $dim Voice...' : 'Frequency: Modulated $dim Echo',
                        style: TextStyle(fontSize: 12, color: isPlaying ? dimColor : Colors.white70, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                    Icon(Icons.graphic_eq_rounded, color: isPlaying ? dimColor : Colors.white38),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  if (currentUid.isEmpty) return;
                  if (hasWitnessed) {
                    FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).update({
                      'witnesses': FieldValue.arrayRemove([currentUid]),
                    });
                  } else {
                    FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).update({
                      'witnesses': FieldValue.arrayUnion([currentUid]),
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(hasWitnessed ? Icons.visibility_rounded : Icons.visibility_outlined, color: hasWitnessed ? dimColor : Colors.white38, size: 18),
                    const SizedBox(width: 6),
                    Text('${witnesses.length} Witnessed', style: TextStyle(color: hasWitnessed ? dimColor : Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openDecipherSheet(context, dimColor),
                child: Row(
                  children: [
                    const Icon(Icons.comment_outlined, color: Colors.white38, size: 18),
                    const SizedBox(width: 6),
                    Text('${widget.data['decipherCount'] ?? 0} Deciphered', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white38, size: 18),
                onPressed: () => _shareTransmission(content, dim, creatorName),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================================================
// TAB 2: TIME-SLIP RADAR
// ==================================================
class TimeSlipRadarScreen extends StatelessWidget {
  final Color accentColor;
  const TimeSlipRadarScreen({super.key, required this.accentColor});

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
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: accentColor));
            }
            final allDocs = snap.data?.docs ?? [];
            final otherUsers = allDocs.where((d) => d.id != myUid).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  const Text('Live thought frequencies in real-time orbit', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 270,
                            height: 270,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor.withOpacity(0.25), width: 1.5)),
                          ),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kNeonPurple.withOpacity(0.35), width: 1.5)),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kAncientGold.withOpacity(0.3), width: 1)),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                              boxShadow: [BoxShadow(color: accentColor, blurRadius: 12, spreadRadius: 3)],
                            ),
                          ),
                          if (otherUsers.isNotEmpty)
                            for (int i = 0; i < otherUsers.length && i < 3; i++)
                              _buildOrbitNode(context, otherUsers[i], i)
                          else ...[
                            _buildStaticNode(const Offset(-70, -75), 'Void_Seeker', accentColor),
                            _buildStaticNode(const Offset(75, 45), 'Ancient_Seer', kAncientGold),
                            _buildStaticNode(const Offset(-45, 65), 'Shadow_01', kHorrorCrimson),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kCardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: accentColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              otherUsers.isNotEmpty
                                  ? 'SYNCHRONIZED: @${(otherUsers.first.data() as Map<String, dynamic>)['username'] ?? 'Explorer'}'
                                  : 'PARALLEL RESONANCE SCANNING',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          otherUsers.isNotEmpty
                              ? '${(otherUsers.first.data() as Map<String, dynamic>)['name'] ?? 'Explorer'} is currently tuned to the frequency.'
                              : 'Tuning into subconscious wave patterns across dimensions...',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (otherUsers.isNotEmpty) {
                                final firstData = otherUsers.first.data() as Map<String, dynamic>;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NexusDirectChatScreen(
                                      peerUid: otherUsers.first.id,
                                      peerName: firstData['name'] ?? 'Explorer',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('ENTER ANONYMOUS LINK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrbitNode(BuildContext context, QueryDocumentSnapshot userDoc, int index) {
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? 'Explorer';
    final offsets = [
      const Offset(-70, -75),
      const Offset(75, 45),
      const Offset(-45, 65),
    ];

    return Transform.translate(
      offset: offsets[index % offsets.length],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NexusDirectChatScreen(peerUid: userDoc.id, peerName: name)),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonPurple.withOpacity(0.3),
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
            Text(name, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticNode(Offset offset, String label, Color color) {
    return Transform.translate(
      offset: offset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2), border: Border.all(color: color, width: 1.5)),
            child: Icon(Icons.blur_on_rounded, size: 14, color: color),
          ),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==================================================
// TAB 3: TRANSMISSION STUDIO SCREEN
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
  String? recordedAudioPath;
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
        setState(() {
          recordedAudioPath = path;
          recordedAudioBase64 = base64Encode(bytes);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice Frequency Captured! Tuned to $selectedDim Realm.')),
          );
        }
      }
    } else {
      final permission = await Permission.microphone.request();
      if (permission.isGranted) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
        setState(() {
          isRecording = true;
          recordedAudioPath = null;
          recordedAudioBase64 = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required.')),
          );
        }
      }
    }
  }

  Future<void> _transmit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty && recordedAudioBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a thought or record your voice frequency.')),
      );
      return;
    }

    setState(() => isTransmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('transmissions').add({
        'uid': user?.uid ?? 'anon',
        'creatorName': user?.displayName ?? 'Explorer',
        'rank': 'Seeker',
        'dimension': selectedDim,
        'content': text,
        'hasAudio': recordedAudioBase64 != null,
        'audioBase64': recordedAudioBase64 ?? '',
        'witnesses': [],
        'decipherCount': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (user?.uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'resonances': FieldValue.increment(10),
        });
      }

      _contentController.clear();
      setState(() {
        recordedAudioPath = null;
        recordedAudioBase64 = null;
      });
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
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('TRANSMISSION STUDIO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT REALM DIMENSION', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: dimensions.map((d) {
                final isSel = selectedDim == d;
                return ChoiceChip(
                  label: Text(d, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: widget.accentColor,
                  backgroundColor: kCardDark,
                  onSelected: (val) => setState(() => selectedDim = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: kCardDark,
                hintText: 'Share your supernatural encounter, dream, or myth...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isRecording ? kHorrorCrimson : Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Voice Frequency Echo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Auto-modulates into $selectedDim Voice', style: TextStyle(color: widget.accentColor, fontSize: 11)),
                        ],
                      ),
                      IconButton(
                        onPressed: _toggleRecording,
                        iconSize: 34,
                        icon: Icon(
                          isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                          color: isRecording ? kHorrorCrimson : (recordedAudioBase64 != null ? kMistyGreen : Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  if (isRecording) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fiber_manual_record, color: kHorrorCrimson, size: 14),
                        SizedBox(width: 6),
                        Text('Recording Frequency... Tap stop when done.', style: TextStyle(color: kHorrorCrimson, fontSize: 12)),
                      ],
                    ),
                  ] else if (recordedAudioBase64 != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: kMistyGreen, size: 16),
                        const SizedBox(width: 6),
                        Text('Voice recorded & tuned to $selectedDim!', style: const TextStyle(color: kMistyGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: isTransmitting ? null : _transmit,
                child: isTransmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('BROADCAST TRANSMISSION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// TAB 4: CHATS (NEXUS FRIEND AI COMPANION PINNED)
// ==================================================
class ChatsInboxScreen extends StatelessWidget {
  final Color accentColor;
  const ChatsInboxScreen({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('ECHO FREQUENCIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kCardDark, kNeonPurple.withOpacity(0.2)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: accentColor,
                child: const Icon(Icons.auto_awesome, color: Colors.black),
              ),
              title: const Text('Nexus Friend (AI Companion)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              subtitle: const Text('Multilingual AI Oracle • Always Online', style: TextStyle(color: kMistyGreen, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: accentColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NexusAIChatScreen()),
                );
              },
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 6),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator(color: accentColor));
              final users = snap.data!.docs.where((d) => d.id != myUid).toList();

              if (users.isEmpty) {
                return const Center(child: Text('No other explorers online.', style: TextStyle(color: Colors.white38)));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (ctx, i) {
                  final u = users[i].data() as Map<String, dynamic>;
                  final isOnline = u['isOnline'] == true;
                  final peerUid = users[i].id;
                  final peerName = u['name'] ?? 'Explorer';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: kCardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accentColor.withOpacity(0.3),
                        child: Text(peerName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(isOnline ? 'Active on frequency' : 'Signal lost', style: TextStyle(color: isOnline ? kMistyGreen : Colors.white38, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NexusDirectChatScreen(peerUid: peerUid, peerName: peerName)),
                        );
                      },
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
}

// ==================================================
// MULTILINGUAL AI CHAT SCREEN (NEXUS FRIEND)
// ==================================================
class NexusAIChatScreen extends StatefulWidget {
  const NexusAIChatScreen({super.key});

  @override
  State<NexusAIChatScreen> createState() => _NexusAIChatScreenState();
}

class _NexusAIChatScreenState extends State<NexusAIChatScreen> {
  final _msgController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Greetings, Explorer. I am Nexus Friend. Speak to me in any language—Hindi, English, or beyond. What mystery shall we decode today?'
    }
  ];
  bool isThinking = false;

  void _sendToAI() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'me', 'text': text});
      isThinking = true;
    });
    _msgController.clear();

    final aiReply = await NexusAIEngine.getAIResponse(text);

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': aiReply});
        isThinking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        title: const Row(
          children: [
            CircleAvatar(radius: 14, backgroundColor: kNeonCyan, child: Icon(Icons.auto_awesome, size: 14, color: Colors.black)),
            SizedBox(width: 10),
            Text('Nexus Friend (AI)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
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
              child: Text('Nexus Friend is channeling dimensions...', style: TextStyle(color: kNeonCyan, fontSize: 12, fontStyle: FontStyle.italic)),
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
class NexusDirectChatScreen extends StatefulWidget {
  final String peerUid;
  final String peerName;
  const NexusDirectChatScreen({super.key, required this.peerUid, required this.peerName});

  @override
  State<NexusDirectChatScreen> createState() => _NexusDirectChatScreenState();
}

class _NexusDirectChatScreenState extends State<NexusDirectChatScreen> {
  final _msgController = TextEditingController();
  late final String chatRoomId;

  @override
  void initState() {
    super.initState();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final list = [myUid, widget.peerUid]..sort();
    chatRoomId = '${list[0]}_${list[1]}';
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': myUid,
      'text': text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kVoidBlack,
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        title: Text(widget.peerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kNeonCyan));
                final messages = snap.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == myUid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? kNeonPurple : kCardDark,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
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
// TAB 5: PROFILE & ARTIFACT VAULT
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
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: kVoidBlack,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
      ],
    );

    if (cropped != null) {
      final bytes = await File(cropped.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePic': base64Image,
      });
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
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
              });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white60),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 2),
                          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                        ),
                        child: ClipOval(
                          child: profilePicBase64.isNotEmpty
                              ? Image.memory(base64Decode(profilePicBase64), fit: BoxFit.cover)
                              : CircleAvatar(
                                  backgroundColor: kNeonPurple.withOpacity(0.4),
                                  child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () => _pickAndCropAvatar(myUid),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                            child: const Icon(Icons.crop_original_rounded, size: 18, color: Colors.black),
                          ),
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
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: accentColor),
                      onPressed: () => _showEditProfileDialog(context, name, bio, myUid),
                    ),
                  ],
                ),
                Text('@${data['username'] ?? 'nexus_being'}', style: TextStyle(color: accentColor, fontSize: 13)),
                const SizedBox(height: 8),
                Text(bio, style: const TextStyle(color: Colors.white60, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: (rankTheme['primary'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rankTheme['primary'] as Color),
                  ),
                  child: Text('Rank: ${rankTheme['rank']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ARTIFACT VAULT (TAP REALM TO OPEN)', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
