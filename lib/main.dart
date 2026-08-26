import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// ==================================================
// NEXUS CORE PALETTE & THEME CONFIG
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
// AUTHENTICATION & GATEKEEPER
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
          'bio': 'Exploring Parallel Timelines',
          'dimension': 'Ancient Lore',
          'rank': 'Oracle',
          'resonances': 108,
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
        SnackBar(content: Text('Nexus Gateway Error: $e')),
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const Text(
                    'N E X U S',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white),
                  ),
                  const Text('The Multiverse Network', style: TextStyle(color: kNeonCyan, fontSize: 13, letterSpacing: 2)),
                  const SizedBox(height: 36),
                  if (isSignUp)
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: kCardDark,
                        hintText: 'Avatar Identity Name',
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
                      hintText: 'Frequency Mail',
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
                      hintText: 'Access Key',
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
                        elevation: 8,
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
                      isSignUp ? 'Already an Explorer? Access Dimension' : 'New Being? Generate Identity',
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
// NEXUS BOTTOM HOST & NAVIGATION
// ==================================================
class NexusNavigationHost extends StatefulWidget {
  const NexusNavigationHost({super.key});
  @override
  State<NexusNavigationHost> createState() => _NexusNavigationHostState();
}

class _NexusNavigationHostState extends State<NexusNavigationHost> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RealmsFeedScreen(),
    const TimeSlipRadarScreen(),
    const TransmissionStudioScreen(),
    const ChatsInboxScreen(),
    const ExplorerProfileScreen(),
  ];

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserOnline(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _setUserOnline(false);
    }
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
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kCardDark,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: kNeonCyan,
          unselectedItemColor: Colors.white38,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.blur_on_rounded), label: 'Realms'),
            BottomNavigationBarItem(icon: Icon(Icons.radar_rounded), label: 'Radar'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded, size: 30), label: 'Drop'),
            BottomNavigationBarItem(icon: Icon(Icons.bubble_chart_rounded), label: 'Echoes'),
            BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Identity'),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// TAB 1: REALMS FEED (HORROR, GODS, SCI-FI, DREAMS)
// ==================================================
class RealmsFeedScreen extends StatefulWidget {
  const RealmsFeedScreen({super.key});
  @override
  State<RealmsFeedScreen> createState() => _RealmsFeedScreenState();
}

class _RealmsFeedScreenState extends State<RealmsFeedScreen> {
  String selectedRealm = 'All';
  final List<Map<String, dynamic>> realms = [
    {'name': 'All', 'icon': Icons.all_inclusive_rounded, 'color': kNeonPurple},
    {'name': 'Horror', 'icon': Icons.dark_mode_rounded, 'color': kHorrorCrimson},
    {'name': 'Ancient Gods', 'icon': Icons.temple_hindu_rounded, 'color': kAncientGold},
    {'name': 'Cyber 3050', 'icon': Icons.memory_rounded, 'color': kNeonCyan},
    {'name': 'Dreams', 'icon': Icons.cloudy_snowing, 'color': kMistyGreen},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kNeonPurple, width: 1.5)),
              child: const Icon(Icons.hub_rounded, color: kNeonCyan, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('N E X U S', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Dimension Selector Carousel
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
                  onTap: () => setState(() => selectedRealm = r['name'] as String),
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
          // Transmission Cards Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedRealm == 'All'
                  ? FirebaseFirestore.instance.collection('transmissions').orderBy('createdAt', descending: true).snapshots()
                  : FirebaseFirestore.instance.collection('transmissions').where('dimension', isEqualTo: selectedRealm).snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Cosmic static interference.', style: TextStyle(color: Colors.white38)));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: kNeonCyan));
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.satellite_alt_rounded, size: 50, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        const Text('No transmissions in this dimension yet.', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    return TransmissionCard(docId: docId, data: data);
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

class TransmissionCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const TransmissionCard({super.key, required this.docId, required this.data});

  Color _getDimensionColor(String dim) {
    switch (dim) {
      case 'Horror': return kHorrorCrimson;
      case 'Ancient Gods': return kAncientGold;
      case 'Cyber 3050': return kNeonCyan;
      case 'Dreams': return kMistyGreen;
      default: return kNeonPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = data['dimension'] ?? 'Nexus';
    final dimColor = _getDimensionColor(dim);
    final witnesses = List<String>.from(data['witnesses'] ?? []);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hasWitnessed = witnesses.contains(currentUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dimColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: dimColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar & Realm Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: dimColor.withOpacity(0.2),
                    child: Text(
                      (data['creatorName'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(color: dimColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['creatorName'] ?? 'Explorer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(data['rank'] ?? 'Seeker', style: TextStyle(color: dimColor, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dimColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dimColor, width: 0.8),
                ),
                child: Text(dim, style: TextStyle(color: dimColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Content
          Text(
            data['content'] ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
          ),
          // Audio Echo Mock Waveform (Zero Storage Free Visualizer)
          if (data['hasAudio'] == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: dimColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Frequency: ${data['audioFilter'] ?? 'Ghost EVP Audio'} (0:14)',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  const Icon(Icons.graphic_eq_rounded, color: Colors.white38),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Actions: Witness & Decipher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  if (currentUid.isEmpty) return;
                  if (hasWitnessed) {
                    FirebaseFirestore.instance.collection('transmissions').doc(docId).update({
                      'witnesses': FieldValue.arrayRemove([currentUid]),
                    });
                  } else {
                    FirebaseFirestore.instance.collection('transmissions').doc(docId).update({
                      'witnesses': FieldValue.arrayUnion([currentUid]),
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      hasWitnessed ? Icons.visibility_rounded : Icons.visibility_outlined,
                      color: hasWitnessed ? dimColor : Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${witnesses.length} Witnessed',
                      style: TextStyle(color: hasWitnessed ? dimColor : Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.comment_outlined, color: Colors.white38, size: 18),
                  const SizedBox(width: 6),
                  Text('${data['decipherCount'] ?? 0} Deciphered', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white38, size: 18),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================================================
// TAB 2: TIME-SLIP RADAR (REAL-TIME ORBIT DISCOVERY)
// ==================================================
class TimeSlipRadarScreen extends StatelessWidget {
  const TimeSlipRadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('TIME-SLIP RADAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text('Scan nearby thought frequencies & parallel beings', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 30),
          // 2D Vector Animated Radar Target
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kNeonCyan.withOpacity(0.2), width: 1.5),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kNeonPurple.withOpacity(0.3), width: 1.5),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kAncientGold.withOpacity(0.4), width: 1.5),
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kNeonCyan,
                    boxShadow: [BoxShadow(color: kNeonCyan, blurRadius: 10, spreadRadius: 2)],
                  ),
                ),
                // Floating Entity Orbits
                Positioned(
                  top: 30,
                  left: 60,
                  child: _buildRadarPin(context, 'Cyborg_09', kNeonCyan, 'Futuristic Anomaly'),
                ),
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: _buildRadarPin(context, 'Vedic_Sage', kAncientGold, 'Ancient Alignment'),
                ),
                Positioned(
                  top: 70,
                  right: 50,
                  child: _buildRadarPin(context, 'Ghost_Hunter', kHorrorCrimson, 'EVP Audio 3AM'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Real-time Match Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kNeonPurple.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: kNeonCyan, size: 20),
                    SizedBox(width: 8),
                    Text('PARALLEL RESONANCE FOUND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNeonCyan)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'User @Shadow_01 is experiencing the same Lucid Dream frequency as you right now.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeonPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Establishing Anonymous Subconscious Link...')),
                      );
                    },
                    child: const Text('ENTER ANONYMOUS LINK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarPin(BuildContext context, String name, Color color, String vibe) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inspecting frequency of $name: $vibe')));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(Icons.person, size: 14, color: color),
          ),
          Text(name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==================================================
// TAB 3: TRANSMISSION STUDIO (DROP / POST MODAL)
// ==================================================
class TransmissionStudioScreen extends StatefulWidget {
  const TransmissionStudioScreen({super.key});
  @override
  State<TransmissionStudioScreen> createState() => _TransmissionStudioScreenState();
}

class _TransmissionStudioScreenState extends State<TransmissionStudioScreen> {
  final _contentController = TextEditingController();
  String selectedDim = 'Horror';
  String selectedFilter = 'EVP Ghost Static';
  bool hasVoiceNote = false;
  bool isTransmitting = false;

  final List<String> dimensions = ['Horror', 'Ancient Gods', 'Cyber 3050', 'Dreams'];
  final List<String> filters = ['EVP Ghost Static', 'Divine Echo', 'Cyber Synth', 'Foggy Dream'];

  Future<void> _transmit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your transmission.')),
      );
      return;
    }

    setState(() => isTransmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('transmissions').add({
        'uid': user?.uid ?? 'anon',
        'creatorName': user?.displayName ?? 'Oracle Explorer',
        'rank': 'Oracle',
        'dimension': selectedDim,
        'content': text,
        'hasAudio': hasVoiceNote,
        'audioFilter': selectedFilter,
        'witnesses': [],
        'decipherCount': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'serverTimestamp': FieldValue.serverTimestamp(),
      });

      _contentController.clear();
      setState(() => hasVoiceNote = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transmission Broadcasted to $selectedDim Realm!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signal Interrupted: $e')),
      );
    } finally {
      if (mounted) setState(() => isTransmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const Text('SELECT REALM DIMENSION', style: TextStyle(color: kNeonCyan, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: dimensions.map((d) {
                final isSel = selectedDim == d;
                return ChoiceChip(
                  label: Text(d, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: kNeonCyan,
                  backgroundColor: kCardDark,
                  onSelected: (val) => setState(() => selectedDim = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: kCardDark,
                hintText: 'Describe your dream, supernatural anomaly, or ancient prophecy...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            // Frequency Voice Studio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Voice Frequency Echo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Switch(
                        activeColor: kNeonPurple,
                        value: hasVoiceNote,
                        onChanged: (v) => setState(() => hasVoiceNote = v),
                      ),
                    ],
                  ),
                  if (hasVoiceNote) ...[
                    const Divider(color: Colors.white12),
                    DropdownButtonFormField<String>(
                      value: selectedFilter,
                      dropdownColor: kCardDark,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: filters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => selectedFilter = v!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: isTransmitting ? null : _transmit,
                icon: isTransmitting ? const SizedBox() : const Icon(Icons.send_rounded, color: Colors.white),
                label: isTransmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('BROADCAST TRANSMISSION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// TAB 4: CHATS & ECHOES INBOX
// ==================================================
class ChatsInboxScreen extends StatelessWidget {
  const ChatsInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: const Text('ECHO FREQUENCIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kNeonPurple));
          final users = snap.data!.docs.where((d) => d.id != myUid).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other explorers online.', style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: kNeonPurple.withOpacity(0.3),
                        child: Text(peerName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline ? kMistyGreen : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: kCardDark, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(isOnline ? 'Active on frequency' : 'Signal lost (Offline)', style: TextStyle(color: isOnline ? kMistyGreen : Colors.white38, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NexusDirectChatScreen(peerUid: peerUid, peerName: peerName),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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

  void _sendTextMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderId': myUid,
      'text': text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'serverTimestamp': FieldValue.serverTimestamp(),
    });

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kVoidBlack,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.peerUid).snapshots(),
          builder: (context, snap) {
            final uData = snap.data?.data() as Map<String, dynamic>?;
            final isPeerOnline = uData?['isOnline'] == true;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  isPeerOnline ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 12, color: isPeerOnline ? kMistyGreen : Colors.white38),
                ),
              ],
            );
          },
        ),
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
                          border: Border.all(color: isMe ? Colors.transparent : Colors.white12),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: kNeonCyan),
                    onPressed: _sendTextMessage,
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
// TAB 5: EXPLORER IDENTITY & ARTIFACT VAULT
// ==================================================
class ExplorerProfileScreen extends StatelessWidget {
  const ExplorerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
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
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kNeonPurple));
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kNeonCyan, width: 2),
                          boxShadow: [
                            BoxShadow(color: kNeonCyan.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: kNeonPurple.withOpacity(0.4),
                        child: Text(
                          (data['name'] ?? 'E')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(data['name'] ?? 'Explorer', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('@${data['username'] ?? 'nexus_being'}', style: const TextStyle(color: kNeonCyan, fontSize: 13)),
                const SizedBox(height: 8),
                Text(data['bio'] ?? 'Traversing Parallel Timelines', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 20),
                // Rank Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: kNeonPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNeonPurple),
                  ),
                  child: Text('Rank: ${data['rank'] ?? 'Oracle'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ARTIFACT VAULT (SAVED LORE)', style: TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 14),
                // Grid of 2D Lore Artifacts
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildArtifactItem('The Kedarnath Alignment', 'Ancient Lore', kAncientGold),
                    _buildArtifactItem('Lucid Tunnel Paradox', 'Dreams', kMistyGreen),
                    _buildArtifactItem('Cyber Singularity 3050', 'Cyber', kNeonCyan),
                    _buildArtifactItem('Midnight Static 3:15 AM', 'Horror', kHorrorCrimson),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtifactItem(String title, String realm, Color color) {
    return Container(
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(realm, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
