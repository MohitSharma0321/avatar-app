import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const Color kPrimaryNeon = Color(0xFF00C6FF);
const Color kAccentPink = Color(0xFFE03287);
const Color kDarkSurface = Color(0xFF141724);
const Color kLightBg = Color(0xFFF8F9FD);
const Color kTextDark = Color(0xFF1B1E28);
const Color kTextSubtle = Color(0xFF7D8494);

// ==================================================
// GLOBAL MUSIC SERVICE & LIVE CLOUDFLARE FETCHER
// ==================================================

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String artwork;
  final String duration;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    required this.artwork,
    this.duration = '',
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Track',
      artist: json['artist'] ?? 'Unknown Artist',
      url: json['url'] ?? '',
      artwork: json['artwork'] ?? '',
      duration: json['duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'url': url,
    'artwork': artwork,
    'duration': duration,
  };
}

class GlobalMusicService {
  static final GlobalMusicService instance = GlobalMusicService._internal();
  GlobalMusicService._internal();

  final AudioPlayer audioPlayer = AudioPlayer();
  final ValueNotifier<SongModel?> currentSongNotifier = ValueNotifier<SongModel?>(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(Duration.zero);

  void init() {
    audioPlayer.onPlayerStateChanged.listen((state) {
      isPlayingNotifier.value = (state == PlayerState.playing);
    });
    audioPlayer.onPositionChanged.listen((pos) {
      positionNotifier.value = pos;
    });
    audioPlayer.onDurationChanged.listen((dur) {
      durationNotifier.value = dur;
    });
  }

  Future<void> playSong(SongModel song) async {
    currentSongNotifier.value = song;
    await audioPlayer.stop();
    await audioPlayer.play(UrlSource(song.url));
  }

  Future<void> pauseSong() async {
    await audioPlayer.pause();
  }

  Future<void> resumeSong() async {
    await audioPlayer.resume();
  }

  Future<void> seek(Duration pos) async {
    await audioPlayer.seek(pos);
  }

  Future<void> stop() async {
    await audioPlayer.stop();
    currentSongNotifier.value = null;
  }
}

class MusicRepository {
  static const String workerBaseUrl = 'https://avatar-music-engine.projectkhurafat.workers.dev/';

  static Future<List<SongModel>> searchTracks(String query) async {
    final q = query.trim().isEmpty ? 'trending hindi' : query.trim();
    try {
      final res = await http.get(Uri.parse('$workerBaseUrl?q=${Uri.encodeComponent(q)}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['songs'] != null) {
          return (data['songs'] as List).map((i) => SongModel.fromJson(i)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}

// Background Mini Player
class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SongModel?>(
      valueListenable: GlobalMusicService.instance.currentSongNotifier,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();

        return Container(
          height: 60,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kDarkSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song.artwork,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 42, height: 42, color: Colors.white24, child: const Icon(Icons.music_note, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: GlobalMusicService.instance.isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    onPressed: () {
                      isPlaying ? GlobalMusicService.instance.pauseSong() : GlobalMusicService.instance.resumeSong();
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                onPressed: () => GlobalMusicService.instance.stop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// In-App Music Picker Modal
class MusicPickerModal extends StatefulWidget {
  const MusicPickerModal({Key? key}) : super(key: key);

  @override
  State<MusicPickerModal> createState() => _MusicPickerModalState();
}

class _MusicPickerModalState extends State<MusicPickerModal> {
  String searchQ = '';
  List<SongModel> songs = [];
  bool isLoading = true;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    _fetchSongs('trending hindi');
  }

  void _fetchSongs(String q) async {
    setState(() => isLoading = true);
    final results = await MusicRepository.searchTracks(q);
    if (mounted) {
      setState(() {
        songs = results;
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSongs(val);
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          const Text('Select Music Track', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kDarkSurface)),
          const SizedBox(height: 12),
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search songs or artists...',
              prefixIcon: const Icon(Icons.search, color: kTextSubtle),
              filled: true,
              fillColor: kLightBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryNeon))
                : songs.isEmpty
                    ? const Center(child: Text('No tracks found.', style: TextStyle(color: kTextSubtle)))
                    : ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, idx) {
                          final song = songs[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.artwork,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: Colors.black12, child: const Icon(Icons.music_note)),
                              ),
                            ),
                            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextSubtle, fontSize: 12)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryNeon,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(context, song),
                              child: const Text('Attach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
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
// FCM BACKGROUND HANDLER & MAIN INIT
// ==================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data['type'] == 'call') {
    final callId = message.data['callId'] ?? '';
    final callerName = message.data['callerName'] ?? 'Incoming Call';
    final callerPhoto = message.data['callerPhoto'] ?? '';
    final callerId = message.data['callerId'] ?? '';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Avatar',
      avatar: callerPhoto.isNotEmpty ? callerPhoto : 'https://via.placeholder.com/150',
      handle: 'Voice Call',
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 35000,
      extra: <String, dynamic>{
        'callId': callId,
        'callerName': callerName,
        'callerPhoto': callerPhoto,
        'callerId': callerId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#141724',
        actionColor: '#00C6FF',
        incomingCallNotificationChannelName: 'Incoming Call',
        isShowCallID: true,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  GlobalMusicService.instance.init();

  runApp(const AvatarApp());
}

// ==================================================
// FCM NOTIFICATION SERVICE
// ==================================================

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _messageSubscription;

  static const String workerUrl =
      'https://avatar-call-notifier.projectkhurafat.workers.dev/';

  static Future<void> initialize() async {
    if (_initialized) {
      await saveCurrentToken();
      return;
    }
    _initialized = true;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'avatar_chat_channel',
      'Chat Notifications',
      description: 'Instant messages and alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final token = await _fcm.getToken();
    if (token != null) {
      await saveTokenToFirestore(token);
    }

    _tokenSubscription = _fcm.onTokenRefresh.listen((newToken) {
      saveTokenToFirestore(newToken);
    });

    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'avatar_chat_channel',
              'Chat Notifications',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
            ),
          ),
        );
      }
    });
  }

  static Future<void> saveCurrentToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await saveTokenToFirestore(token);
    } catch (_) {}
  }

  static Future<void> saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  static Future<void> triggerCallPush({
    required String calleeId,
    required String callId,
    required String callerName,
    required String callerPhoto,
    required String callerId,
  }) async {
    try {
      final calleeDoc = await FirebaseFirestore.instance.collection('users').doc(calleeId).get();
      final String? fcmToken = calleeDoc.data()?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) return;

      await http.post(
        Uri.parse(workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'call',
          'fcmToken': fcmToken,
          'callId': callId,
          'callerName': callerName,
          'callerPhoto': callerPhoto,
          'callerId': callerId,
        }),
      );
    } catch (_) {}
  }

  static Future<void> triggerChatPush({
    required String receiverUid,
    required String senderName,
    required String messageText,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(receiverUid).get();
      final String? fcmToken = doc.data()?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) return;

      await http.post(
        Uri.parse(workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'chat',
          'fcmToken': fcmToken,
          'title': senderName,
          'body': messageText,
        }),
      );
    } catch (_) {}
  }
}

// ==================================================
// WEBRTC SIGNALING SERVICE
// ==================================================

typedef StreamCallback = void Function(MediaStream stream);

class WebRtcSignalingService {
  final Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? currentCallId;
  StreamSubscription? callDocSubscription;
  StreamSubscription? candidateSubscription;

  final List<RTCIceCandidate> _iceCandidateQueue = [];
  bool _isRemoteDescriptionSet = false;

  Future<MediaStream> openAudioStream() async {
    await Permission.microphone.request();
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    return localStream!;
  }

  Future<String> createCall({
    required String callerId,
    required String calleeId,
    required String callerName,
    required String callerPhoto,
    required StreamCallback onRemoteStreamReceived,
    required VoidCallback onCallEnded,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final callDoc = firestore.collection('calls').doc();
    currentCallId = callDoc.id;
    _isRemoteDescriptionSet = false;
    _iceCandidateQueue.clear();

    peerConnection = await createPeerConnection(configuration);

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onRemoteStreamReceived(event.streams[0]);
      }
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callDoc.collection('callerCandidates').add(candidate.toMap());
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await callDoc.set({
      'callId': currentCallId,
      'callerId': callerId,
      'calleeId': calleeId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'offer': offer.toMap(),
      'status': 'calling',
      'createdAt': FieldValue.serverTimestamp(),
    });

    unawaited(
      NotificationService.triggerCallPush(
        calleeId: calleeId,
        callId: currentCallId!,
        callerName: callerName,
        callerPhoto: callerPhoto,
        callerId: callerId,
      ),
    );

    callDocSubscription = callDoc.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null) {
        if (data['status'] == 'ended') {
          onCallEnded();
        } else if (data['answer'] != null && !_isRemoteDescriptionSet) {
          var answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );
          await peerConnection?.setRemoteDescription(answer);
          _isRemoteDescriptionSet = true;
          _processIceCandidateQueue();
        }
      }
    });

    candidateSubscription = callDoc
        .collection('calleeCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data();
          if (data != null) {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            if (_isRemoteDescriptionSet) {
              peerConnection?.addCandidate(candidate);
            } else {
              _iceCandidateQueue.add(candidate);
            }
          }
        }
      }
    });

    return currentCallId!;
  }

  Future<void> answerCall({
    required String callId,
    required StreamCallback onRemoteStreamReceived,
    required VoidCallback onCallEnded,
  }) async {
    currentCallId = callId;
    _isRemoteDescriptionSet = false;
    _iceCandidateQueue.clear();

    final callDoc = FirebaseFirestore.instance.collection('calls').doc(callId);

    peerConnection = await createPeerConnection(configuration);

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onRemoteStreamReceived(event.streams[0]);
      }
    };

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callDoc.collection('calleeCandidates').add(candidate.toMap());
    };

    final callData = (await callDoc.get()).data();
    if (callData != null && callData['offer'] != null) {
      var offer = RTCSessionDescription(
        callData['offer']['sdp'],
        callData['offer']['type'],
      );
      await peerConnection?.setRemoteDescription(offer);
      _isRemoteDescriptionSet = true;
      _processIceCandidateQueue();

      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      await callDoc.update({
        'answer': answer.toMap(),
        'status': 'connected',
      });
    }

    callDocSubscription = callDoc.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['status'] == 'ended') {
        onCallEnded();
      }
    });

    candidateSubscription = callDoc
        .collection('callerCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data();
          if (data != null) {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            if (_isRemoteDescriptionSet) {
              peerConnection?.addCandidate(candidate);
            } else {
              _iceCandidateQueue.add(candidate);
            }
          }
        }
      }
    });
  }

  void _processIceCandidateQueue() {
    for (var candidate in _iceCandidateQueue) {
      peerConnection?.addCandidate(candidate);
    }
    _iceCandidateQueue.clear();
  }

  Future<void> hangUp() async {
    callDocSubscription?.cancel();
    candidateSubscription?.cancel();

    if (currentCallId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(currentCallId)
            .update({'status': 'ended'});
      } catch (_) {}
    }

    localStream?.getTracks().forEach((track) => track.stop());
    remoteStream?.getTracks().forEach((track) => track.stop());
    await peerConnection?.close();
    peerConnection = null;
    localStream = null;
    remoteStream = null;
    currentCallId = null;
    _isRemoteDescriptionSet = false;
    _iceCandidateQueue.clear();
  }
}

// ==================================================
// TOP-LEVEL HELPERS & CUSTOM WIDGETS
// ==================================================

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: kDarkSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

String getChatRoomId(String a, String b) {
  return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
}

void updateUserPresence(bool isOnline) {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

Future<void> ensureUserDoc(User user) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      final defaultUsername = 'user_${Random().nextInt(899999) + 100000}';
      await docRef.set({
        'uid': user.uid,
        'name': '',
        'username': defaultUsername,
        'bio': 'Hey there! I am on Avatar.',
        'photoBase64': '',
        'connections': [],
        'pinnedChats': [],
        'isPrivate': false,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      updateUserPresence(true);
    }
  } catch (_) {}
}

void showUserAvatarPreview(BuildContext context, {
  required String photoBase64,
  required String name,
  String? bio,
  String? username,
  String? targetUid,
}) {
  ImageProvider? provider;
  if (photoBase64.isNotEmpty) {
    try {
      final clean = photoBase64.replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '');
      provider = MemoryImage(base64Decode(clean));
    } catch (_) {}
  }

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: provider != null
                    ? Image(image: provider, width: 268, height: 268, fit: BoxFit.cover)
                    : Container(
                        width: 268,
                        height: 268,
                        color: kLightBg,
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : (username != null && username.isNotEmpty ? username[0].toUpperCase() : 'U'),
                            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: kDarkSurface),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Text(name.isNotEmpty ? name : (username != null ? '@$username' : 'User'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkSurface)),
              if (username != null && name.isNotEmpty)
                Text('@$username', style: const TextStyle(color: kTextSubtle, fontSize: 13)),
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(bio, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(color: kTextSubtle, fontSize: 13)),
              ],
              if (targetUid != null && targetUid.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDarkSurface,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserPublicProfileScreen(
                            targetUid: targetUid,
                            targetName: name,
                            targetUsername: username ?? 'user',
                            targetPhoto: photoBase64,
                            targetBio: bio ?? '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: const Text('View Full Profile & Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildUserAvatar({
  required BuildContext context,
  required String photoBase64,
  required String name,
  String? bio,
  String? username,
  String? targetUid,
  double radius = 24,
  bool enablePreview = true,
}) {
  ImageProvider? imageProvider;
  if (photoBase64.isNotEmpty) {
    try {
      final cleanData = photoBase64.replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '');
      imageProvider = MemoryImage(base64Decode(cleanData));
    } catch (_) {}
  }

  final avatarWidget = Container(
    padding: const EdgeInsets.all(2.5),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [kPrimaryNeon, kAccentPink],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : (username != null && username.isNotEmpty ? username[0].toUpperCase() : 'U'),
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.bold,
                color: kDarkSurface,
              ),
            )
          : null,
    ),
  );

  if (!enablePreview) return avatarWidget;

  return GestureDetector(
    onLongPress: () => showUserAvatarPreview(
      context,
      photoBase64: photoBase64,
      name: name,
      bio: bio,
      username: username,
      targetUid: targetUid,
    ),
    child: avatarWidget,
  );
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
      return data['reply'] ?? data['response'] ?? 'Koi response nahi mila.';
    } else {
      return 'Server error: ${response.statusCode}';
    }
  } catch (e) {
    return 'Connection error: Internet check karein.';
  }
}

// ==================================================
// APP MAIN OBSERVER
// ==================================================

class AvatarApp extends StatefulWidget {
  const AvatarApp({Key? key}) : super(key: key);

  @override
  State<AvatarApp> createState() => _AvatarAppState();
}

class _AvatarAppState extends State<AvatarApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    updateUserPresence(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateUserPresence(true);
    } else {
      updateUserPresence(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updateUserPresence(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Avatar',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: kLightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryNeon,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: kDarkSurface),
          titleTextStyle: TextStyle(
            color: kDarkSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
            body: Center(child: CircularProgressIndicator(color: kPrimaryNeon)),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          ensureUserDoc(snapshot.data!);
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
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kPrimaryNeon, kAccentPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryNeon.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.bolt, size: 60, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Avatar',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: kDarkSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Clean, Ultra-fast Voice & Mutual Connections.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: kTextSubtle, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 44),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [kPrimaryNeon, kAccentPink],
                    ),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                      );
                    },
                    child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('I already have an account', style: TextStyle(fontSize: 15, color: kDarkSurface, fontWeight: FontWeight.w600)),
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
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;
  String usernameError = '';

  Future<void> createAccount() async {
    FocusScope.of(context).unfocus();
    setState(() => usernameError = '');

    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please enter username, email and password.');
      return;
    }

    if (username.contains(' ') || username.length < 3) {
      _showMessage(context, 'Username must be at least 3 characters without spaces.');
      return;
    }

    if (password.length < 6) {
      _showMessage(context, 'Password must be at least 6 characters.');
      return;
    }

    setState(() => loading = true);

    try {
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (existingUser.docs.isNotEmpty) {
        setState(() {
          loading = false;
          usernameError = 'This username is already taken. Please choose another one.';
        });
        return;
      }

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(username);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': '',
          'username': username,
          'bio': 'Hey there! I am on Avatar.',
          'photoBase64': '',
          'connections': [],
          'pinnedChats': [],
          'isPrivate': false,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Pick a unique username', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kDarkSurface)),
              const SizedBox(height: 8),
              const Text('You can set your public display name anytime later in profile.', style: TextStyle(color: kTextSubtle, fontSize: 14)),
              const SizedBox(height: 28),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Unique Username (e.g. mohit_01)',
                  filled: true,
                  fillColor: kLightBg,
                  errorText: usernameError.isNotEmpty ? usernameError : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: kLightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: kLightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                    icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [kPrimaryNeon, kAccentPink]),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: loading ? null : createAccount,
                  child: loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
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
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, 'Please enter email and password.');
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await ensureUserDoc(credential.user!);
      }

      if (!mounted) return;
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
      _showMessage(context, 'Error: $e');
    }

    if (mounted) setState(() => loading = false);
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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kDarkSurface)),
              const SizedBox(height: 8),
              const Text('Enter your credentials to continue.', style: TextStyle(color: kTextSubtle, fontSize: 14)),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: kLightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: kLightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                    icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [kPrimaryNeon, kAccentPink]),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: loading ? null : login,
                  child: loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
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
// POST STUDIO (PHOTO EDITOR SCREEN)
// ==================================================

class PostEditStudioScreen extends StatefulWidget {
  final File initialImageFile;

  const PostEditStudioScreen({Key? key, required this.initialImageFile}) : super(key: key);

  @override
  State<PostEditStudioScreen> createState() => _PostEditStudioScreenState();
}

class _PostEditStudioScreenState extends State<PostEditStudioScreen> {
  late File currentImage;
  final TextEditingController captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  SongModel? selectedSong;
  int currentFilterIndex = 0;
  bool isPosting = false;

  final List<String> filterNames = ['Normal', 'Vivid', 'Warm', 'Mono', 'Vintage', 'Neon'];
  final List<List<double>> colorMatrices = [
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0], // Normal
    [1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1, 0], // Vivid
    [1.2, 0, 0, 0, 20, 0, 1.1, 0, 0, 10, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0], // Warm
    [0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0, 0, 0, 1, 0], // Mono
    [0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0], // Vintage
    [0.8, 0, 0, 0, 0, 0, 1.3, 0, 0, 10, 0, 0, 1.5, 0, 30, 0, 0, 0, 1, 0], // Neon
  ];

  @override
  void initState() {
    super.initState();
    currentImage = widget.initialImageFile;
  }

  Future<void> _cropImage() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: currentImage.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop & Ratio',
          toolbarColor: kDarkSurface,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: kPrimaryNeon,
        ),
      ],
    );
    if (cropped != null) {
      setState(() => currentImage = File(cropped.path));
    }
  }

  Future<void> _replaceImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() => currentImage = File(picked.path));
    }
  }

  Future<void> _pickMusic() async {
    final SongModel? song = await showModalBottomSheet<SongModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MusicPickerModal(),
    );
    if (song != null) {
      setState(() => selectedSong = song);
    }
  }

  Future<void> _publishPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isPosting = true);

    try {
      final bytes = await currentImage.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('feed_posts').add({
        'uid': user.uid,
        'creatorName': user.displayName ?? 'User',
        'type': 'post',
        'caption': captionController.text.trim(),
        'mediaData': imageBase64,
        'videoUrl': '',
        'attachedSong': selectedSong != null ? selectedSong!.toJson() : null,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage(context, 'Post published successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showMessage(context, 'Publish failed: $e');
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: isPosting ? null : _publishPost,
            child: isPosting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryNeon))
                : const Text('Share', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimaryNeon)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 380,
              color: Colors.black,
              child: Center(
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(colorMatrices[currentFilterIndex]),
                  child: Image.file(currentImage, fit: BoxFit.contain),
                ),
              ),
            ),
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: filterNames.length,
                itemBuilder: (ctx, idx) {
                  final isSelected = (currentFilterIndex == idx);
                  return GestureDetector(
                    onTap: () => setState(() => currentFilterIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? kDarkSurface : kLightBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? kPrimaryNeon : Colors.transparent, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          filterNames[idx],
                          style: TextStyle(
                            color: isSelected ? Colors.white : kDarkSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: kDarkSurface,
                    ),
                    onPressed: _cropImage,
                    icon: const Icon(Icons.crop_rotate_rounded, size: 16),
                    label: const Text('Crop'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: kDarkSurface,
                    ),
                    onPressed: _replaceImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Replace'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedSong != null ? kDarkSurface : kLightBg,
                      foregroundColor: selectedSong != null ? Colors.white : kDarkSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _pickMusic,
                    icon: Icon(Icons.music_note_rounded, size: 16, color: selectedSong != null ? kPrimaryNeon : kDarkSurface),
                    label: Text(selectedSong != null ? 'Music Added' : 'Add Music'),
                  ),
                ],
              ),
            ),
            if (selectedSong != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kLightBg, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack, size: 18, color: kPrimaryNeon),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${selectedSong!.title} • ${selectedSong!.artist}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    GestureDetector(
                      onTap: () => setState(() => selectedSong = null),
                      child: const Icon(Icons.close, size: 18, color: kTextSubtle),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  filled: true,
                  fillColor: kLightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
// REEL STUDIO (VIDEO EDITOR SCREEN)
// ==================================================

class ReelEditStudioScreen extends StatefulWidget {
  final File initialVideoFile;

  const ReelEditStudioScreen({Key? key, required this.initialVideoFile}) : super(key: key);

  @override
  State<ReelEditStudioScreen> createState() => _ReelEditStudioScreenState();
}

class _ReelEditStudioScreenState extends State<ReelEditStudioScreen> {
  late VideoPlayerController _videoController;
  late File currentVideo;
  final TextEditingController captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  SongModel? selectedSong;
  bool isUploading = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    currentVideo = widget.initialVideoFile;
    _initVideo();
  }

  void _initVideo() {
    _videoController = VideoPlayerController.file(currentVideo)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => isInitialized = true);
          _videoController.setLooping(true);
          _videoController.play();
        }
      });
  }

  Future<void> _replaceVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      await _videoController.dispose();
      setState(() {
        isInitialized = false;
        currentVideo = File(picked.path);
      });
      _initVideo();
    }
  }

  Future<void> _pickMusic() async {
    final SongModel? song = await showModalBottomSheet<SongModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MusicPickerModal(),
    );
    if (song != null) {
      setState(() => selectedSong = song);
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    const String cloudName = 'a6flqxr8';
    const String uploadPreset = 'avatar_preset';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');

    try {
      final req = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await req.send();
      if (streamed.statusCode == 200) {
        final res = await http.Response.fromStream(streamed);
        final data = jsonDecode(res.body);
        return data['secure_url'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _publishReel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isUploading = true);

    try {
      final videoUrl = await _uploadToCloudinary(currentVideo);
      if (videoUrl == null || videoUrl.isEmpty) {
        if (mounted) _showMessage(context, 'Video upload failed. Check internet.');
        setState(() => isUploading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('feed_posts').add({
        'uid': user.uid,
        'creatorName': user.displayName ?? 'User',
        'type': 'reel',
        'caption': captionController.text.trim(),
        'videoUrl': videoUrl,
        'mediaData': '',
        'attachedSong': selectedSong != null ? selectedSong!.toJson() : null,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage(context, 'Reel published successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showMessage(context, 'Publish error: $e');
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('New Reel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: isUploading ? null : _publishReel,
            child: isUploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryNeon))
                : const Text('Share', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimaryNeon)),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: kPrimaryNeon)),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        onPressed: _replaceVideo,
                        icon: const Icon(Icons.video_library_outlined, size: 16),
                        label: const Text('Replace'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedSong != null ? kPrimaryNeon : Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _pickMusic,
                        icon: const Icon(Icons.music_note_rounded, size: 16),
                        label: Text(selectedSong != null ? 'Sound Attached' : 'Add Sound'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a reel caption...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
// REELS & POSTS DUAL FEED SCREEN
// ==================================================

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int feedTab = 0; // 0 = Reels, 1 = Posts
  final ImagePicker _picker = ImagePicker();

  void _openShareModal(BuildContext context, Map<String, dynamic> postData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Share Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkSurface)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kPrimaryNeon, kAccentPink])),
                child: const Icon(Icons.history_toggle_off_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('Add to Avatar Story (24h)', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _showMessage(context, 'Added to your Avatar Story!');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.shade600),
                child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('Share to WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                final videoUrl = postData['videoUrl'] ?? '';
                Share.share('Watch this on Avatar App!\n${postData['caption'] ?? ''}\n$videoUrl');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _startCreationFlow() async {
    if (feedTab == 0) {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReelEditStudioScreen(initialVideoFile: File(picked.path))),
        );
      }
    } else {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostEditStudioScreen(initialImageFile: File(picked.path))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: feedTab == 0 ? Colors.black : kLightBg,
      appBar: AppBar(
        backgroundColor: feedTab == 0 ? Colors.black : Colors.white,
        titleSpacing: 0,
        title: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: feedTab == 0 ? Colors.white12 : kLightBg,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => feedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: feedTab == 0 ? kPrimaryNeon : Colors.transparent,
                  ),
                  child: Text('Reels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: feedTab == 0 ? Colors.white : (feedTab == 0 ? Colors.white70 : kTextDark))),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => feedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: feedTab == 1 ? kPrimaryNeon : Colors.transparent,
                  ),
                  child: Text('Posts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: feedTab == 1 ? Colors.white : (feedTab == 0 ? Colors.white70 : kTextDark))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _startCreationFlow,
            icon: Icon(Icons.add_box_outlined, color: feedTab == 0 ? Colors.white : kDarkSurface, size: 26),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feed_posts')
            .where('type', isEqualTo: feedTab == 0 ? 'reel' : 'post')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryNeon));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(feedTab == 0 ? Icons.movie_outlined : Icons.photo_library_outlined, size: 60, color: feedTab == 0 ? Colors.white38 : kTextSubtle),
                  const SizedBox(height: 12),
                  Text(feedTab == 0 ? 'No Reels uploaded yet.' : 'No Posts yet.', style: TextStyle(color: feedTab == 0 ? Colors.white70 : kDarkSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Tap + at top right to create.', style: TextStyle(color: feedTab == 0 ? Colors.white38 : kTextSubtle, fontSize: 13)),
                ],
              ),
            );
          }

          if (feedTab == 0) {
            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final List<dynamic> likes = data['likes'] ?? [];
                final isLiked = likes.contains(currentUid);
                final String videoUrl = data['videoUrl'] ?? '';
                final Map<String, dynamic>? songData = data['attachedSong'];

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black,
                      child: videoUrl.isNotEmpty
                          ? ReelVideoPlayerItem(videoUrl: videoUrl)
                          : const Center(child: Icon(Icons.play_circle_outline_rounded, size: 80, color: Colors.white38)),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 40,
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? Colors.redAccent : Colors.white, size: 30),
                            onPressed: () {
                              docs[index].reference.update({
                                'likes': isLiked ? FieldValue.arrayRemove([currentUid]) : FieldValue.arrayUnion([currentUid]),
                              });
                            },
                          ),
                          Text('${likes.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26),
                            onPressed: () {},
                          ),
                          const SizedBox(height: 16),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
                            onPressed: () => _openShareModal(context, data),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 30,
                      right: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${data['creatorName'] ?? 'user'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          if ((data['caption'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(data['caption'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                          if (songData != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.music_note, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text('${songData['title']} • ${songData['artist']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }

          // Posts Feed
          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String mediaBase64 = data['mediaData'] ?? '';
              final List<dynamic> likes = data['likes'] ?? [];
              final isLiked = likes.contains(currentUid);
              final Map<String, dynamic>? songData = data['attachedSong'];

              Widget postImage;
              if (mediaBase64.isNotEmpty) {
                try {
                  postImage = Image.memory(base64Decode(mediaBase64), fit: BoxFit.contain, width: double.infinity);
                } catch (_) {
                  postImage = Container(height: 250, color: Colors.grey.shade200, child: const Icon(Icons.broken_image));
                }
              } else {
                postImage = Container(height: 250, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.photo_outlined, size: 48, color: Colors.grey)));
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: kPrimaryNeon.withOpacity(0.2), child: Text(data['creatorName'] != null && data['creatorName'].isNotEmpty ? data['creatorName'][0].toUpperCase() : 'U')),
                      title: Text(data['creatorName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: songData != null ? Text('🎵 ${songData['title']}', style: const TextStyle(fontSize: 11, color: kPrimaryNeon)) : null,
                      trailing: IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () => _openShareModal(context, data)),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 450),
                        child: postImage,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? Colors.redAccent : kDarkSurface, size: 26),
                            onPressed: () {
                              docs[index].reference.update({
                                'likes': isLiked ? FieldValue.arrayRemove([currentUid]) : FieldValue.arrayUnion([currentUid]),
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text('${likes.length} likes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.share_outlined, size: 24),
                            onPressed: () => _openShareModal(context, data),
                          ),
                        ],
                      ),
                    ),
                    if ((data['caption'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        child: Text(data['caption'], style: const TextStyle(fontSize: 14)),
                      ),
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
// ROBUST FULL-SCREEN REEL VIDEO PLAYER ITEM
// ==================================================

class ReelVideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const ReelVideoPlayerItem({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<ReelVideoPlayerItem> createState() => _ReelVideoPlayerItemState();
}

class _ReelVideoPlayerItemState extends State<ReelVideoPlayerItem> {
  late VideoPlayerController _controller;
  bool isInitialized = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      if (mounted) {
        setState(() => isInitialized = true);
        _controller.setLooping(true);
        _controller.play();
      }
    } catch (_) {
      if (mounted) setState(() => hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const Center(child: Icon(Icons.error_outline_rounded, size: 50, color: Colors.white38));
    }
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryNeon, strokeWidth: 2));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

// ==================================================
// MUSIC HUB SCREEN (SOLO LISTENING & SEARCH)
// ==================================================

class MusicHubScreen extends StatefulWidget {
  const MusicHubScreen({Key? key}) : super(key: key);

  @override
  State<MusicHubScreen> createState() => _MusicHubScreenState();
}

class _MusicHubScreenState extends State<MusicHubScreen> {
  List<SongModel> songs = [];
  bool isLoading = true;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    _fetchTracks('trending hindi');
  }

  void _fetchTracks(String q) async {
    setState(() => isLoading = true);
    final results = await MusicRepository.searchTracks(q);
    if (mounted) {
      setState(() {
        songs = results;
        isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchTracks(val);
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Hub', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search any track or artist...',
                prefixIcon: const Icon(Icons.search, color: kTextSubtle),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryNeon))
                : songs.isEmpty
                    ? const Center(child: Text('No tracks found.', style: TextStyle(color: kTextSubtle)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: songs.length,
                        itemBuilder: (context, idx) {
                          final song = songs[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  song.artwork,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.black12, child: const Icon(Icons.music_note)),
                                ),
                              ),
                              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('${song.artist} • ${song.duration}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextSubtle, fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: kPrimaryNeon, size: 36),
                                onPressed: () => GlobalMusicService.instance.playSong(song),
                              ),
                            ),
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
// REWARDS SCREEN PLACEHOLDER
// ==================================================

class RewardsPlaceholderScreen extends StatelessWidget {
  const RewardsPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avatar Rewards', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.stars_rounded, size: 70, color: Colors.amber),
            SizedBox(height: 14),
            Text('Daily Streaks & Avatar Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Earn coins to unlock exclusive perks', style: TextStyle(color: kTextSubtle)),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// HOME SCREEN (5 TABS + FLOATING MINI PLAYER)
// ==================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 2;
  StreamSubscription? callSubscription;

  final List<Widget?> pages = [null, null, null, null, null];

  Widget _pageAt(int index) {
    if (pages[index] == null) {
      pages[index] = switch (index) {
        0 => const FeedScreen(),
        1 => const MusicHubScreen(),
        2 => const ProfileScreen(),
        3 => const RewardsPlaceholderScreen(),
        _ => const ChatScreen(),
      };
    }
    return pages[index]!;
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ensureUserDoc(user);
      _listenForIncomingCalls(user.uid);
      _listenToCallKitEvents();
      _checkInitialCall();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          FocusManager.instance.primaryFocus?.unfocus();
          _requestAllPermissions();
        }
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyAsked = prefs.getBool('full_permissions_asked_v4') ?? false;

    if (!alreadyAsked) {
      await prefs.setBool('full_permissions_asked_v4', true);
      await NotificationService.initialize();
      await NotificationService.saveCurrentToken();

      await [
        Permission.microphone,
        Permission.camera,
        Permission.notification,
        Permission.photos,
        Permission.storage,
      ].request();

      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } else {
      await NotificationService.initialize();
    }
  }

  Future<void> _checkInitialCall() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        final call = calls.first;
        final extra = call['extra'] ?? {};
        final callId = extra['callId'] ?? call['id'];
        final callerName = extra['callerName'] ?? call['nameCaller'] ?? 'User';
        final callerPhoto = extra['callerPhoto'] ?? '';
        final callerId = extra['callerId'] ?? '';

        if (mounted) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => CallScreen(
                peerName: callerName,
                peerPhoto: callerPhoto,
                peerUid: callerId,
                callId: callId,
                isIncoming: true,
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _listenToCallKitEvents() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          final extra = event.body['extra'] ?? {};
          final callId = extra['callId'] ?? event.body['id'];
          final callerName = extra['callerName'] ?? event.body['nameCaller'] ?? 'User';
          final callerPhoto = extra['callerPhoto'] ?? '';
          final callerId = extra['callerId'] ?? '';

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => CallScreen(
                peerName: callerName,
                peerPhoto: callerPhoto,
                peerUid: callerId,
                callId: callId,
                isIncoming: true,
              ),
            ),
          );
          break;
        case Event.actionCallDecline:
          final callId = event.body['id'];
          if (callId != null) {
            FirebaseFirestore.instance.collection('calls').doc(callId).update({'status': 'ended'});
          }
          break;
        default:
          break;
      }
    });
  }

  void _listenForIncomingCalls(String myUid) {
    callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && mounted) {
            _showIncomingCallDialog(data, change.doc.id);
          }
        }
      }
    });
  }

  final Set<String> _shownIncomingCallIds = <String>{};

  Future<void> _showIncomingCallDialog(Map<String, dynamic> callData, String callId) async {
    if (_shownIncomingCallIds.contains(callId)) return;
    _shownIncomingCallIds.add(callId);

    final callerName = callData['callerName'] ?? 'User';
    final callerPhoto = callData['callerPhoto'] ?? '';
    final callerId = callData['callerId'] ?? '';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Avatar',
      avatar: callerPhoto.isNotEmpty ? callerPhoto : 'https://via.placeholder.com/150',
      handle: 'Voice Call',
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 35000,
      extra: <String, dynamic>{
        'callId': callId,
        'callerName': callerName,
        'callerPhoto': callerPhoto,
        'callerId': callerId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#141724',
        actionColor: '#00C6FF',
        incomingCallNotificationChannelName: 'Incoming Call',
        isShowCallID: true,
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (_) {}
  }

  @override
  void dispose() {
    callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: [
              currentIndex == 0 || pages[0] != null ? _pageAt(0) : const SizedBox.shrink(),
              currentIndex == 1 || pages[1] != null ? _pageAt(1) : const SizedBox.shrink(),
              currentIndex == 2 || pages[2] != null ? _pageAt(2) : const SizedBox.shrink(),
              currentIndex == 3 || pages[3] != null ? _pageAt(3) : const SizedBox.shrink(),
              currentIndex == 4 || pages[4] != null ? _pageAt(4) : const SizedBox.shrink(),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlobalMiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  currentIndex == 0 ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded,
                  color: currentIndex == 0 ? kPrimaryNeon : kDarkSurface,
                  size: 26,
                ),
                onPressed: () => setState(() => currentIndex = 0),
              ),
              IconButton(
                icon: Icon(
                  currentIndex == 1 ? Icons.music_note : Icons.music_note_outlined,
                  color: currentIndex == 1 ? kPrimaryNeon : kDarkSurface,
                  size: 26,
                ),
                onPressed: () => setState(() => currentIndex = 1),
              ),
              GestureDetector(
                onTap: () => setState(() => currentIndex = 2),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kPrimaryNeon, kAccentPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryNeon.withOpacity(currentIndex == 2 ? 0.45 : 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: currentIndex == 2 ? kPrimaryNeon : kDarkSurface,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  currentIndex == 3 ? Icons.stars_rounded : Icons.stars_outlined,
                  color: currentIndex == 3 ? Colors.amber.shade700 : kDarkSurface,
                  size: 26,
                ),
                onPressed: () => setState(() => currentIndex = 3),
              ),
              IconButton(
                icon: Icon(
                  currentIndex == 4 ? Icons.chat_bubble : Icons.chat_bubble_outline_rounded,
                  color: currentIndex == 4 ? kPrimaryNeon : kDarkSurface,
                  size: 26,
                ),
                onPressed: () => setState(() => currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// NOTIFICATIONS & UPDATES SCREEN
// ==================================================

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  Future<void> _connectBack(BuildContext context, String peerUid) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(myUid).set({
      'connections': FieldValue.arrayUnion([peerUid])
    }, SetOptions(merge: true));

    _showMessage(context, 'Connected back! Chat is now open.');
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & Updates')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, mySnap) {
          final myData = mySnap.data?.data() as Map<String, dynamic>?;
          final List<dynamic> myConnections = myData?['connections'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('app_updates').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, updateSnap) {
                  final updates = updateSnap.data?.docs ?? [];
                  if (updates.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Official Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkSurface)),
                      const SizedBox(height: 10),
                      ...updates.map((doc) {
                        final u = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kPrimaryNeon.withOpacity(0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: kPrimaryNeon,
                                child: Icon(Icons.campaign, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u['title'] ?? 'App Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(u['message'] ?? '', style: const TextStyle(color: kTextDark, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 28),
                    ],
                  );
                },
              ),
              const Text('Connection Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkSurface)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('connections', arrayContains: currentUid).snapshots(),
                builder: (context, reqSnap) {
                  if (reqSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryNeon));
                  }

                  final usersWhoConnectedMe = reqSnap.data?.docs ?? [];

                  if (usersWhoConnectedMe.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No new connection requests.', style: TextStyle(color: kTextSubtle))),
                    );
                  }

                  return Column(
                    children: usersWhoConnectedMe.map((doc) {
                      final uData = doc.data() as Map<String, dynamic>;
                      final peerUid = uData['uid'] ?? doc.id;
                      final peerName = (uData['name'] ?? '').toString();
                      final peerUsername = (uData['username'] ?? 'user').toString();
                      final peerBio = uData['bio'] ?? '';
                      final peerPhoto = uData['photoBase64'] ?? '';
                      final isMutual = myConnections.contains(peerUid);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => showUserAvatarPreview(
                                context,
                                photoBase64: peerPhoto,
                                name: peerName,
                                bio: peerBio,
                                username: peerUsername,
                                targetUid: peerUid,
                              ),
                              child: buildUserAvatar(
                                context: context,
                                photoBase64: peerPhoto,
                                name: peerName,
                                username: peerUsername,
                                bio: peerBio,
                                targetUid: peerUid,
                                radius: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(peerName.isNotEmpty ? peerName : '@$peerUsername', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(isMutual ? 'Mutual Connected' : 'Connected with you', style: const TextStyle(color: kTextSubtle, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (!isMutual)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kAccentPink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () => _connectBack(context, peerUid),
                                child: const Text('Connect Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
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

  Future<void> _togglePinChat(String peerUid, bool isPinned) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    if (isPinned) {
      await userRef.update({
        'pinnedChats': FieldValue.arrayRemove([peerUid]),
      });
      if (mounted) _showMessage(context, 'Chat unpinned.');
    } else {
      await userRef.update({
        'pinnedChats': FieldValue.arrayUnion([peerUid]),
      });
      if (mounted) _showMessage(context, 'Chat pinned to top.');
    }
  }

  Future<void> _deleteChatForMe(String peerUid) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final roomId = getChatRoomId(currentUid, peerUid);
    await FirebaseFirestore.instance.collection('chats').doc(roomId).set({
      'deletedBy': FieldValue.arrayUnion([currentUid]),
    }, SetOptions(merge: true));

    if (mounted) _showMessage(context, 'Chat deleted for you.');
  }

  void _showChatTileOptions(BuildContext context, {
    required String peerUid,
    required String peerName,
    required String peerUsername,
    required String peerPhoto,
    required String peerBio,
    required bool isPinned,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: kPrimaryNeon),
              title: Text(isPinned ? 'Unpin Chat' : 'Pin to Top', style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _togglePinChat(peerUid, isPinned);
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded, color: kDarkSurface),
              title: const Text('View Full Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserPublicProfileScreen(
                      targetUid: peerUid,
                      targetName: peerName,
                      targetUsername: peerUsername,
                      targetPhoto: peerPhoto,
                      targetBio: peerBio,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete Chat for Me', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteChatForMe(peerUid);
              },
            ),
          ],
        ),
      ),
    );
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
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiscoverScreen()),
              );
            },
            icon: const Icon(Icons.person_search_rounded, color: kDarkSurface, size: 26),
            tooltip: 'Discover & Search People',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded, color: kDarkSurface, size: 26),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, userSnap) {
          final myData = userSnap.data?.data() as Map<String, dynamic>?;
          final List<dynamic> myConnections = myData?['connections'] ?? [];
          final List<dynamic> pinnedChats = myData?['pinnedChats'] ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, allUsersSnap) {
              if (allUsersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimaryNeon));
              }

              final allDocs = allUsersSnap.data?.docs ?? [];

              var activeChatUsers = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final uid = data['uid'] ?? doc.id;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final username = (data['username'] ?? '').toString().toLowerCase();
                final bool isPrivate = data['isPrivate'] ?? false;
                final List<dynamic> theirConnections = data['connections'] ?? [];

                if (uid == currentUid) return false;

                bool canChat = false;
                if (!isPrivate && myConnections.contains(uid)) {
                  canChat = true;
                } else if (isPrivate && myConnections.contains(uid) && theirConnections.contains(currentUid)) {
                  canChat = true;
                }

                if (!canChat) return false;

                if (searchQuery.isNotEmpty) {
                  return name.contains(searchQuery.toLowerCase()) || username.contains(searchQuery.toLowerCase());
                }
                return true;
              }).toList();

              activeChatUsers.sort((a, b) {
                final aPinned = pinnedChats.contains(a.id);
                final bPinned = pinnedChats.contains(b.id);
                if (aPinned && !bPinned) return -1;
                if (!aPinned && bPinned) return 1;
                return 0;
              });

              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: TextField(
                      controller: searchController,
                      onChanged: (v) => setState(() => searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        prefixIcon: const Icon(Icons.search, color: kTextSubtle),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [kPrimaryNeon, kAccentPink]),
                        ),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.auto_awesome, color: kAccentPink, size: 20),
                        ),
                      ),
                      title: const Text('Avatar Friend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkSurface)),
                      subtitle: const Text('AI Companion • Always Online', style: TextStyle(color: Colors.green, fontSize: 13)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryNeon.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('AI', style: TextStyle(color: kPrimaryNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatConversationScreen(userName: 'Avatar Friend')),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (activeChatUsers.isNotEmpty) ...[
                    ...activeChatUsers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final peerUid = data['uid'] ?? doc.id;
                      final name = (data['name'] ?? '').toString();
                      final username = (data['username'] ?? 'user').toString();
                      final bio = data['bio'] ?? '';
                      final photo = data['photoBase64'] ?? '';
                      final isOnline = data['isOnline'] == true;
                      final isPinned = pinnedChats.contains(peerUid);

                      final displayName = name.isNotEmpty ? name : '@$username';

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isPinned ? Border.all(color: kPrimaryNeon.withOpacity(0.6), width: 1.2) : null,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                          ],
                        ),
                        child: ListTile(
                          onLongPress: () => _showChatTileOptions(
                            context,
                            peerUid: peerUid,
                            peerName: name,
                            peerUsername: username,
                            peerPhoto: photo,
                            peerBio: bio,
                            isPinned: isPinned,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Stack(
                            children: [
                              buildUserAvatar(
                                context: context,
                                photoBase64: photo,
                                name: name,
                                username: username,
                                bio: bio,
                                targetUid: peerUid,
                                radius: 22,
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkSurface))),
                              if (isPinned)
                                const Icon(Icons.push_pin_rounded, size: 16, color: kPrimaryNeon),
                            ],
                          ),
                          subtitle: Text(
                            isOnline ? 'Active now' : 'Offline',
                            style: TextStyle(color: isOnline ? Colors.green : kTextSubtle, fontSize: 13),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: kTextSubtle),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatConversationScreen(
                                  userName: displayName,
                                  peerUid: peerUid,
                                  peerPhoto: photo,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.people_outline_rounded, size: 50, color: kTextSubtle),
                            SizedBox(height: 10),
                            Text('No active chats.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkSurface)),
                            SizedBox(height: 4),
                            Text('Connect with Public accounts to chat directly, or wait for Private accounts to connect back.', textAlign: TextAlign.center, style: TextStyle(color: kTextSubtle, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ==================================================
// DISCOVER & SEARCH PEOPLE SCREEN
// ==================================================

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  Future<void> toggleConnection(String peerUid, bool isConnected) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUid);

    if (isConnected) {
      await userRef.set({
        'connections': FieldValue.arrayRemove([peerUid])
      }, SetOptions(merge: true));
      if (mounted) _showMessage(context, 'Disconnected.');
    } else {
      await userRef.set({
        'connections': FieldValue.arrayUnion([peerUid])
      }, SetOptions(merge: true));
      if (mounted) _showMessage(context, 'Connected successfully!');
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
      appBar: AppBar(title: const Text('Discover People', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, userSnap) {
          final myData = userSnap.data?.data() as Map<String, dynamic>?;
          final List<dynamic> myConnections = myData?['connections'] ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: (val) => setState(() => searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name or @username...',
                    prefixIcon: const Icon(Icons.search, color: kTextSubtle),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
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
                      return const Center(child: CircularProgressIndicator(color: kPrimaryNeon));
                    }

                    final users = (snapshot.data?.docs ?? []).where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = data['uid'] ?? doc.id;
                      if (uid == currentUid) return false;

                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final username = (data['username'] ?? '').toString().toLowerCase();

                      if (searchQuery.isEmpty) return true;
                      return name.contains(searchQuery) || username.contains(searchQuery);
                    }).toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text('No users found.', style: TextStyle(color: kTextSubtle)),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final userData = users[index].data() as Map<String, dynamic>;
                        final userName = (userData['name'] ?? '').toString();
                        final userUsername = (userData['username'] ?? 'user').toString();
                        final userBio = userData['bio'] ?? 'Using Avatar';
                        final peerUid = userData['uid'] ?? users[index].id;
                        final photo = userData['photoBase64'] ?? '';
                        final isConnected = myConnections.contains(peerUid);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: GestureDetector(
                              onTap: () => showUserAvatarPreview(
                                context,
                                photoBase64: photo,
                                name: userName,
                                bio: userBio,
                                username: userUsername,
                                targetUid: peerUid,
                              ),
                              child: buildUserAvatar(
                                context: context,
                                photoBase64: photo,
                                name: userName,
                                username: userUsername,
                                bio: userBio,
                                targetUid: peerUid,
                                radius: 22,
                              ),
                            ),
                            title: Text(userName.isNotEmpty ? userName : '@$userUsername', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkSurface)),
                            subtitle: Text('@$userUsername • $userBio', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextSubtle)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isConnected ? kLightBg : kDarkSurface,
                                foregroundColor: isConnected ? kTextDark : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => toggleConnection(peerUid, isConnected),
                              child: Text(isConnected ? 'Connected' : 'Connect', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
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
// FULL SCREEN IMAGE VIEWER
// ==================================================

class FullImageViewScreen extends StatelessWidget {
  final String imageData;

  const FullImageViewScreen({Key? key, required this.imageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageData.startsWith('http')) {
      imageWidget = Image.network(imageData, fit: BoxFit.contain);
    } else {
      try {
        final cleanData = imageData.replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '');
        final bytes = base64Decode(cleanData);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        imageWidget = const Icon(Icons.broken_image, size: 80, color: Colors.white54);
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(child: imageWidget),
      ),
    );
  }
}

// ==================================================
// SINGLE REEL FULL SCREEN PLAYER (FOR PROFILE TAP)
// ==================================================

class SingleReelScreen extends StatelessWidget {
  final String videoUrl;
  final String caption;
  final String creatorName;

  const SingleReelScreen({
    Key? key,
    required this.videoUrl,
    required this.caption,
    required this.creatorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ReelVideoPlayerItem(videoUrl: videoUrl),
          Positioned(
            left: 16,
            bottom: 30,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$creatorName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(caption, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// 1-ON-1 ACTIVE CALLING SCREEN WITH LIVE AUDIO SYNC
// ==================================================

class CallScreen extends StatefulWidget {
  final String peerName;
  final String peerPhoto;
  final String peerUid;
  final String? callId;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    required this.peerName,
    required this.peerPhoto,
    required this.peerUid,
    this.callId,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final WebRtcSignalingService _signaling = WebRtcSignalingService();
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _syncMusicPlayer = AudioPlayer();

  bool isMuted = false;
  bool isSpeaker = false;
  bool isConnected = false;
  int callSeconds = 0;
  Timer? callTimer;

  String? activeCallId;
  StreamSubscription? musicSyncSubscription;
  SongModel? syncedSong;
  bool isSyncPlaying = false;

  @override
  void initState() {
    super.initState();
    _startWebRtcCall();
  }

  Future<void> _playOutgoingRingtone() async {
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(AssetSource('audio/dialing.mp3'));
    } catch (_) {}
  }

  void _stopOutgoingRingtone() {
    try {
      _ringtonePlayer.stop();
    } catch (_) {}
  }

  Future<void> _startWebRtcCall() async {
    await _signaling.openAudioStream();

    if (widget.isIncoming && widget.callId != null) {
      activeCallId = widget.callId;
      _listenToMusicSync(activeCallId!);

      await _signaling.answerCall(
        callId: widget.callId!,
        onRemoteStreamReceived: (stream) {
          unawaited(FlutterCallkitIncoming.setCallConnected(widget.callId!));
          _startTimer();
        },
        onCallEnded: () {
          _stopOutgoingRingtone();
          unawaited(FlutterCallkitIncoming.endAllCalls());
          _logCallHistory();
          if (mounted) Navigator.pop(context);
        },
      );
      _startTimer();
      return;
    }

    _playOutgoingRingtone();

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currentName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';

    activeCallId = await _signaling.createCall(
      callerId: currentUid,
      calleeId: widget.peerUid,
      callerName: currentName,
      callerPhoto: '',
      onRemoteStreamReceived: (stream) {
        _stopOutgoingRingtone();
        if (activeCallId != null) {
          unawaited(FlutterCallkitIncoming.setCallConnected(activeCallId!));
          _listenToMusicSync(activeCallId!);
        }
        _startTimer();
      },
      onCallEnded: () {
        _stopOutgoingRingtone();
        unawaited(FlutterCallkitIncoming.endAllCalls());
        _logCallHistory();
        if (mounted) Navigator.pop(context);
      },
    );

    try {
      final outgoingParams = CallKitParams(
        id: activeCallId!,
        nameCaller: widget.peerName,
        appName: 'Avatar',
        handle: 'Voice Call',
        type: 1,
        extra: <String, dynamic>{
          'callId': activeCallId!,
          'peerUid': widget.peerUid,
          'callerName': currentName,
          'callerPhoto': '',
        },
        callingNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Calling...',
          callbackText: 'Hang Up',
        ),
        android: const AndroidParams(
          isCustomNotification: true,
          isShowCallID: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      await FlutterCallkitIncoming.startCall(outgoingParams);
    } catch (_) {}
  }

  void _listenToMusicSync(String callId) {
    musicSyncSubscription = FirebaseFirestore.instance.collection('calls').doc(callId).snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null && data['syncedMusic'] != null) {
        final Map<String, dynamic> mData = data['syncedMusic'];
        final song = SongModel.fromJson(mData['song']);
        final playing = mData['isPlaying'] == true;

        if (syncedSong?.url != song.url) {
          syncedSong = song;
          await _syncMusicPlayer.stop();
          await _syncMusicPlayer.play(UrlSource(song.url));
          await _syncMusicPlayer.setVolume(0.35);
        }

        if (playing && !isSyncPlaying) {
          await _syncMusicPlayer.resume();
          setState(() => isSyncPlaying = true);
        } else if (!playing && isSyncPlaying) {
          await _syncMusicPlayer.pause();
          setState(() => isSyncPlaying = false);
        }
      }
    });
  }

  Future<void> _pickSyncMusic() async {
    if (activeCallId == null) return;
    final SongModel? song = await showModalBottomSheet<SongModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MusicPickerModal(),
    );

    if (song != null) {
      await FirebaseFirestore.instance.collection('calls').doc(activeCallId).update({
        'syncedMusic': {
          'song': song.toJson(),
          'isPlaying': true,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    }
  }

  void _startTimer() {
    _stopOutgoingRingtone();
    if (!isConnected && mounted) {
      setState(() => isConnected = true);
      callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => callSeconds++);
      });
    }
  }

  void _toggleMic() {
    setState(() => isMuted = !isMuted);
    _signaling.localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  void _toggleSpeaker() {
    setState(() => isSpeaker = !isSpeaker);
    _signaling.remoteStream?.getAudioTracks().forEach((track) {
      track.enableSpeakerphone(isSpeaker);
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _logCallHistory() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || widget.peerUid.isEmpty) return;

    try {
      final roomId = getChatRoomId(currentUid, widget.peerUid);
      final logText = isConnected
          ? 'Voice Call • ${_formatTime(callSeconds)}'
          : (widget.isIncoming ? 'Missed Voice Call' : 'Cancelled Voice Call');

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .add({
        'senderId': currentUid,
        'receiverId': widget.peerUid,
        'type': 'call_log',
        'text': logText,
        'callStatus': isConnected ? 'connected' : (widget.isIncoming ? 'missed' : 'cancelled'),
        'isRead': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopOutgoingRingtone();
    _ringtonePlayer.dispose();
    _syncMusicPlayer.dispose();
    musicSyncSubscription?.cancel();
    callTimer?.cancel();
    _logCallHistory();
    unawaited(_signaling.hangUp());
    unawaited(FlutterCallkitIncoming.endAllCalls());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkSurface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              widget.peerName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              isConnected ? 'Connected • ${_formatTime(callSeconds)}' : 'Calling...',
              style: TextStyle(fontSize: 16, color: isConnected ? kPrimaryNeon : Colors.white60),
            ),
            const Spacer(),
            buildUserAvatar(
              context: context,
              photoBase64: widget.peerPhoto,
              name: widget.peerName,
              targetUid: widget.peerUid,
              radius: 75,
              enablePreview: false,
            ),
            if (syncedSong != null) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPrimaryNeon.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_note_rounded, color: kPrimaryNeon, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Synced: ${syncedSong!.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  iconSize: 26,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: isMuted ? Colors.white : Colors.white12,
                    foregroundColor: isMuted ? Colors.black : Colors.white,
                  ),
                  onPressed: _toggleMic,
                  icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
                ),
                IconButton.filledTonal(
                  iconSize: 26,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: kPrimaryNeon.withOpacity(0.2),
                    foregroundColor: kPrimaryNeon,
                  ),
                  onPressed: _pickSyncMusic,
                  icon: const Icon(Icons.music_note_rounded),
                  tooltip: 'Listen Music Together',
                ),
                IconButton.filled(
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.call_end, color: Colors.white),
                ),
                IconButton.filledTonal(
                  iconSize: 26,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: isSpeaker ? Colors.white : Colors.white12,
                    foregroundColor: isSpeaker ? Colors.black : Colors.white,
                  ),
                  onPressed: _toggleSpeaker,
                  icon: Icon(isSpeaker ? Icons.volume_up : Icons.volume_down),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// AUDIO WAVEFORM VOICE NOTE PLAYER
// ==================================================

class VoiceNoteBubble extends StatefulWidget {
  final String audioBase64;
  final bool isMe;

  const VoiceNoteBubble({Key? key, required this.audioBase64, required this.isMe}) : super(key: key);

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String? tempAudioPath;
  late final List<double> barHeights;

  @override
  void initState() {
    super.initState();
    final rand = Random(widget.audioBase64.hashCode);
    barHeights = List.generate(24, (_) => 0.25 + rand.nextDouble() * 0.75);

    _prepareAudio();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => isPlaying = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => position = p);
    });
  }

  Future<void> _prepareAudio() async {
    try {
      final bytes = base64Decode(widget.audioBase64);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}.m4a');
      await file.writeAsBytes(bytes);
      tempAudioPath = file.path;
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (tempAudioPath != null) {
        await _audioPlayer.play(DeviceFileSource(tempAudioPath!));
      }
    }
  }

  void _seek(double progress) {
    if (duration.inMilliseconds > 0) {
      final targetMs = (progress * duration.inMilliseconds).toInt();
      _audioPlayer.seek(Duration(milliseconds: targetMs));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _togglePlay,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 38,
            color: widget.isMe ? Colors.white : kPrimaryNeon,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final tapPos = box.globalToLocal(details.globalPosition);
                _seek((tapPos.dx / 130).clamp(0.0, 1.0));
              },
              onTapDown: (details) {
                _seek((details.localPosition.dx / 130).clamp(0.0, 1.0));
              },
              child: SizedBox(
                width: 130,
                height: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(barHeights.length, (idx) {
                    final barProgress = idx / barHeights.length;
                    final isPassed = barProgress <= progress;
                    return Container(
                      width: 3,
                      height: 28 * barHeights[idx],
                      decoration: BoxDecoration(
                        color: isPassed
                            ? (widget.isMe ? Colors.white : kPrimaryNeon)
                            : (widget.isMe ? Colors.white38 : Colors.black12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${position.inSeconds}s / ${duration.inSeconds}s',
              style: TextStyle(fontSize: 11, color: widget.isMe ? Colors.white70 : kTextSubtle),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ==================================================
// CHAT CONVERSATION SCREEN
// ==================================================

class ChatConversationScreen extends StatefulWidget {
  final String userName;
  final String? peerUid;
  final String? peerPhoto;

  const ChatConversationScreen({
    Key? key,
    required this.userName,
    this.peerUid,
    this.peerPhoto,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, String>> localMessages = [];
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool isLoading = false;
  bool isRecording = false;
  int recordingSeconds = 0;
  Timer? recordingTimer;
  bool isUploadingMedia = false;
  bool isSendingMessage = false;
  bool isVoiceEnabled = true;
  Timer? typingDebounceTimer;
  Timer? typingWriteTimer;

  bool get isAvatarFriend => widget.userName == 'Avatar Friend';
  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get currentName => FirebaseAuth.instance.currentUser?.displayName ?? 'User';
  String get chatRoomId => getChatRoomId(currentUid, widget.peerUid ?? '');

  @override
  void initState() {
    super.initState();
    _initTts();
    if (isAvatarFriend) {
      _loadChatHistory();
    } else {
      _markMessagesAsRead();
    }

    messageFocusNode.addListener(() {
      if (messageFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () => _scrollToBottom());
      }
    });
  }

  void _markMessagesAsRead() async {
    try {
      final unreadDocs = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        doc.reference.update({'isRead': true});
      }
    } catch (_) {}
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (isAvatarFriend || widget.peerUid == null || currentUid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
        'typing_$currentUid': isTyping,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _onTextChanged(String text) {
    if (isAvatarFriend) return;

    typingWriteTimer?.cancel();
    if (text.trim().isNotEmpty) {
      typingWriteTimer = Timer(const Duration(milliseconds: 400), () {
        _updateTypingStatus(true);
      });
    } else {
      _updateTypingStatus(false);
    }

    typingDebounceTimer?.cancel();
    typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      _updateTypingStatus(false);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      if (isAvatarFriend) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
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
    if (mounted) _showMessage(context, 'Chat history cleared.');
  }

  Future<void> _pickAndSendGalleryImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => isUploadingMedia = true);

      final Uint8List bytes = await pickedFile.readAsBytes();
      final String base64String = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUid,
        'receiverId': widget.peerUid,
        'type': 'image',
        'imageData': base64String,
        'deletedFor': [],
        'isRead': false,
        'reaction': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (widget.peerUid != null) {
        unawaited(
          NotificationService.triggerChatPush(
            receiverUid: widget.peerUid!,
            senderName: currentName,
            messageText: 'Photo',
          ),
        );
      }

      _scrollToBottom();
      if (mounted) setState(() => isUploadingMedia = false);
    } catch (e) {
      if (mounted) {
        setState(() => isUploadingMedia = false);
        _showMessage(context, 'Image error: $e');
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          isRecording = true;
          recordingSeconds = 0;
        });

        recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => recordingSeconds++);
        });
      } else {
        _showMessage(context, 'Microphone permission required.');
      }
    } catch (e) {
      _showMessage(context, 'Recording error: $e');
    }
  }

  Future<void> _cancelRecording() async {
    recordingTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    setState(() => isRecording = false);
    if (mounted) _showMessage(context, 'Recording cancelled.');
  }

  Future<void> _stopAndSendRecording() async {
    recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() => isRecording = false);

      if (path != null && recordingSeconds >= 1) {
        final file = File(path);
        final bytes = await file.readAsBytes();
        final base64Audio = base64Encode(bytes);

        if (!isAvatarFriend) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatRoomId)
              .collection('messages')
              .add({
            'senderId': currentUid,
            'receiverId': widget.peerUid,
            'type': 'audio',
            'audioData': base64Audio,
            'deletedFor': [],
            'isRead': false,
            'reaction': '',
            'timestamp': FieldValue.serverTimestamp(),
          });

          if (widget.peerUid != null) {
            unawaited(
              NotificationService.triggerChatPush(
                receiverUid: widget.peerUid!,
                senderName: currentName,
                messageText: 'Voice message',
              ),
            );
          }

          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() => isRecording = false);
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSendingMessage) return;

    setState(() => isSendingMessage = true);
    messageController.clear();
    _updateTypingStatus(false);

    try {
      if (isAvatarFriend) {
        setState(() {
          localMessages.add({'sender': 'user', 'type': 'text', 'text': text});
          isLoading = true;
        });
        await _saveChatHistory();
        _scrollToBottom();

        final reply = await askAvatarFriend(text);
        if (!mounted) return;

        setState(() {
          localMessages.add({'sender': 'bot', 'type': 'text', 'text': reply});
          isLoading = false;
        });
        await _saveChatHistory();
        _scrollToBottom();
        unawaited(_speak(reply));
      } else {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .add({
          'senderId': currentUid,
          'receiverId': widget.peerUid,
          'type': 'text',
          'text': text,
          'deletedFor': [],
          'isRead': false,
          'reaction': '',
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (widget.peerUid != null) {
          unawaited(
            NotificationService.triggerChatPush(
              receiverUid: widget.peerUid!,
              senderName: currentName,
              messageText: text,
            ),
          );
        }

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) _showMessage(context, 'Message send failed.');
    } finally {
      if (mounted) setState(() => isSendingMessage = false);
    }
  }

  void _showMessageOptions(DocumentSnapshot doc, Map<String, dynamic> data, bool isMe) {
    final bool isRead = data['isRead'] == true;
    final bool canUnsend = isMe && !isRead;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '👍', '🔥', '😮', '😢'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      doc.reference.update({'reaction': emoji});
                      Navigator.pop(ctx);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            if (data['type'] == 'text')
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy Text'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data['text'] ?? ''));
                  Navigator.pop(ctx);
                  _showMessage(context, 'Text copied.');
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.orangeAccent),
              title: const Text('Delete for Me', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
              onTap: () {
                doc.reference.update({
                  'deletedFor': FieldValue.arrayUnion([currentUid]),
                });
                Navigator.pop(ctx);
                _showMessage(context, 'Deleted for you.');
              },
            ),
            if (canUnsend)
              ListTile(
                leading: const Icon(Icons.undo_rounded, color: Colors.redAccent),
                title: const Text('Unsend (Delete for Everyone)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                subtitle: const Text('Receiver has not seen this message yet', style: TextStyle(fontSize: 11, color: kTextSubtle)),
                onTap: () {
                  doc.reference.delete();
                  Navigator.pop(ctx);
                  _showMessage(context, 'Message unsent.');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _updateTypingStatus(false);
    typingDebounceTimer?.cancel();
    typingWriteTimer?.cancel();
    recordingTimer?.cancel();
    _audioRecorder.dispose();
    scrollController.dispose();
    flutterTts.stop();
    messageController.dispose();
    messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            isAvatarFriend
                ? Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [kPrimaryNeon, kAccentPink]),
                    ),
                    child: const CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.auto_awesome, size: 18, color: kAccentPink),
                    ),
                  )
                : buildUserAvatar(
                    context: context,
                    photoBase64: widget.peerPhoto ?? '',
                    name: widget.userName,
                    targetUid: widget.peerUid,
                    radius: 17,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: isAvatarFriend
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDarkSurface)),
                        const Text('AI Companion', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    )
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).snapshots(),
                      builder: (context, chatDocSnap) {
                        final chatData = chatDocSnap.data?.data() as Map<String, dynamic>?;
                        final isPeerTyping = chatData?['typing_${widget.peerUid}'] == true;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDarkSurface)),
                            Text(
                              isPeerTyping ? 'typing...' : 'Online',
                              style: TextStyle(
                                color: isPeerTyping ? kAccentPink : Colors.green,
                                fontSize: 12,
                                fontWeight: isPeerTyping ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
        actions: [
          if (isAvatarFriend) ...[
            IconButton(
              onPressed: () {
                setState(() => isVoiceEnabled = !isVoiceEnabled);
                if (!isVoiceEnabled) flutterTts.stop();
                _showMessage(
                  context,
                  isVoiceEnabled ? 'Voice Enabled' : 'Voice Muted',
                );
              },
              icon: Icon(
                isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: isVoiceEnabled ? kPrimaryNeon : kTextSubtle,
              ),
            ),
            IconButton(
              onPressed: _clearChatHistory,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      peerName: widget.userName,
                      peerPhoto: widget.peerPhoto ?? '',
                      peerUid: widget.peerUid ?? '',
                      isIncoming: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.call_rounded, color: kPrimaryNeon),
              tooltip: 'Voice Call',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (isUploadingMedia) const LinearProgressIndicator(minHeight: 3, color: kPrimaryNeon),
          Expanded(
            child: isAvatarFriend ? _buildAiChat() : _buildRealUserChat(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: isRecording
                  ? Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('${recordingSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                          const Spacer(),
                          TextButton(
                            onPressed: _cancelRecording,
                            child: const Text('Cancel', style: TextStyle(color: kTextDark)),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: _stopAndSendRecording,
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        if (!isAvatarFriend)
                          IconButton(
                            onPressed: _pickAndSendGalleryImage,
                            icon: const Icon(Icons.image_outlined, color: kTextDark),
                            tooltip: 'Send Photo',
                          ),
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            focusNode: messageFocusNode,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 5,
                            onChanged: _onTextChanged,
                            onSubmitted: (_) => sendMessage(),
                            decoration: InputDecoration(
                              hintText: isAvatarFriend ? 'Ask AI anything...' : 'Type a message...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (!isAvatarFriend) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _startRecording,
                            icon: const Icon(Icons.mic_none_rounded, color: kTextDark),
                          ),
                        ],
                        const SizedBox(width: 4),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [kPrimaryNeon, kAccentPink]),
                          ),
                          child: IconButton(
                            onPressed: sendMessage,
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
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

  Widget _buildAiChat() {
    if (localMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome, size: 60, color: kAccentPink),
            SizedBox(height: 14),
            Text('Say hello to Avatar Friend!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkSurface)),
            SizedBox(height: 4),
            Text('Your personal voice AI companion', style: TextStyle(fontSize: 13, color: kTextSubtle)),
          ],
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryNeon)),
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
              gradient: isUser ? const LinearGradient(colors: [kPrimaryNeon, kAccentPink]) : null,
              color: isUser ? null : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(fontSize: 15, color: isUser ? Colors.white : kDarkSurface, fontWeight: isUser ? FontWeight.w500 : FontWeight.normal),
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _speak(msg['text'] ?? ''),
                    child: const Icon(Icons.volume_up_rounded, size: 18, color: kPrimaryNeon),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealUserChat() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryNeon));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 60, color: kTextSubtle),
                const SizedBox(height: 12),
                Text('Start a conversation with ${widget.userName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDarkSurface)),
              ],
            ),
          );
        }

        final allMessages = snapshot.data!.docs;
        final messages = allMessages.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> deletedFor = data['deletedFor'] ?? [];
          return !deletedFor.contains(currentUid);
        }).toList();

        return ListView.builder(
          reverse: true,
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>;
            final isMe = data['senderId'] == currentUid;
            final type = data['type'] ?? 'text';
            final imgPayload = data['imageData'] ?? data['imageUrl'] ?? '';
            final audioPayload = data['audioData'] ?? '';
            final isRead = data['isRead'] == true;
            final reaction = data['reaction'] ?? '';

            if (type == 'call_log') {
              final status = data['callStatus'] ?? 'connected';
              final isMissed = status == 'missed';
              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isMissed ? Colors.redAccent.withOpacity(0.4) : Colors.green.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainBuildContext.min,
                    children: [
                      Icon(isMissed ? Icons.phone_missed_rounded : Icons.phone_rounded, size: 16, color: isMissed ? Colors.redAccent : Colors.green),
                      const SizedBox(width: 8),
                      Text(data['text'] ?? 'Voice Call', style: TextStyle(fontSize: 13, color: isMissed ? Colors.redAccent : Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }

            return GestureDetector(
              onLongPress: () => _showMessageOptions(doc, data, isMe),
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: type == 'image'
                          ? const EdgeInsets.all(4)
                          : (type == 'audio'
                              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                              : const EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
                      decoration: BoxDecoration(
                        gradient: isMe ? const LinearGradient(colors: [kPrimaryNeon, kAccentPink]) : null,
                        color: isMe ? null : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (type == 'image')
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FullImageViewScreen(imageData: imgPayload)),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: imgPayload.startsWith('http')
                                    ? Image.network(imgPayload, width: 220, height: 220, fit: BoxFit.cover)
                                    : Image.memory(base64Decode(imgPayload), width: 220, height: 220, fit: BoxFit.cover),
                              ),
                            )
                          else if (type == 'audio')
                            VoiceNoteBubble(key: ValueKey(doc.id), audioBase64: audioPayload, isMe: isMe)
                          else
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(fontSize: 15, color: isMe ? Colors.white : kDarkSurface, fontWeight: isMe ? FontWeight.w500 : FontWeight.normal),
                            ),
                          if (isMe) ...[
                            const SizedBox(height: 2),
                            Icon(
                              isRead ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 15,
                              color: Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (reaction.isNotEmpty)
                      Positioned(
                        bottom: 2,
                        right: isMe ? 4 : null,
                        left: !isMe ? 4 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)
                            ],
                          ),
                          child: Text(reaction, style: const TextStyle(fontSize: 13)),
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
}

// ==================================================
// INTERACTIVE CONNECTED & CONNECTORS POPUP SHEET
// ==================================================

class ConnectionsListModal extends StatefulWidget {
  final String title;
  final bool isConnectedMode;
  final String myUid;
  final List<dynamic> myConnections;

  const ConnectionsListModal({
    Key? key,
    required this.title,
    required this.isConnectedMode,
    required this.myUid,
    required this.myConnections,
  }) : super(key: key);

  @override
  State<ConnectionsListModal> createState() => _ConnectionsListModalState();
}

class _ConnectionsListModalState extends State<ConnectionsListModal> {
  final TextEditingController searchCtrl = TextEditingController();
  String query = '';

  Future<void> _toggleConnection(String peerUid, bool currentlyConnected) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.myUid);
    if (currentlyConnected) {
      await userRef.set({
        'connections': FieldValue.arrayRemove([peerUid])
      }, SetOptions(merge: true));
      if (mounted) _showMessage(context, 'Disconnected.');
    } else {
      await userRef.set({
        'connections': FieldValue.arrayUnion([peerUid])
      }, SetOptions(merge: true));
      if (mounted) _showMessage(context, 'Connected back!');
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkSurface)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 22)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search, color: kTextSubtle),
                filled: true,
                fillColor: kLightBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.myUid).snapshots(),
              builder: (context, mySnap) {
                final myLiveConnections = (mySnap.data?.data() as Map<String, dynamic>?)?['connections'] as List<dynamic>? ?? widget.myConnections;

                Query userQuery = FirebaseFirestore.instance.collection('users');
                if (widget.isConnectedMode) {
                  if (myLiveConnections.isEmpty) {
                    return const Center(child: Text('No connected users yet.', style: TextStyle(color: kTextSubtle)));
                  }
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: widget.isConnectedMode
                      ? userQuery.snapshots()
                      : userQuery.where('connections', arrayContains: widget.myUid).snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kPrimaryNeon));
                    }

                    var docs = snap.data?.docs ?? [];
                    if (widget.isConnectedMode) {
                      docs = docs.where((d) => myLiveConnections.contains(d.id)).toList();
                    }

                    final filtered = docs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final name = (d['name'] ?? '').toString().toLowerCase();
                      final username = (d['username'] ?? '').toString().toLowerCase();
                      if (query.isEmpty) return true;
                      return name.contains(query) || username.contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No matching users found.', style: TextStyle(color: kTextSubtle)));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final uData = filtered[idx].data() as Map<String, dynamic>;
                        final peerUid = uData['uid'] ?? filtered[idx].id;
                        final name = (uData['name'] ?? '').toString();
                        final username = (uData['username'] ?? 'user').toString();
                        final bio = uData['bio'] ?? '';
                        final photo = uData['photoBase64'] ?? '';
                        final isAlreadyConnectedByMe = myLiveConnections.contains(peerUid);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: GestureDetector(
                            onTap: () => showUserAvatarPreview(
                              context,
                              photoBase64: photo,
                              name: name,
                              username: username,
                              bio: bio,
                              targetUid: peerUid,
                            ),
                            child: buildUserAvatar(
                              context: context,
                              photoBase64: photo,
                              name: name,
                              username: username,
                              bio: bio,
                              targetUid: peerUid,
                              radius: 22,
                            ),
                          ),
                          title: Text(name.isNotEmpty ? name : '@$username', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('@$username', style: const TextStyle(color: kTextSubtle, fontSize: 13)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAlreadyConnectedByMe ? kLightBg : kPrimaryNeon,
                              foregroundColor: isAlreadyConnectedByMe ? kTextDark : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _toggleConnection(peerUid, isAlreadyConnectedByMe),
                            child: Text(
                              isAlreadyConnectedByMe ? 'Disconnect' : 'Connect Back',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        );
                      },
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

// ==================================================
// MY PROFILE SCREEN (WITH SEPARATE REELS/POSTS TABS)
// ==================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  String displayName = '';
  String username = '';
  String displayBio = 'Hey there! I am on Avatar.';
  String photoBase64 = '';
  bool isPrivateAccount = false;
  int profileTab = 0; // 0 = Reels, 1 = Posts

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          displayName = data?['name'] ?? '';
          username = data?['username'] ?? '';
          displayBio = data?['bio'] ?? displayBio;
          photoBase64 = data?['photoBase64'] ?? '';
          isPrivateAccount = data?['isPrivate'] ?? false;
        });
      }
    }
  }

  Future<void> _togglePrivacy(bool value) async {
    setState(() => isPrivateAccount = value);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isPrivate': value,
      }, SetOptions(merge: true));
      if (mounted) _showMessage(context, value ? 'Account set to Private' : 'Account set to Public');
    }
  }

  Future<void> _updateProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: kDarkSurface,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            activeControlsWidgetColor: kPrimaryNeon,
          ),
        ],
      );

      if (croppedFile == null) return;

      final bytes = await croppedFile.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() => photoBase64 = base64String);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'photoBase64': base64String,
        }, SetOptions(merge: true));
        if (mounted) _showMessage(context, 'Profile picture updated.');
      }
    } catch (e) {
      if (mounted) _showMessage(context, 'Error: $e');
    }
  }

  void _openEditProfileSheet() {
    final nameCtrl = TextEditingController(text: displayName);
    final usernameCtrl = TextEditingController(text: username);
    final bioCtrl = TextEditingController(text: displayBio);
    String sheetError = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              const Text('Edit Profile Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkSurface)),
              const SizedBox(height: 18),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                  labelText: 'Unique Username (@)',
                  filled: true,
                  fillColor: kLightBg,
                  errorText: sheetError.isNotEmpty ? sheetError : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g. Mohit Sharma',
                  filled: true,
                  fillColor: kLightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Bio / Status',
                  filled: true,
                  fillColor: kLightBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [kPrimaryNeon, kAccentPink]),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    final newUsername = usernameCtrl.text.trim().toLowerCase();
                    final newName = nameCtrl.text.trim();
                    final newBio = bioCtrl.text.trim();
                    final user = FirebaseAuth.instance.currentUser;

                    if (newUsername.isEmpty || newUsername.contains(' ') || newUsername.length < 3) {
                      setModalState(() => sheetError = 'Valid username (min 3 chars, no space) required.');
                      return;
                    }

                    if (newUsername != username) {
                      final check = await FirebaseFirestore.instance
                          .collection('users')
                          .where('username', isEqualTo: newUsername)
                          .get();

                      if (check.docs.isNotEmpty) {
                        setModalState(() => sheetError = 'This username is already taken. Please choose another one.');
                        return;
                      }
                    }

                    setState(() {
                      username = newUsername;
                      displayName = newName;
                      displayBio = newBio;
                    });

                    Navigator.pop(ctx);

                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                        'username': newUsername,
                        'name': newName,
                        'bio': newBio,
                      }, SetOptions(merge: true));
                    }

                    if (mounted) _showMessage(context, 'Profile updated.');
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openConnectionsModal(bool isConnectedMode, List<dynamic> myConnections, String myUid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConnectionsListModal(
        title: isConnectedMode ? 'People You Connected' : 'Your Connectors',
        isConnectedMode: isConnectedMode,
        myUid: myUid,
        myConnections: myConnections,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final myUid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(username.isNotEmpty ? '@$username' : 'My Profile', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        actions: [
          IconButton(
            onPressed: () async {
              updateUserPresence(false);
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Stack(
                children: [
                  buildUserAvatar(
                    context: context,
                    photoBase64: photoBase64,
                    name: displayName,
                    username: username,
                    bio: displayBio,
                    targetUid: myUid,
                    radius: 60,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _updateProfilePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kDarkSurface,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(displayName.isNotEmpty ? displayName : (username.isNotEmpty ? '@$username' : 'Set Your Name'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kDarkSurface)),
              if (displayName.isNotEmpty && username.isNotEmpty)
                Text('@$username', style: const TextStyle(color: kTextSubtle, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(displayBio, textAlign: TextAlign.center, style: const TextStyle(color: kTextSubtle, fontSize: 14)),
              const SizedBox(height: 24),

              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
                builder: (context, mySnap) {
                  final myData = mySnap.data?.data() as Map<String, dynamic>?;
                  final List<dynamic> connectedList = myData?['connections'] ?? [];

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').where('connections', arrayContains: myUid).snapshots(),
                    builder: (context, connectorSnap) {
                      final connectorCount = connectorSnap.data?.docs.length ?? 0;

                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openConnectionsModal(true, connectedList, myUid),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${connectedList.length}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryNeon),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Connected', style: TextStyle(color: kTextSubtle, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openConnectionsModal(false, connectedList, myUid),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$connectorCount',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAccentPink),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Connectors', style: TextStyle(color: kTextSubtle, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))
                  ],
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  activeColor: kPrimaryNeon,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kLightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(isPrivateAccount ? Icons.lock_rounded : Icons.public_rounded, color: kDarkSurface, size: 22),
                  ),
                  title: const Text('Private Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDarkSurface)),
                  subtitle: Text(
                    isPrivateAccount ? 'Only mutual connections can chat & view content' : 'Anyone connected can message you',
                    style: const TextStyle(color: kTextSubtle, fontSize: 12),
                  ),
                  value: isPrivateAccount,
                  onChanged: _togglePrivacy,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    foregroundColor: kDarkSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _openEditProfileSheet,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile & Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: kLightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => profileTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: profileTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: profileTab == 0
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Reels',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: profileTab == 0 ? kDarkSurface : kTextSubtle,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => profileTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: profileTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: profileTab == 1
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Posts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: profileTab == 1 ? kDarkSurface : kTextSubtle,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feed_posts')
                    .where('uid', isEqualTo: myUid)
                    .where('type', isEqualTo: profileTab == 0 ? 'reel' : 'post')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, gridSnap) {
                  if (gridSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: kPrimaryNeon)));
                  }

                  final myPosts = gridSnap.data?.docs ?? [];
                  if (myPosts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        profileTab == 0 ? 'No Reels uploaded yet.' : 'No Posts uploaded yet.',
                        style: const TextStyle(color: kTextSubtle, fontSize: 13),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myPosts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, idx) {
                      final item = myPosts[idx].data() as Map<String, dynamic>;
                      final String videoUrl = item['videoUrl'] ?? '';
                      final String mediaBase64 = item['mediaData'] ?? '';
                      final String caption = item['caption'] ?? '';

                      if (profileTab == 0) {
                        return GestureDetector(
                          onTap: () {
                            if (videoUrl.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SingleReelScreen(
                                    videoUrl: videoUrl,
                                    caption: caption,
                                    creatorName: username.isNotEmpty ? username : 'me',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: kDarkSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  right: 6,
                                  child: Text(
                                    caption.isNotEmpty ? caption : 'Reel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          if (mediaBase64.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FullImageViewScreen(imageData: mediaBase64)),
                            );
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: mediaBase64.isNotEmpty
                              ? Image.memory(base64Decode(mediaBase64), fit: BoxFit.cover)
                              : Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// PUBLIC VISITOR PROFILE SCREEN (FOR OTHER USERS)
// ==================================================

class UserPublicProfileScreen extends StatefulWidget {
  final String targetUid;
  final String targetName;
  final String targetUsername;
  final String targetPhoto;
  final String targetBio;

  const UserPublicProfileScreen({
    Key? key,
    required this.targetUid,
    required this.targetName,
    required this.targetUsername,
    required this.targetPhoto,
    required this.targetBio,
  }) : super(key: key);

  @override
  State<UserPublicProfileScreen> createState() => _UserPublicProfileScreenState();
}

class _UserPublicProfileScreenState extends State<UserPublicProfileScreen> {
  int tabIndex = 0; // 0 = Reels, 1 = Posts

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.targetUsername}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildUserAvatar(
              context: context,
              photoBase64: widget.targetPhoto,
              name: widget.targetName,
              username: widget.targetUsername,
              bio: widget.targetBio,
              targetUid: widget.targetUid,
              radius: 54,
              enablePreview: false,
            ),
            const SizedBox(height: 14),
            Text(widget.targetName.isNotEmpty ? widget.targetName : '@${widget.targetUsername}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkSurface)),
            const SizedBox(height: 4),
            Text(widget.targetBio.isNotEmpty ? widget.targetBio : 'Avatar Member', textAlign: TextAlign.center, style: const TextStyle(color: kTextSubtle, fontSize: 13)),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: kLightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: tabIndex == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: tabIndex == 0
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Reels',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tabIndex == 0 ? kDarkSurface : kTextSubtle,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => tabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: tabIndex == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: tabIndex == 1
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Posts',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tabIndex == 1 ? kDarkSurface : kTextSubtle,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feed_posts')
                  .where('uid', isEqualTo: widget.targetUid)
                  .where('type', isEqualTo: tabIndex == 0 ? 'reel' : 'post')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, gridSnap) {
                if (gridSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: kPrimaryNeon)));
                }

                final userPosts = gridSnap.data?.docs ?? [];
                if (userPosts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      tabIndex == 0 ? 'No Reels uploaded yet.' : 'No Posts uploaded yet.',
                      style: const TextStyle(color: kTextSubtle, fontSize: 13),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userPosts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, idx) {
                    final item = userPosts[idx].data() as Map<String, dynamic>;
                    final String videoUrl = item['videoUrl'] ?? '';
                    final String mediaBase64 = item['mediaData'] ?? '';
                    final String caption = item['caption'] ?? '';

                    if (tabIndex == 0) {
                      return GestureDetector(
                        onTap: () {
                          if (videoUrl.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SingleReelScreen(
                                  videoUrl: videoUrl,
                                  caption: caption,
                                  creatorName: widget.targetUsername,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: kDarkSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                              Positioned(
                                bottom: 6,
                                left: 6,
                                right: 6,
                                child: Text(
                                  caption.isNotEmpty ? caption : 'Reel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        if (mediaBase64.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FullImageViewScreen(imageData: mediaBase64)),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: mediaBase64.isNotEmpty
                            ? Image.memory(base64Decode(mediaBase64), fit: BoxFit.cover)
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
