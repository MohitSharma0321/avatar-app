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

  await AppLanguage.loadSavedLanguage();
  runApp(const AvatarApp());
}

// ==================================================
// GLOBAL MULTILINGUAL TRANSLATION ENGINE (ALL 15 LANGUAGES)
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

  static Future<void> loadSavedLanguage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/avatar_selected_language.txt');
      if (await file.exists()) {
        final saved = (await file.readAsString()).trim();
        final exists = supportedLanguages.any((language) => language['name'] == saved);
        if (exists) currentLang.value = saved;
      }
    } catch (e) {
      debugPrint('Language load error: $e');
    }
  }

  static Future<void> saveLanguage(String language) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/avatar_selected_language.txt');
      await file.writeAsString(language, flush: true);
    } catch (e) {
      debugPrint('Language save error: $e');
    }
  }

  static const Map<String, Map<String, String>> dictionary = {
    'English': {
      'home': 'Home', 'radar': 'Radar', 'post': 'Post', 'hub': 'Hub', 'echoes': 'Echoes', 'identity': 'Identity',
      'select_realm': 'SELECT REALM DIMENSION', 'share_hint': 'Share your supernatural encounter, dream, or myth...',
      'voice_echo': 'Voice Frequency Echo (+2 Pts)', 'voice_tap': 'Tap mic to capture paranormal audio frequency',
      'voice_captured': 'Voice Captured! Choose Modulator filter below.', 'filters_title': '1-TAP REAL-TIME VOICE FILTERS (PREVIEW):',
      'broadcast_btn': 'BROADCAST TRANSMISSION (+2 PTS)', 'transmitting_audio': 'Transmitting Echo...',
      'witnessed': 'Witnessed', 'deciphered': 'Deciphered', 'self_witness': 'Self Witness', 'plus_witness': '+1 Witness',
      'sponsored': 'Sponsored', 'featured': 'Featured Transmission', 'search_lang': 'Search language...', 'select_lang': 'Select Global Language',
      'online': 'Online', 'offline': 'Offline', 'typing': 'typing...', 'delete_me': 'Delete for Me', 'delete_everyone': 'Delete for Everyone',
      'unsend': 'Unsend Message', 'pin_chat': 'Pin Conversation', 'unpin_chat': 'Unpin Conversation', 'share_link': 'Share with App Link', 'share_text': 'Share Text Only',
      'profile_locked': 'Profile details unlock after 3 days of frequency connection', 'snap_feed': '24H AI SNAP EXPLORER FEED',
      'snap_creator': '24-HOUR AI SNAP CREATOR', 'snap_hint': 'Type your deepest thought, mystery or quote...',
      'generating_pic': 'AI is turning your thought into visual art (Under 60s)...', 'done_pic': 'DONE (GENERATE AI PIC)',
      'upload_snap': 'UPLOAD SNAP (LIVE FOR 24H)', 'expires_in': 'Expires automatically in 24h',
      'all': 'All', 'horror': 'Horror', 'ancient_gods': 'Ancient Gods', 'cyber_3050': 'Cyber 3050', 'dreams': 'Dreams',
      'scan_radar': 'Scanning for Multiverse Frequencies in Orbit', 'send_invite': 'SEND INVITATION (+3 PTS)',
      'creator_stories': 'Creator Stories & News', 'daily_questions': 'Daily 20 Questions (8 PM)', 'publish_lore': 'PUBLISH LORE',
      'solve_btn': 'ANSWER SOLUTION', 'solved_tag': 'SOLVED (8 PM SPOTLIGHT)', 'pending_tag': 'PENDING ORACLE',
      'ai_friend_title': 'Avatar Friend (AI Companion)', 'ai_friend_sub': 'Multilingual AI Oracle • Always Online',
      'active_perks': 'ACTIVE PERKS & ARTIFACTS', 'artifact_vault': 'ARTIFACT VAULT (TAP REALM TO OPEN)',
      'no_transmissions': 'No transmissions in this dimension yet.', 'create_snap_banner': 'Create 24H AI Multiverse Snap (+)',
    },
    'Hindi': {
      'home': 'होम', 'radar': 'रडार', 'post': 'पोस्ट', 'hub': 'हब', 'echoes': 'इकोस', 'identity': 'पहचान',
      'select_realm': 'आयाम (डाइमेंशन) चुनें', 'share_hint': 'अपना अलौकिक अनुभव, सपना या विचार यहाँ लिखें...',
      'voice_echo': 'ध्वनि तरंग इको (+2 अंक)', 'voice_tap': 'आवाज़ रिकॉर्ड करने के लिए माइक दबाएं',
      'voice_captured': 'आवाज़ रिकॉर्ड हो गई! नीचे दिए गए वॉइस फ़िल्टर चुनें।', 'filters_title': 'वॉइस मॉड्यूलेशन फ़िल्टर (प्रीव्यू):',
      'broadcast_btn': 'पोस्ट प्रसारित करें (+2 अंक)', 'transmitting_audio': 'ध्वनि प्रसारित हो रही है...',
      'witnessed': 'देखा गया', 'deciphered': 'डिकोड किया गया', 'self_witness': 'स्वयं साक्षी', 'plus_witness': '+1 साक्षी',
      'sponsored': 'प्रायोजित', 'featured': 'विशेष ट्रांसमिशन', 'search_lang': 'भाषा खोजें...', 'select_lang': 'भाषा चुनें',
      'online': 'ऑनलाइन', 'offline': 'ऑफ़लाइन', 'typing': 'टाइप कर रहे हैं...', 'delete_me': 'मेरे लिए हटाएं', 'delete_everyone': 'सबके लिए हटाएं',
      'unsend': 'मैसेज अनसेंड करें', 'pin_chat': 'चैट पिन करें', 'unpin_chat': 'चैट अनपिन करें', 'share_link': 'ऐप लिंक के साथ शेयर करें', 'share_text': 'सिर्फ टेक्स्ट शेयर करें',
      'profile_locked': '3 दिन की बातचीत के बाद प्रोफाइल अनलॉक होगी', 'snap_feed': '24 घंटे का AI स्नैप फीड',
      'snap_creator': '24-घंटे का AI स्नैप बनाएं', 'snap_hint': 'अपना विचार, रहस्य या संदेश यहाँ लिखें...',
      'generating_pic': 'AI आपके विचार को तस्वीर में बदल रहा है (60s)...', 'done_pic': 'तस्वीर बनाएं (DONE)',
      'upload_snap': 'स्नैप अपलोड करें (24H लाइव)', 'expires_in': '24 घंटे में अपने आप हट जाएगा',
      'all': 'सभी', 'horror': 'हॉरर', 'ancient_gods': 'प्राचीन देवता', 'cyber_3050': 'साइबर 3050', 'dreams': 'सपने',
      'scan_radar': 'ब्रह्मांडीय आवृत्तियों को रडार पर खोजा जा रहा है', 'send_invite': 'निमंत्रण भेजें (+3 अंक)',
      'creator_stories': 'क्रिएटर कथाएं और समाचार', 'daily_questions': 'दैनिक 20 प्रश्न (रात 8 बजे)', 'publish_lore': 'कथा प्रकाशित करें',
      'solve_btn': 'समाधान प्रदान करें', 'solved_tag': 'हल किया गया (रात 8 बजे)', 'pending_tag': 'प्रतीक्षारत प्रश्न',
      'ai_friend_title': 'अवतार मित्र (AI साथी)', 'ai_friend_sub': 'बहुभाषी AI साथी • हमेशा ऑनलाइन',
      'active_perks': 'सक्रिय शक्तियां और अनलॉक तत्व', 'artifact_vault': 'रहस्यमयी वॉल्ट (खोलने के लिए टैप करें)',
      'no_transmissions': 'इस आयाम में अभी कोई ट्रांसमिशन नहीं है।', 'create_snap_banner': '24 घंटे का AI स्नैप बनाएं (+)',
    },
    'Arabic': {
      'home': 'الرئيسية', 'radar': 'الرادار', 'post': 'نشر', 'hub': 'المركز', 'echoes': 'الصدى', 'identity': 'الهوية',
      'select_realm': 'اختر بُعد العوالم', 'share_hint': 'شارك تجربتك الخارقة أو حلمك...',
      'voice_echo': 'صدى تردد الصوت (+2 نقطة)', 'voice_tap': 'اضغط للتسجيل الصوتي',
      'broadcast_btn': 'بث الإرسال (+2 نقطة)', 'witnessed': 'مشاهدات', 'deciphered': 'مفكوك الرموز',
      'all': 'الكل', 'horror': 'رعب', 'ancient_gods': 'آلهة قديمة', 'cyber_3050': 'سايبر 3050', 'dreams': 'أحلام',
      'sponsored': 'برعاية', 'featured': 'إرسال مميز', 'search_lang': 'ابحث عن اللغة...', 'select_lang': 'اختر اللغة العالمية',
      'online': 'متصل', 'offline': 'غير متصل', 'typing': 'يكتب الآن...', 'snap_feed': 'خلاصة لقطات الذكاء الاصطناعي 24 ساعة',
      'snap_creator': 'صانع لقطات الذكاء الاصطناعي', 'create_snap_banner': 'إنشاء لقطة ذكاء اصطناعي 24 ساعة (+)',
      'no_transmissions': 'لا توجد إرسالات في هذا البعد بعد.', 'active_perks': 'الميزات والرموز النشطة', 'artifact_vault': 'خزينة الآثار'
    },
    'Russian': {
      'home': 'Главная', 'radar': 'Радар', 'post': 'Пост', 'hub': 'Хаб', 'echoes': 'Эхо', 'identity': 'Профиль',
      'select_realm': 'ВЫБЕРИТЕ ИЗМЕРЕНИЕ', 'share_hint': 'Поделитесь мистическим опытом или сном...',
      'voice_echo': 'Голосовое Эхо (+2 Очка)', 'voice_tap': 'Нажмите для записи частоты',
      'broadcast_btn': 'ТРАНСЛИРОВАТЬ (+2 ОЧКА)', 'witnessed': 'Замечено', 'deciphered': 'Расшифровано',
      'all': 'Все', 'horror': 'Ужасы', 'ancient_gods': 'Древние Боги', 'cyber_3050': 'Кибер 3050', 'dreams': 'Сны',
      'sponsored': 'Реклама', 'featured': 'Популярная передача', 'search_lang': 'Поиск языка...', 'select_lang': 'Выберите язык',
      'online': 'В сети', 'offline': 'Не в сети', 'typing': 'печатает...', 'snap_feed': '24-часовая AI Лента Снапов',
      'snap_creator': 'СОЗДАТЕЛЬ 24Ч AI СНАПОВ', 'create_snap_banner': 'Создать 24ч AI Снап (+)',
      'no_transmissions': 'В этом измерении пока нет передач.', 'active_perks': 'АКТИВНЫЕ ПЕРКИ И АРТЕФАКТЫ', 'artifact_vault': 'ХРАНИЛИЩЕ АРТЕФАКТОВ'
    },
    'Spanish': {
      'home': 'Inicio', 'radar': 'Radar', 'post': 'Publicar', 'hub': 'Centro', 'echoes': 'Ecos', 'identity': 'Identidad',
      'select_realm': 'SELECCIONAR DIMENSIÓN', 'share_hint': 'Comparte tu encuentro sobrenatural o sueño...',
      'voice_echo': 'Eco de Frecuencia de Voz (+2 Pts)', 'voice_tap': 'Toca el micrófono para grabar',
      'broadcast_btn': 'TRANSMITIR (+2 PTS)', 'witnessed': 'Presenciado', 'deciphered': 'Descifrado',
      'all': 'Todos', 'horror': 'Terror', 'ancient_gods': 'Dioses Antiguos', 'cyber_3050': 'Cyber 3050', 'dreams': 'Sueños',
      'sponsored': 'Patrocinado', 'featured': 'Transmisión destacada', 'search_lang': 'Buscar idioma...', 'select_lang': 'Seleccionar idioma global',
      'online': 'En línea', 'offline': 'Desconectado', 'typing': 'escribiendo...', 'snap_feed': 'FEED DE SNAPS DE IA 24H',
      'snap_creator': 'CREADOR DE SNAPS DE IA 24H', 'create_snap_banner': 'Crear Snap de IA 24H (+)',
      'no_transmissions': 'No hay transmisiones en esta dimensión aún.', 'active_perks': 'VENTAJAS Y ARTEFACTOS ACTIVOS', 'artifact_vault': 'BÓVEDA DE ARTEFACTOS'
    },
    'French': {
      'home':'Accueil','radar':'Radar','post':'Publier','hub':'Centre','echoes':'Échos','identity':'Identité','select_realm':'CHOISIR LA DIMENSION','share_hint':'Partagez votre rencontre surnaturelle, votre rêve ou votre mystère...','voice_echo':'Écho de fréquence vocale (+2 pts)','voice_tap':'Touchez le micro pour enregistrer','voice_captured':'Voix enregistrée ! Choisissez un filtre.','filters_title':'FILTRES VOCAUX EN TEMPS RÉEL :','broadcast_btn':'DIFFUSER LA TRANSMISSION (+2 PTS)','transmitting_audio':'Transmission en cours...','witnessed':'Observé','deciphered':'Déchiffré','self_witness':'Auto-observation','plus_witness':'+1 témoin','sponsored':'Sponsorisé','featured':'Transmission à la une','search_lang':'Rechercher une langue...','select_lang':'Choisir la langue','online':'En ligne','offline':'Hors ligne','typing':'écrit...','delete_me':'Supprimer pour moi','delete_everyone':'Supprimer pour tous','unsend':'Annuler l’envoi','pin_chat':'Épingler la conversation','unpin_chat':'Désépingler la conversation','share_link':'Partager avec le lien de l’application','share_text':'Partager uniquement le texte','profile_locked':'Le profil se débloque après 3 jours de connexion','snap_feed':'FIL 24H DE SNAPS IA','snap_creator':'CRÉATEUR DE SNAPS IA 24H','snap_hint':'Écrivez votre pensée, mystère ou citation...','generating_pic':'L’IA transforme votre pensée en image...','done_pic':'GÉNÉRER L’IMAGE IA','upload_snap':'PUBLIER LE SNAP (24H)','expires_in':'Expire automatiquement dans 24h','all':'Tous','horror':'Horreur','ancient_gods':'Dieux anciens','cyber_3050':'Cyber 3050','dreams':'Rêves','scan_radar':'Recherche des fréquences du multivers','send_invite':'ENVOYER L’INVITATION (+3 PTS)','creator_stories':'Histoires et actualités du créateur','daily_questions':'20 questions quotidiennes (20h)','publish_lore':'PUBLIER LE RÉCIT','solve_btn':'RÉPONDRE','solved_tag':'RÉSOLU','pending_tag':'EN ATTENTE','ai_friend_title':'Avatar Friend (Compagnon IA)','ai_friend_sub':'Oracle IA multilingue • Toujours en ligne','active_perks':'AVANTAGES ET ARTEFACTS ACTIFS','artifact_vault':'COFFRE DES ARTEFACTS','no_transmissions':'Aucune transmission dans cette dimension.','create_snap_banner':'Créer un Snap IA 24H (+)',
    },
    'German': {
      'home':'Start','radar':'Radar','post':'Post','hub':'Zentrum','echoes':'Echos','identity':'Identität','select_realm':'DIMENSION AUSWÄHLEN','share_hint':'Teile dein übernatürliches Erlebnis, deinen Traum oder dein Geheimnis...','voice_echo':'Stimmfrequenz-Echo (+2 Pkt.)','voice_tap':'Tippe auf das Mikrofon zum Aufnehmen','voice_captured':'Stimme aufgenommen! Filter auswählen.','filters_title':'ECHTZEIT-SPRACHFILTER:','broadcast_btn':'ÜBERTRAGUNG SENDEN (+2 PKT.)','transmitting_audio':'Echo wird übertragen...','witnessed':'Bezeugt','deciphered':'Entschlüsselt','self_witness':'Selbst bezeugt','plus_witness':'+1 Zeuge','sponsored':'Gesponsert','featured':'Empfohlene Übertragung','search_lang':'Sprache suchen...','select_lang':'Globale Sprache auswählen','online':'Online','offline':'Offline','typing':'schreibt...','delete_me':'Für mich löschen','delete_everyone':'Für alle löschen','unsend':'Nachricht zurücknehmen','pin_chat':'Chat anheften','unpin_chat':'Chat lösen','share_link':'Mit App-Link teilen','share_text':'Nur Text teilen','profile_locked':'Profildetails werden nach 3 Tagen Verbindung freigeschaltet','snap_feed':'24H KI-SNAP-FEED','snap_creator':'24-STUNDEN-KI-SNAP-CREATOR','snap_hint':'Gib deinen Gedanken, dein Rätsel oder Zitat ein...','generating_pic':'KI verwandelt deinen Gedanken in ein Bild...','done_pic':'KI-BILD ERSTELLEN','upload_snap':'SNAP HOCHLADEN (24H)','expires_in':'Läuft automatisch nach 24h ab','all':'Alle','horror':'Horror','ancient_gods':'Alte Götter','cyber_3050':'Cyber 3050','dreams':'Träume','scan_radar':'Suche nach Multiversum-Frequenzen','send_invite':'EINLADUNG SENDEN (+3 PKT.)','creator_stories':'Creator-Geschichten & News','daily_questions':'Tägliche 20 Fragen (20 Uhr)','publish_lore':'LORE VERÖFFENTLICHEN','solve_btn':'LÖSUNG','solved_tag':'GELÖST','pending_tag':'OFFEN','ai_friend_title':'Avatar Friend (KI-Begleiter)','ai_friend_sub':'Mehrsprachiger KI-Orakel • Immer online','active_perks':'AKTIVE VORTEILE & ARTEFAKTE','artifact_vault':'ARTEFAKT-TRESOR','no_transmissions':'Noch keine Übertragungen in dieser Dimension.','create_snap_banner':'24H KI-Snap erstellen (+)',
    },
    'Japanese': {
      'home':'ホーム','radar':'レーダー','post':'投稿','hub':'ハブ','echoes':'エコー','identity':'アイデンティティ','select_realm':'次元を選択','share_hint':'超常現象、夢、謎めいた体験を共有...','voice_echo':'音声周波数エコー (+2pt)','voice_tap':'マイクをタップして録音','voice_captured':'音声を録音しました！フィルターを選択してください。','filters_title':'リアルタイム音声フィルター:','broadcast_btn':'送信をブロードキャスト (+2pt)','transmitting_audio':'エコーを送信中...','witnessed':'目撃','deciphered':'解読','self_witness':'自分で目撃','plus_witness':'+1目撃','sponsored':'スポンサー','featured':'注目の送信','search_lang':'言語を検索...','select_lang':'グローバル言語を選択','online':'オンライン','offline':'オフライン','typing':'入力中...','delete_me':'自分から削除','delete_everyone':'全員から削除','unsend':'送信取り消し','pin_chat':'会話をピン留め','unpin_chat':'ピン留めを解除','share_link':'アプリリンクと共有','share_text':'テキストのみ共有','profile_locked':'3日間つながるとプロフィールが解除されます','snap_feed':'24時間AIスナップフィード','snap_creator':'24時間AIスナップ作成','snap_hint':'考え、謎、引用を入力...','generating_pic':'AIが考えを画像に変換中...','done_pic':'AI画像を生成','upload_snap':'スナップを投稿 (24H)','expires_in':'24時間後に自動消去','all':'すべて','horror':'ホラー','ancient_gods':'古代の神々','cyber_3050':'サイバー3050','dreams':'夢','scan_radar':'マルチバース周波数を探索中','send_invite':'招待を送信 (+3pt)','creator_stories':'クリエイターの物語とニュース','daily_questions':'毎日の20問 (20時)','publish_lore':'物語を公開','solve_btn':'回答','solved_tag':'解決済み','pending_tag':'保留中','ai_friend_title':'Avatar Friend (AIコンパニオン)','ai_friend_sub':'多言語AIオラクル • 常時オンライン','active_perks':'有効な特典とアーティファクト','artifact_vault':'アーティファクト保管庫','no_transmissions':'この次元にはまだ送信がありません。','create_snap_banner':'24H AIスナップを作成 (+)',
    },
    'Korean': {
      'home':'홈','radar':'레이더','post':'게시','hub':'허브','echoes':'에코','identity':'아이덴티티','select_realm':'차원 선택','share_hint':'초자연적 경험, 꿈 또는 미스터리를 공유하세요...','voice_echo':'음성 주파수 에코 (+2점)','voice_tap':'마이크를 눌러 녹음','voice_captured':'음성이 녹음되었습니다! 필터를 선택하세요.','filters_title':'실시간 음성 필터:','broadcast_btn':'전송 방송 (+2점)','transmitting_audio':'에코 전송 중...','witnessed':'목격','deciphered':'해독','self_witness':'본인 목격','plus_witness':'+1 목격','sponsored':'스폰서','featured':'추천 전송','search_lang':'언어 검색...','select_lang':'글로벌 언어 선택','online':'온라인','offline':'오프라인','typing':'입력 중...','delete_me':'나에게서 삭제','delete_everyone':'모두에게서 삭제','unsend':'메시지 보내기 취소','pin_chat':'대화 고정','unpin_chat':'대화 고정 해제','share_link':'앱 링크와 공유','share_text':'텍스트만 공유','profile_locked':'3일간 연결 후 프로필이 잠금 해제됩니다','snap_feed':'24시간 AI 스냅 피드','snap_creator':'24시간 AI 스냅 생성기','snap_hint':'생각, 미스터리 또는 문구를 입력하세요...','generating_pic':'AI가 생각을 이미지로 변환 중...','done_pic':'AI 이미지 생성','upload_snap':'스냅 게시 (24시간)','expires_in':'24시간 후 자동 만료','all':'전체','horror':'공포','ancient_gods':'고대의 신들','cyber_3050':'사이버 3050','dreams':'꿈','scan_radar':'멀티버스 주파수를 탐색하는 중','send_invite':'초대 보내기 (+3점)','creator_stories':'크리에이터 스토리 및 뉴스','daily_questions':'매일 20개 질문 (오후 8시)','publish_lore':'스토리 게시','solve_btn':'답변','solved_tag':'해결됨','pending_tag':'대기 중','ai_friend_title':'Avatar Friend (AI 동반자)','ai_friend_sub':'다국어 AI 오라클 • 항상 온라인','active_perks':'활성 혜택 및 아티팩트','artifact_vault':'아티팩트 보관함','no_transmissions':'이 차원에는 아직 전송이 없습니다.','create_snap_banner':'24시간 AI 스냅 만들기 (+)',
    },
    'Portuguese': {
      'home':'Início','radar':'Radar','post':'Publicar','hub':'Central','echoes':'Ecos','identity':'Identidade','select_realm':'SELECIONE A DIMENSÃO','share_hint':'Compartilhe seu encontro sobrenatural, sonho ou mistério...','voice_echo':'Eco de Frequência de Voz (+2 pts)','voice_tap':'Toque no microfone para gravar','voice_captured':'Voz capturada! Escolha um filtro.','filters_title':'FILTROS DE VOZ EM TEMPO REAL:','broadcast_btn':'TRANSMITIR (+2 PTS)','transmitting_audio':'Transmitindo eco...','witnessed':'Testemunhado','deciphered':'Decifrado','self_witness':'Auto testemunho','plus_witness':'+1 testemunha','sponsored':'Patrocinado','featured':'Transmissão em destaque','search_lang':'Pesquisar idioma...','select_lang':'Selecionar idioma global','online':'Online','offline':'Offline','typing':'digitando...','delete_me':'Excluir para mim','delete_everyone':'Excluir para todos','unsend':'Cancelar envio','pin_chat':'Fixar conversa','unpin_chat':'Desafixar conversa','share_link':'Compartilhar com link do app','share_text':'Compartilhar apenas texto','profile_locked':'Detalhes do perfil são liberados após 3 dias de conexão','snap_feed':'FEED DE SNAPS DE IA 24H','snap_creator':'CRIADOR DE SNAPS DE IA 24H','snap_hint':'Digite seu pensamento, mistério ou frase...','generating_pic':'A IA está transformando seu pensamento em arte...','done_pic':'GERAR IMAGEM DE IA','upload_snap':'PUBLICAR SNAP (24H)','expires_in':'Expira automaticamente em 24h','all':'Todos','horror':'Terror','ancient_gods':'Deuses Antigos','cyber_3050':'Cyber 3050','dreams':'Sonhos','scan_radar':'Procurando frequências do multiverso','send_invite':'ENVIAR CONVITE (+3 PTS)','creator_stories':'Histórias e notícias do criador','daily_questions':'20 perguntas diárias (20h)','publish_lore':'PUBLICAR LORE','solve_btn':'RESPONDER','solved_tag':'RESOLVIDO','pending_tag':'PENDENTE','ai_friend_title':'Avatar Friend (Companheiro IA)','ai_friend_sub':'Oráculo IA multilíngue • Sempre online','active_perks':'VANTAGENS E ARTEFATOS ATIVOS','artifact_vault':'COFRE DE ARTEFATOS','no_transmissions':'Ainda não há transmissões nesta dimensão.','create_snap_banner':'Criar Snap de IA 24H (+)',
    },
    'Bengali': {
      'home':'হোম','radar':'রাডার','post':'পোস্ট','hub':'হাব','echoes':'ইকো','identity':'পরিচয়','select_realm':'ডাইমেনশন নির্বাচন করুন','share_hint':'আপনার অতিপ্রাকৃত অভিজ্ঞতা, স্বপ্ন বা রহস্য শেয়ার করুন...','voice_echo':'ভয়েস ফ্রিকোয়েন্সি ইকো (+2 পয়েন্ট)','voice_tap':'রেকর্ড করতে মাইক্রোফোন চাপুন','voice_captured':'ভয়েস রেকর্ড হয়েছে! ফিল্টার বেছে নিন।','filters_title':'রিয়েল-টাইম ভয়েস ফিল্টার:','broadcast_btn':'ট্রান্সমিশন সম্প্রচার (+2 পয়েন্ট)','transmitting_audio':'ইকো পাঠানো হচ্ছে...','witnessed':'দেখেছেন','deciphered':'ডিকোড হয়েছে','self_witness':'নিজে দেখেছেন','plus_witness':'+1 সাক্ষী','sponsored':'স্পনসরড','featured':'বিশেষ ট্রান্সমিশন','search_lang':'ভাষা খুঁজুন...','select_lang':'গ্লোবাল ভাষা নির্বাচন','online':'অনলাইন','offline':'অফলাইন','typing':'টাইপ করছেন...','delete_me':'আমার জন্য মুছুন','delete_everyone':'সবার জন্য মুছুন','unsend':'মেসেজ আনসেন্ড','pin_chat':'চ্যাট পিন করুন','unpin_chat':'চ্যাট আনপিন করুন','share_link':'অ্যাপ লিংকসহ শেয়ার','share_text':'শুধু টেক্সট শেয়ার','profile_locked':'৩ দিন সংযোগের পর প্রোফাইলের তথ্য খুলবে','snap_feed':'২৪ ঘণ্টার AI স্ন্যাপ ফিড','snap_creator':'২৪ ঘণ্টার AI স্ন্যাপ ক্রিয়েটর','snap_hint':'আপনার ভাবনা, রহস্য বা উদ্ধৃতি লিখুন...','generating_pic':'AI আপনার ভাবনাকে ছবিতে রূপ দিচ্ছে...','done_pic':'AI ছবি তৈরি করুন','upload_snap':'স্ন্যাপ প্রকাশ করুন (২৪ ঘণ্টা)','expires_in':'২৪ ঘণ্টায় স্বয়ংক্রিয়ভাবে শেষ হবে','all':'সব','horror':'হরর','ancient_gods':'প্রাচীন দেবতা','cyber_3050':'সাইবার ৩০৫০','dreams':'স্বপ্ন','scan_radar':'মাল্টিভার্স ফ্রিকোয়েন্সি খোঁজা হচ্ছে','send_invite':'আমন্ত্রণ পাঠান (+৩ পয়েন্ট)','creator_stories':'ক্রিয়েটর গল্প ও খবর','daily_questions':'দৈনিক ২০ প্রশ্ন (রাত ৮টা)','publish_lore':'লোর প্রকাশ করুন','solve_btn':'উত্তর দিন','solved_tag':'সমাধান হয়েছে','pending_tag':'অপেক্ষমাণ','ai_friend_title':'Avatar Friend (AI সঙ্গী)','ai_friend_sub':'বহুভাষী AI ওরাকল • সবসময় অনলাইন','active_perks':'সক্রিয় সুবিধা ও আর্টিফ্যাক্ট','artifact_vault':'আর্টিফ্যাক্ট ভল্ট','no_transmissions':'এই ডাইমেনশনে এখনও কোনো ট্রান্সমিশন নেই।','create_snap_banner':'২৪ ঘণ্টার AI স্ন্যাপ তৈরি করুন (+)',
    },
    'Punjabi': {
      'home':'ਹੋਮ','radar':'ਰਡਾਰ','post':'ਪੋਸਟ','hub':'ਹੱਬ','echoes':'ਏਕੋਜ਼','identity':'ਪਛਾਣ','select_realm':'ਡਾਈਮੇਂਸ਼ਨ ਚੁਣੋ','share_hint':'ਆਪਣਾ ਅਲੌਕਿਕ ਤਜਰਬਾ, ਸੁਪਨਾ ਜਾਂ ਰਹੱਸ ਸਾਂਝਾ ਕਰੋ...','voice_echo':'ਵੌਇਸ ਫ੍ਰਿਕਵੈਂਸੀ ਏਕੋ (+2 ਅੰਕ)','voice_tap':'ਰਿਕਾਰਡ ਕਰਨ ਲਈ ਮਾਈਕ ਦਬਾਓ','voice_captured':'ਆਵਾਜ਼ ਰਿਕਾਰਡ ਹੋ ਗਈ! ਫਿਲਟਰ ਚੁਣੋ।','filters_title':'ਰੀਅਲ-ਟਾਈਮ ਵੌਇਸ ਫਿਲਟਰ:','broadcast_btn':'ਟ੍ਰਾਂਸਮਿਸ਼ਨ ਪ੍ਰਸਾਰਿਤ ਕਰੋ (+2 ਅੰਕ)','transmitting_audio':'ਏਕੋ ਭੇਜਿਆ ਜਾ ਰਿਹਾ ਹੈ...','witnessed':'ਦੇਖਿਆ','deciphered':'ਡਿਕੋਡ ਕੀਤਾ','self_witness':'ਆਪ ਦੇਖਿਆ','plus_witness':'+1 ਗਵਾਹ','sponsored':'ਪ੍ਰਾਯੋਜਿਤ','featured':'ਖਾਸ ਟ੍ਰਾਂਸਮਿਸ਼ਨ','search_lang':'ਭਾਸ਼ਾ ਖੋਜੋ...','select_lang':'ਗਲੋਬਲ ਭਾਸ਼ਾ ਚੁਣੋ','online':'ਆਨਲਾਈਨ','offline':'ਆਫਲਾਈਨ','typing':'ਟਾਈਪ ਕਰ ਰਿਹਾ ਹੈ...','delete_me':'ਮੇਰੇ ਲਈ ਮਿਟਾਓ','delete_everyone':'ਸਭ ਲਈ ਮਿਟਾਓ','unsend':'ਮੈਸੇਜ ਵਾਪਸ ਲਓ','pin_chat':'ਚੈਟ ਪਿੰਨ ਕਰੋ','unpin_chat':'ਚੈਟ ਅਨਪਿੰਨ ਕਰੋ','share_link':'ਐਪ ਲਿੰਕ ਨਾਲ ਸਾਂਝਾ ਕਰੋ','share_text':'ਸਿਰਫ਼ ਟੈਕਸਟ ਸਾਂਝਾ ਕਰੋ','profile_locked':'3 ਦਿਨਾਂ ਦੀ ਕਨੈਕਸ਼ਨ ਤੋਂ ਬਾਅਦ ਪ੍ਰੋਫਾਈਲ ਖੁੱਲ੍ਹੇਗੀ','snap_feed':'24 ਘੰਟੇ AI ਸਨੈਪ ਫੀਡ','snap_creator':'24 ਘੰਟੇ AI ਸਨੈਪ ਬਣਾਉਣ ਵਾਲਾ','snap_hint':'ਆਪਣਾ ਵਿਚਾਰ, ਰਹੱਸ ਜਾਂ ਕੋਟ ਲਿਖੋ...','generating_pic':'AI ਤੁਹਾਡੇ ਵਿਚਾਰ ਨੂੰ ਤਸਵੀਰ ਵਿੱਚ ਬਦਲ ਰਿਹਾ ਹੈ...','done_pic':'AI ਤਸਵੀਰ ਬਣਾਓ','upload_snap':'ਸਨੈਪ ਪੋਸਟ ਕਰੋ (24 ਘੰਟੇ)','expires_in':'24 ਘੰਟਿਆਂ ਬਾਅਦ ਆਪਣੇ ਆਪ ਖਤਮ','all':'ਸਾਰੇ','horror':'ਹੌਰਰ','ancient_gods':'ਪੁਰਾਤਨ ਦੇਵਤੇ','cyber_3050':'ਸਾਈਬਰ 3050','dreams':'ਸੁਪਨੇ','scan_radar':'ਮਲਟੀਵਰਸ ਫ੍ਰਿਕਵੈਂਸੀ ਖੋਜ ਰਹੇ ਹਾਂ','send_invite':'ਸੱਦਾ ਭੇਜੋ (+3 ਅੰਕ)','creator_stories':'ਕ੍ਰੀਏਟਰ ਕਹਾਣੀਆਂ ਅਤੇ ਖ਼ਬਰਾਂ','daily_questions':'ਰੋਜ਼ਾਨਾ 20 ਸਵਾਲ (ਰਾਤ 8 ਵਜੇ)','publish_lore':'ਲੋਰ ਪ੍ਰਕਾਸ਼ਿਤ ਕਰੋ','solve_btn':'ਜਵਾਬ ਦਿਓ','solved_tag':'ਹੱਲ ਹੋਇਆ','pending_tag':'ਬਾਕੀ','ai_friend_title':'Avatar Friend (AI ਸਾਥੀ)','ai_friend_sub':'ਬਹੁਭਾਸ਼ੀ AI ਓਰੇਕਲ • ਹਮੇਸ਼ਾ ਆਨਲਾਈਨ','active_perks':'ਸਰਗਰਮ ਫਾਇਦੇ ਅਤੇ ਆਰਟੀਫੈਕਟ','artifact_vault':'ਆਰਟੀਫੈਕਟ ਵਾਲਟ','no_transmissions':'ਇਸ ਡਾਈਮੇਂਸ਼ਨ ਵਿੱਚ ਹਾਲੇ ਕੋਈ ਟ੍ਰਾਂਸਮਿਸ਼ਨ ਨਹੀਂ।','create_snap_banner':'24 ਘੰਟੇ ਦਾ AI ਸਨੈਪ ਬਣਾਓ (+)',
    },
    'Tamil': {
      'home':'முகப்பு','radar':'ரேடார்','post':'பதிவு','hub':'மையம்','echoes':'எதிரொலிகள்','identity':'அடையாளம்','select_realm':'பரிமாணத்தைத் தேர்ந்தெடுக்கவும்','share_hint':'உங்கள் அமானுஷ்ய அனுபவம், கனவு அல்லது மர்மத்தைப் பகிருங்கள்...','voice_echo':'குரல் அதிர்வெண் எதிரொலி (+2 புள்ளிகள்)','voice_tap':'பதிவு செய்ய மைக்கைத் தட்டவும்','voice_captured':'குரல் பதிவு செய்யப்பட்டது! வடிகட்டியைத் தேர்ந்தெடுக்கவும்.','filters_title':'நிகழ்நேர குரல் வடிகட்டிகள்:','broadcast_btn':'ஒலிபரப்பு அனுப்பவும் (+2 புள்ளிகள்)','transmitting_audio':'எதிரொலி அனுப்பப்படுகிறது...','witnessed':'பார்த்தவர்கள்','deciphered':'விளக்கப்பட்டது','self_witness':'சுய பார்வை','plus_witness':'+1 பார்வையாளர்','sponsored':'ஸ்பான்சர்','featured':'சிறப்பு ஒலிபரப்பு','search_lang':'மொழியைத் தேடுங்கள்...','select_lang':'உலக மொழியைத் தேர்ந்தெடுக்கவும்','online':'ஆன்லைன்','offline':'ஆஃப்லைன்','typing':'தட்டச்சு செய்கிறார்...','delete_me':'எனக்காக நீக்கு','delete_everyone':'அனைவருக்கும் நீக்கு','unsend':'செய்தியை அனுப்பாதே','pin_chat':'உரையாடலைப் பின் செய்','unpin_chat':'பின்னை நீக்கு','share_link':'ஆப் இணைப்புடன் பகிர்','share_text':'உரை மட்டும் பகிர்','profile_locked':'3 நாட்கள் இணைந்த பிறகு சுயவிவரம் திறக்கும்','snap_feed':'24 மணி AI ஸ்னாப் ஃபீட்','snap_creator':'24 மணி AI ஸ்னாப் உருவாக்கி','snap_hint':'உங்கள் எண்ணம், மர்மம் அல்லது மேற்கோளை உள்ளிடவும்...','generating_pic':'AI உங்கள் எண்ணத்தை படமாக மாற்றுகிறது...','done_pic':'AI படத்தை உருவாக்கு','upload_snap':'ஸ்னாப்பை வெளியிடு (24 மணி)','expires_in':'24 மணி நேரத்தில் தானாக முடியும்','all':'அனைத்தும்','horror':'திகில்','ancient_gods':'பண்டைய தெய்வங்கள்','cyber_3050':'சைபர் 3050','dreams':'கனவுகள்','scan_radar':'மல்டிவெர்ஸ் அதிர்வெண்களைத் தேடுகிறது','send_invite':'அழைப்பை அனுப்பு (+3 புள்ளிகள்)','creator_stories':'உருவாக்குநர் கதைகள் மற்றும் செய்திகள்','daily_questions':'தினசரி 20 கேள்விகள் (இரவு 8 மணி)','publish_lore':'கதையை வெளியிடு','solve_btn':'பதில் அளி','solved_tag':'தீர்க்கப்பட்டது','pending_tag':'நிலுவையில்','ai_friend_title':'Avatar Friend (AI துணை)','ai_friend_sub':'பலமொழி AI ஓராக்கிள் • எப்போதும் ஆன்லைன்','active_perks':'செயலில் உள்ள சலுகைகள் மற்றும் கலைப்பொருட்கள்','artifact_vault':'கலைப்பொருள் களஞ்சியம்','no_transmissions':'இந்த பரிமாணத்தில் இன்னும் எந்த ஒலிபரப்பும் இல்லை.','create_snap_banner':'24 மணி AI ஸ்னாப் உருவாக்கு (+)',
    },
    'Telugu': {
      'home':'హోమ్','radar':'రాడార్','post':'పోస్ట్','hub':'హబ్','echoes':'ఎకోస్','identity':'గుర్తింపు','select_realm':'డైమెన్షన్ ఎంచుకోండి','share_hint':'మీ అతీంద్రియ అనుభవం, కల లేదా రహస్యాన్ని పంచుకోండి...','voice_echo':'వాయిస్ ఫ్రీక్వెన్సీ ఎకో (+2 పాయింట్లు)','voice_tap':'రికార్డ్ చేయడానికి మైక్ నొక్కండి','voice_captured':'వాయిస్ రికార్డ్ అయింది! ఫిల్టర్ ఎంచుకోండి.','filters_title':'రియల్-టైమ్ వాయిస్ ఫిల్టర్లు:','broadcast_btn':'ట్రాన్స్‌మిషన్ ప్రసారం (+2 పాయింట్లు)','transmitting_audio':'ఎకో పంపబడుతోంది...','witnessed':'చూసినవారు','deciphered':'డీకోడ్ అయింది','self_witness':'స్వయంగా చూశారు','plus_witness':'+1 సాక్షి','sponsored':'స్పాన్సర్డ్','featured':'ప్రత్యేక ట్రాన్స్‌మిషన్','search_lang':'భాషను వెతకండి...','select_lang':'గ్లోబల్ భాషను ఎంచుకోండి','online':'ఆన్‌లైన్','offline':'ఆఫ్‌లైన్','typing':'టైప్ చేస్తున్నారు...','delete_me':'నా కోసం తొలగించు','delete_everyone':'అందరికీ తొలగించు','unsend':'మెసేజ్ పంపడం రద్దు','pin_chat':'చాట్ పిన్ చేయి','unpin_chat':'చాట్ అన్‌పిన్ చేయి','share_link':'యాప్ లింక్‌తో షేర్ చేయి','share_text':'టెక్స్ట్ మాత్రమే షేర్ చేయి','profile_locked':'3 రోజుల కనెక్షన్ తర్వాత ప్రొఫైల్ వివరాలు తెరవబడతాయి','snap_feed':'24 గంటల AI స్నాప్ ఫీడ్','snap_creator':'24 గంటల AI స్నాప్ క్రియేటర్','snap_hint':'మీ ఆలోచన, రహస్యం లేదా కోట్ టైప్ చేయండి...','generating_pic':'AI మీ ఆలోచనను చిత్రంగా మార్చుతోంది...','done_pic':'AI చిత్రాన్ని రూపొందించు','upload_snap':'స్నాప్ ప్రచురించు (24 గంటలు)','expires_in':'24 గంటల తర్వాత ఆటోమేటిక్‌గా ముగుస్తుంది','all':'అన్నీ','horror':'హారర్','ancient_gods':'ప్రాచీన దేవతలు','cyber_3050':'సైబర్ 3050','dreams':'కలలు','scan_radar':'మల్టీవర్స్ ఫ్రీక్వెన్సీల కోసం వెతుకుతోంది','send_invite':'ఆహ్వానం పంపండి (+3 పాయింట్లు)','creator_stories':'క్రియేటర్ కథలు & వార్తలు','daily_questions':'రోజువారీ 20 ప్రశ్నలు (రాత్రి 8)','publish_lore':'లోర్ ప్రచురించండి','solve_btn':'సమాధానం ఇవ్వండి','solved_tag':'పరిష్కరించబడింది','pending_tag':'పెండింగ్','ai_friend_title':'Avatar Friend (AI సహచరుడు)','ai_friend_sub':'బహుభాషా AI ఒరాకిల్ • ఎల్లప్పుడూ ఆన్‌లైన్','active_perks':'యాక్టివ్ పెర్క్స్ & ఆర్టిఫాక్ట్స్','artifact_vault':'ఆర్టిఫాక్ట్ వాల్ట్','no_transmissions':'ఈ డైమెన్షన్‌లో ఇంకా ట్రాన్స్‌మిషన్‌లు లేవు.','create_snap_banner':'24 గంటల AI స్నాప్ సృష్టించండి (+)',
    },
    'Marathi': {
      'home':'होम','radar':'रडार','post':'पोस्ट','hub':'हब','echoes':'प्रतिध्वनी','identity':'ओळख','select_realm':'डायमेन्शन निवडा','share_hint':'तुमचा अलौकिक अनुभव, स्वप्न किंवा रहस्य शेअर करा...','voice_echo':'व्हॉइस फ्रिक्वेन्सी इको (+2 गुण)','voice_tap':'रेकॉर्ड करण्यासाठी माइक दाबा','voice_captured':'आवाज रेकॉर्ड झाला! फिल्टर निवडा.','filters_title':'रिअल-टाइम व्हॉइस फिल्टर्स:','broadcast_btn':'ट्रान्समिशन प्रसारित करा (+2 गुण)','transmitting_audio':'इको पाठवत आहे...','witnessed':'पाहिले','deciphered':'उलगडले','self_witness':'स्वतः पाहिले','plus_witness':'+1 साक्षीदार','sponsored':'प्रायोजित','featured':'वैशिष्ट्यपूर्ण ट्रान्समिशन','search_lang':'भाषा शोधा...','select_lang':'ग्लोबल भाषा निवडा','online':'ऑनलाइन','offline':'ऑफलाइन','typing':'टाइप करत आहे...','delete_me':'माझ्यासाठी हटवा','delete_everyone':'सर्वांसाठी हटवा','unsend':'मेसेज अनसेंड करा','pin_chat':'चॅट पिन करा','unpin_chat':'चॅट अनपिन करा','share_link':'अॅप लिंकसह शेअर करा','share_text':'फक्त मजकूर शेअर करा','profile_locked':'3 दिवसांच्या कनेक्शननंतर प्रोफाइल तपशील उघडतील','snap_feed':'24 तास AI स्नॅप फीड','snap_creator':'24 तास AI स्नॅप क्रिएटर','snap_hint':'तुमचा विचार, रहस्य किंवा कोट लिहा...','generating_pic':'AI तुमचा विचार चित्रात बदलत आहे...','done_pic':'AI चित्र तयार करा','upload_snap':'स्नॅप प्रकाशित करा (24 तास)','expires_in':'24 तासांनी आपोआप संपेल','all':'सर्व','horror':'हॉरर','ancient_gods':'प्राचीन देव','cyber_3050':'सायबर 3050','dreams':'स्वप्ने','scan_radar':'मल्टीव्हर्स फ्रिक्वेन्सी शोधत आहे','send_invite':'आमंत्रण पाठवा (+3 गुण)','creator_stories':'क्रिएटर कथा आणि बातम्या','daily_questions':'दररोज 20 प्रश्न (रात्री 8)','publish_lore':'लोर प्रकाशित करा','solve_btn':'उत्तर द्या','solved_tag':'सोडवले','pending_tag':'प्रलंबित','ai_friend_title':'Avatar Friend (AI साथी)','ai_friend_sub':'बहुभाषिक AI ओरॅकल • नेहमी ऑनलाइन','active_perks':'सक्रिय फायदे आणि कलाकृती','artifact_vault':'आर्टिफॅक्ट व्हॉल्ट','no_transmissions':'या डायमेन्शनमध्ये अजून कोणतेही ट्रान्समिशन नाही.','create_snap_banner':'24 तासांचा AI स्नॅप तयार करा (+)',
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
  static const String snapWorkerUrl = 'https://avatar-snap-ai.projectkhurafat.workers.dev/generate';

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
// INSTAGRAM STYLE NATIVE ADVANCED AD WIDGET
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
    _loadNativeAd();
  }

  void _loadNativeAd() {
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
          debugPrint('Native Ad Failed: $error');
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                child: Text(AppLanguage.tr('sponsored'), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(AppLanguage.tr('featured'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all frequency fields.')));
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gateway Error: $e')));
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
                    width: 76, height: 76,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: kNeonPurple.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)], border: Border.all(color: kNeonCyan, width: 2)),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('A V A T A R', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white)),
                  const Text('The Multiverse Network', style: TextStyle(color: kNeonCyan, fontSize: 13, letterSpacing: 2)),
                  const SizedBox(height: 36),
                  if (isSignUp)
                    TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Avatar Name', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.person_outline, color: kNeonPurple))),
                  if (isSignUp) const SizedBox(height: 14),
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Email Frequency', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.alternate_email, color: kNeonPurple))),
                  const SizedBox(height: 14),
                  TextField(controller: _passController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: 'Passkey', hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.lock_outline, color: kNeonPurple))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: isLoading ? null : _handleAuth,
                      child: isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isSignUp ? 'INITIALIZE TRANSMITTER' : 'ENTER DIMENSION', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
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
// NOTIFICATIONS & POINT RULES SCREEN
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
                          const SizedBox(height: 10),
                          Text('Next Goal: ${rankInfo['next']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
// DYNAMIC NAVIGATION HOST (6 TABS WITH REACTIVE TRANSLATION)
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

            return ValueListenableBuilder<String>(
              valueListenable: AppLanguage.currentLang,
              builder: (context, lang, _) {
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
      },
    );
  }
}

// ==================================================
// TAB 1: REALMS FEED SCREEN (WITH IN-FEED NATIVE ADS)
// ==================================================
class RealmsFeedScreen extends StatelessWidget {
  final String selectedRealm;
  final Color accentColor;
  final Function(String) onRealmChange;

  const RealmsFeedScreen({super.key, required this.selectedRealm, required this.accentColor, required this.onRealmChange});

  List<Map<String, dynamic>> _getRealms() => [
    {'name': 'All', 'labelKey': 'all', 'icon': Icons.all_inclusive_rounded, 'color': kNeonPurple},
    {'name': 'Horror', 'labelKey': 'horror', 'icon': Icons.dark_mode_rounded, 'color': kHorrorCrimson},
    {'name': 'Ancient Gods', 'labelKey': 'ancient_gods', 'icon': Icons.temple_hindu_rounded, 'color': kAncientGold},
    {'name': 'Cyber 3050', 'labelKey': 'cyber_3050', 'icon': Icons.memory_rounded, 'color': kNeonCyan},
    {'name': 'Dreams', 'labelKey': 'dreams', 'icon': Icons.cloudy_snowing, 'color': kMistyGreen},
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
                            onTap: () async {
                              final selectedLanguage = item['name']!;
                              AppLanguage.currentLang.value = selectedLanguage;
                              await AppLanguage.saveLanguage(selectedLanguage);
                              if (ctx.mounted) Navigator.pop(ctx);
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
    final realms = _getRealms();

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
                        decoration: const BoxDecoration(color: kHorrorCrimson, shape: BoxShape.circle),
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
                      border: Border.all(color: isSel ? (r['color'] as Color) : Colors.white12, width: isSel ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: CenterAxisAlignment(),
                      children: [
                        Icon(r['icon'] as IconData, color: r['color'] as Color, size: 24),
                        const SizedBox(height: 6),
                        Text(AppLanguage.tr(r['labelKey'] as String), style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.white60)),
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
                        Text(AppLanguage.tr('no_transmissions'), style: const TextStyle(color: Colors.white38)),
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

// ==================================================
// TRANSMISSION CARD (WITH DEVELOPER + USER PURGE CONTROLS)
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

  void _showDeleteDialog(BuildContext context, int createdAt, String authorUid, bool isDev) {
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
            if (isDev) ...[
              ListTile(
                leading: const Icon(Icons.shield_rounded, color: kHorrorCrimson),
                title: const Text('Admin Purge Transmission', style: TextStyle(color: kHorrorCrimson, fontWeight: FontWeight.bold)),
                subtitle: const Text('Developer privilege: Purge immediately with zero penalty.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('transmissions').doc(widget.docId).delete();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ] else if (isWithin24Hours) ...[
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
                subtitle: Text('Transmissions older than 24 hours cannot be purged by explorer.'),
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
          mainAxisSize: MainAxisSize.min,
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

  @override
  Widget build(BuildContext context) {
    final dim = widget.data['dimension'] ?? 'Nexus';
    final voiceFilter = widget.data['voiceFilter'] ?? 'normal';
    final dimColor = _getDimensionColor(dim);
    final witnesses = List<String>.from(widget.data['witnesses'] ?? []);
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid ?? '';
    final isDev = (currentUser?.email?.toLowerCase().trim() == kAdminEmail.toLowerCase().trim());
    final hasWitnessed = witnesses.contains(currentUid);
    final isCreator = (widget.data['uid'] == currentUid);
    final authorUid = widget.data['uid'] ?? '';
    final createdAt = widget.data['createdAt'] ?? 0;
    final content = widget.data['content'] ?? '';
    final creatorName = widget.data['creatorName'] ?? 'Explorer';
    final audioBase64 = widget.data['audioBase64'] ?? '';

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
                        if (isCreator || isDev)
                          IconButton(
                            icon: Icon(isDev && !isCreator ? Icons.admin_panel_settings_rounded : Icons.more_vert, size: 18, color: isDev && !isCreator ? kHorrorCrimson : Colors.white54),
                            onPressed: () => _showDeleteDialog(context, createdAt, authorUid, isDev),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (content.isNotEmpty) Text(content, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
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
                                Text(isPlaying ? AppLanguage.tr('transmitting_audio') : 'Frequency: Modulated ${voiceFilter.toUpperCase()} Echo', style: TextStyle(fontSize: 12, color: isPlaying ? dimColor : Colors.white70, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _toggleWitness(currentUid, dimColor),
                      child: Row(
                        children: [
                          Icon(hasWitnessed ? Icons.visibility_rounded : Icons.visibility_outlined, color: hasWitnessed ? dimColor : Colors.white38, size: 18),
                          const SizedBox(width: 6),
                          Text('${witnesses.length} ${AppLanguage.tr('witnessed')}', style: TextStyle(color: hasWitnessed ? dimColor : Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _openDecipherSheet(context, dimColor),
                      child: Row(
                        children: [
                          const Icon(Icons.comment_outlined, color: Colors.white38, size: 18),
                          const SizedBox(width: 6),
                          Text('${widget.data['decipherCount'] ?? 0} ${AppLanguage.tr('deciphered')}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white38, size: 18), onPressed: () => _openShareOptions(context, content, dim, creatorName)),
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
                      Text(isCreator ? AppLanguage.tr('self_witness') : AppLanguage.tr('plus_witness'), style: TextStyle(color: dimColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent! +3 Resonance Points added.')));
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
        title: Text(AppLanguage.tr('radar').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
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
                  Text(AppLanguage.tr('scan_radar'), style: TextStyle(color: widget.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
                              child: Text(AppLanguage.tr('send_invite'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDev = (currentUser?.email?.toLowerCase().trim() == kAdminEmail.toLowerCase().trim());
    final now = DateTime.now().millisecondsSinceEpoch;

    // Regular users can only post 1 snap per 24 hours
    if (!isDev) {
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
                          Text(AppLanguage.tr('snap_creator'), style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
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
                      hintText: AppLanguage.tr('snap_hint'),
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
                          errorBuilder: (c, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
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
                          Text(AppLanguage.tr('generating_pic'), style: const TextStyle(color: kNeonCyan, fontSize: 12)),
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

                          try {
                            final response = await http.post(
                              Uri.parse(AvatarAIEngine.snapWorkerUrl),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'prompt': 'cinematic surreal multiverse mystic art of: $text, high quality, glowing neon, portrait composition',
                              }),
                            ).timeout(const Duration(seconds: 45));

                            if (response.statusCode != 200) {
                              throw Exception('Cloudflare Worker Error: HTTP ${response.statusCode}');
                            }

                            final data = jsonDecode(response.body) as Map<String, dynamic>;
                            final imageUrl = data['imageUrl']?.toString();

                            if (imageUrl == null || imageUrl.isEmpty) {
                              throw Exception('No valid image URL returned from Cloudflare Worker.');
                            }

                            setModalState(() {
                              generatedImageUrl = imageUrl;
                              isGenerating = false;
                            });
                          } catch (e) {
                            setModalState(() => isGenerating = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cloudflare AI Worker error: $e')),
                              );
                            }
                          }
                        },
                        child: Text(AppLanguage.tr('done_pic'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                            : Text(AppLanguage.tr('upload_snap'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: kNeonCyan),
                          const SizedBox(width: 4),
                          Text(AppLanguage.tr('expires_in'), style: const TextStyle(color: kNeonCyan, fontSize: 11)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _open24hThoughtCreator(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kNeonPurple.withOpacity(0.4), widget.accentColor.withOpacity(0.2)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.accentColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: widget.accentColor, radius: 16, child: const Icon(Icons.auto_awesome, size: 18, color: Colors.black)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(AppLanguage.tr('create_snap_banner'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),

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
                        Text(AppLanguage.tr('snap_feed'), style: const TextStyle(color: kNeonCyan, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
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

            Text(AppLanguage.tr('select_realm'), style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: dimensions.map((d) {
                final isSel = selectedDim == d;
                return ChoiceChip(label: Text(d, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold)), selected: isSel, selectedColor: widget.accentColor, backgroundColor: kCardDark, onSelected: (val) => setState(() => selectedDim = d));
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(controller: _contentController, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: kCardDark, hintText: AppLanguage.tr('share_hint'), hintStyle: const TextStyle(color: Colors.white38), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
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
                          Text(AppLanguage.tr('voice_echo'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(recordedAudioBase64 != null ? AppLanguage.tr('voice_captured') : AppLanguage.tr('voice_tap'), style: TextStyle(color: widget.accentColor, fontSize: 11)),
                        ],
                      ),
                      IconButton(onPressed: _toggleRecording, iconSize: 34, icon: Icon(isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded, color: isRecording ? kHorrorCrimson : (recordedAudioBase64 != null ? kMistyGreen : Colors.white70))),
                    ],
                  ),
                  if (recordedAudioBase64 != null) ...[
                    const Divider(color: Colors.white12, height: 24),
                    Text(AppLanguage.tr('filters_title'), style: const TextStyle(color: kNeonCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                child: isTransmitting ? const CircularProgressIndicator(color: Colors.black) : Text(AppLanguage.tr('broadcast_btn'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// TAB 4: THE ORACLE'S SANCTUM (DEVELOPER CONTROLLED)
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

  void _confirmDeleteDoc(BuildContext context, String collectionName, String docId, String itemType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardDark,
        title: Text('PURGE $itemType', style: const TextStyle(color: kHorrorCrimson, fontWeight: FontWeight.bold, fontSize: 14)),
        content: Text('Permanently remove this $itemType as Developer?', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kHorrorCrimson),
            onPressed: () async {
              await FirebaseFirestore.instance.collection(collectionName).doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$itemType purged.')));
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          tabs: [
            Tab(text: AppLanguage.tr('creator_stories')),
            Tab(text: AppLanguage.tr('daily_questions')),
          ],
        ),
      ),
      floatingActionButton: (isDeveloper && _tabController.index == 0)
          ? FloatingActionButton.extended(
              backgroundColor: kAncientGold,
              onPressed: () => _showPublishStoryDialog(context),
              icon: const Icon(Icons.add, color: Colors.black),
              label: Text(AppLanguage.tr('publish_lore'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
                                  tooltip: 'Copy Story Text',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: content));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chronicle text copied to clipboard!')));
                                  },
                                ),
                                if (isDeveloper)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: kHorrorCrimson),
                                    tooltip: 'Purge Chronicle',
                                    onPressed: () => _confirmDeleteDoc(context, 'developer_broadcasts', docs[i].id, 'Chronicle'),
                                  ),
                              ],
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
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: isAnswered ? kMistyGreen.withOpacity(0.2) : kHorrorCrimson.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                        child: Text(isAnswered ? AppLanguage.tr('solved_tag') : AppLanguage.tr('pending_tag'), style: TextStyle(color: isAnswered ? kMistyGreen : kHorrorCrimson, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                      if (isDeveloper)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: kHorrorCrimson),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _confirmDeleteDoc(context, 'daily_questions', qDocs[i].id, 'Question'),
                                        ),
                                    ],
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
                                    child: Text(AppLanguage.tr('solve_btn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
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
              title: Text(isPinned ? AppLanguage.tr('unpin_chat') : AppLanguage.tr('pin_chat')),
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
      appBar: AppBar(backgroundColor: kVoidBlack, elevation: 0, title: Text(AppLanguage.tr('echoes').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16))),
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
                  title: Text(AppLanguage.tr('ai_friend_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  subtitle: Text(AppLanguage.tr('ai_friend_sub'), style: const TextStyle(color: kMistyGreen, fontSize: 12)),
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
                          subtitle: Text(isOnline ? AppLanguage.tr('online') : AppLanguage.tr('offline'), style: TextStyle(color: isOnline ? kMistyGreen : Colors.white38, fontSize: 12)),
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
        title: Row(
          children: [
            const CircleAvatar(radius: 14, backgroundColor: kNeonCyan, child: Icon(Icons.auto_awesome, size: 14, color: Colors.black)),
            const SizedBox(width: 10),
            Text(AppLanguage.tr('ai_friend_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                Text(isTyping ? AppLanguage.tr('typing') : (isOnline ? AppLanguage.tr('online') : AppLanguage.tr('offline')), style: TextStyle(fontSize: 11, color: isTyping ? kNeonCyan : (isOnline ? kMistyGreen : Colors.white38))),
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
        title: Text(AppLanguage.tr('identity').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
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
                          Text('${AppLanguage.tr('active_perks')} (${perks.length})', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(AppLanguage.tr('artifact_vault'), style: const TextStyle(color: kAncientGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12,
                  children: [
                    _buildArtifactItem(AppLanguage.tr('ancient_gods'), 'Temple Alignments & Lore', kAncientGold, () => onVaultSelect('Ancient Gods')),
                    _buildArtifactItem(AppLanguage.tr('dreams'), 'Lucid Dreams & Paradoxes', kMistyGreen, () => onVaultSelect('Dreams')),
                    _buildArtifactItem(AppLanguage.tr('cyber_3050'), 'Singularity & AI Theories', kNeonCyan, () => onVaultSelect('Cyber 3050')),
                    _buildArtifactItem(AppLanguage.tr('horror'), 'Midnight Paranormal EVP', kHorrorCrimson, () => onVaultSelect('Horror')),
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
