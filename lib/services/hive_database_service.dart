import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../models/dava_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../models/category_model.dart';
import '../models/registration_model.dart';
import '../models/settings_model.dart';
import '../models/friendship_model.dart';
import '../models/evidence_model.dart';
import '../models/evidence_comment_model.dart';
import '../models/album_model.dart';
import '../models/album_image_model.dart';
import '../data/direm_data.dart';
import '../utils/constants.dart';
import 'verified_users_service.dart';
import '../utils/comment_utils.dart';

class HiveDatabaseService {
  static const String _davaBoxName = 'dava_box';
  static const String _userBoxName = 'user_box';
  static const String _commentBoxName = 'comment_box';
  static const String _categoryBoxName = 'category_box';
  static const String _registrationBoxName = 'registration_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _friendshipBoxName = 'friendship_box';
  static const String _evidenceBoxName = 'evidence_box';
  static const String _incomingDavaBoxName = 'incoming_dava_box';
  static const String _savedDavaBoxName = 'saved_dava_box';
  static const String _openedDavaBoxName = 'opened_dava_box';
  static const String _friendGroupBoxName = 'friend_group_box'; // key: ownerEmail, value: Map<friendEmail, category>
  static const String _homeFeedBoxName = 'home_feed_box'; // key: userEmail, value: List<Map<String, dynamic>>
  static const String _rejectedDavaBoxName = 'rejected_dava_box'; // key: userEmail, value: List<Map<String, dynamic>>
  static const String _acceptedDavaBoxName = 'accepted_dava_box'; // key: userEmail, value: List<Map<String, dynamic>>
  static const String _katildigimDavaBoxName = 'katildigim_dava_box'; // key: userEmail, value: List<Map<String, dynamic>>
  static const String _hukumBoxName = 'hukum_box'; // key: davaId_userRole, value: Map<String, dynamic> (hukum text, createdAt, etc.)
  static const String _davaParticipantBoxName = 'dava_participant_box'; // key: davaId, value: List<Map<String,dynamic>> (participant status list)
  static const String _cezaBegeniBoxName = 'ceza_begeni_box'; // key: cezaName, value: Map<String, dynamic> (likeCount, likedBy: List<String>)
  static const String _cezaBoxName = 'ceza_box'; // key: davaId_userEmail, value: String (ceza metni)
  static const String _cezaOyBoxName = 'ceza_oy_box'; // key: davaId, value: Map (votesByEmail)
  static const String _hediyeOyBoxName = 'hediye_oy_box'; // key: davaId, value: Map (votesByEmail)
  static const String _masrafBoxName = 'masraf_box'; // key: davaId_userEmail, value: List<String> (masraf isimleri listesi)
  static const String _reklamBoxName = 'reklam_box'; // key: reklamId, value: Map<String, dynamic> (reklam verileri)
  static const String _tutulanReklamlarBoxName = 'tutulan_reklamlar_box'; // key: userEmail, value: List<String> (reklamId listesi)
  static const String _hediyeUyariBoxName = 'hediye_uyari_box'; // key: davaId_userEmail, value: Map<String, dynamic> (hediye durumu ve uyarılar)
  static const String _davaActionsBoxName = 'dava_actions_box'; // key: davaId_userEmail, value: Map<String, dynamic> (kullanıcı bazlı aksiyonlar)
  static const String _davaActionStatsBoxName = 'dava_action_stats_box'; // key: davaId, value: Map<String, dynamic> (global istatistikler)
  static const String _davaHukumVerisiBoxName = 'dava_hukum_verisi_box'; // key: davaId, value: Map<String, dynamic> (hüküm verisi)
  static const String _haykirBoxName = 'haykir_box'; // key: haykirId, value: Map<String, dynamic> (haykırış verileri)
  static const String _katildigimHaykirBoxName = 'katildigim_haykir_box'; // ✅ key: userEmail, value: List<Map<String, dynamic>> (katıldığım haykırlar)
  static const String _userLastCommentBoxName = 'user_last_comment_box'; // ✅ key: userEmail, value: String (son yorum zamanı ISO8601)
  static const String _savedWidgetsBoxName = 'saved_widgets_box'; // ✅ Step-1: key: userEmail, value: List<Map<String, dynamic>> (kaydedilen widget'lar)
  static const String _albumBoxName = 'album_box'; // ✅ Step-3: key: userEmail, value: List<Map<String, dynamic>> (albümler)
  static const String _albumImageBoxName = 'album_image_box'; // ✅ Step-3: key: albumId, value: List<Map<String, dynamic>> (albüm resimleri)
  static const String _dailyQuotaBoxName = 'daily_quota_box'; // key: action_email_yyyy-mm-dd, value: int

  static Box<DavaModel>? _davaBox;
  static Box<UserModel>? _userBox;
  static Box<CommentModel>? _commentBox;
  static Box<CategoryModel>? _categoryBox;
  static Box<RegistrationModel>? _registrationBox;
  static Box<SettingsModel>? _settingsBox;
  static Box<FriendshipModel>? _friendshipBox;
  static Box<EvidenceModel>? _evidenceBox;
  static Box? _incomingDavaBox; // key: userEmail, value: List<Map<String, dynamic>>
  static Box? _savedDavaBox;   // key: 'saved', value: List<Map<String, dynamic>>
  static Box? _openedDavaBox;  // key: 'opened', value: List<Map<String, dynamic>>
  static Box? _friendGroupBox; // key: ownerEmail, value: Map<String, String>
  static Box? _homeFeedBox; // key: userEmail, value: List<Map<String, dynamic>>
  static Box? _rejectedDavaBox; // key: userEmail, value: List<Map<String, dynamic>>
  static Box? _acceptedDavaBox; // key: userEmail, value: List<Map<String, dynamic>>
  static Box? _katildigimDavaBox; // key: userEmail, value: List<Map<String, dynamic>>
  static Box? _hukumBox; // key: davaId_userRole, value: Map<String, dynamic>
  static Box? _davaParticipantBox; // key: davaId, value: List<Map<String, dynamic>>
  static Box? _cezaBegeniBox; // key: cezaName, value: Map<String, dynamic> (likeCount, likedBy: List<String>)
  static Box? _cezaBox; // key: davaId_userEmail, value: String (ceza metni)
  static Box? _cezaOyBox; // key: davaId, value: Map<String, dynamic> (votesByEmail)
  static Box? _hediyeOyBox; // key: davaId, value: Map<String, dynamic> (votesByEmail)
  static Box? _masrafBox; // key: davaId_userEmail, value: List<String> (masraf isimleri listesi)
  static Box? _reklamBox; // key: reklamId, value: Map<String, dynamic> (reklam verileri)
  static Box? _tutulanReklamlarBox; // key: userEmail, value: List<String> (reklamId listesi)
  static Box? _hediyeUyariBox; // key: davaId_userEmail, value: Map<String, dynamic>
  static Box? _davaActionsBox; // key: davaId_userEmail, value: Map<String, dynamic>
  static Box? _davaActionStatsBox; // key: davaId, value: Map<String, dynamic>
  static Box? _davaHukumVerisiBox; // key: davaId, value: Map<String, dynamic>
  static Box? _haykirBox; // key: haykirId, value: Map<String, dynamic>
  static Box? _katildigimHaykirBox; // ✅ key: userEmail, value: List<Map<String, dynamic>> (katıldığım haykırlar)
  static Box? _userLastCommentBox; // ✅ key: userEmail, value: String (son yorum zamanı ISO8601)
  static Box? _savedWidgetsBox; // ✅ Step-1: key: userEmail, value: List<Map<String, dynamic>> (kaydedilen widget'lar)
  static Box? _albumBox; // ✅ Step-3: key: userEmail, value: List<Map<String, dynamic>> (albümler)
  static Box? _albumImageBox; // ✅ Step-3: key: albumId, value: List<Map<String, dynamic>> (albüm resimleri)
  static Box? _dailyQuotaBox; // key: action_email_yyyy-mm-dd, value: int
  
  // Sabit grup üyelikleri (istenen kesin 7 kişi)
  static const List<String> _grup19Members = <String>[
    'testyargic1@gmail.com',
    'testyargic2@gmail.com',
    'testyargic5@gmail.com',
    'testyargic8@gmail.com',
    'testyargic9@gmail.com',
    'testyargic10@gmail.com',
    'testyargic11@gmail.com',
  ];

  // Hive'ı başlatma
  static Future<void> initialize() async {
    // Hive'ı Flutter ile başlat
    await Hive.initFlutter();

    // Adapter'ları kaydet
    Hive.registerAdapter(DavaModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(CommentModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(RegistrationModelAdapter());
    Hive.registerAdapter(EvidenceModelAdapter());
    Hive.registerAdapter(EvidenceCommentModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());
    Hive.registerAdapter(FriendshipModelAdapter());
    Hive.registerAdapter(FriendshipStatusAdapter());
    Hive.registerAdapter(AlbumModelAdapter());
    Hive.registerAdapter(AlbumImageModelAdapter());

    // Box'ları aç
    _davaBox = await Hive.openBox<DavaModel>(_davaBoxName);
    _userBox = await Hive.openBox<UserModel>(_userBoxName);
    _commentBox = await Hive.openBox<CommentModel>(_commentBoxName);
    _categoryBox = await Hive.openBox<CategoryModel>(_categoryBoxName);
    _registrationBox = await Hive.openBox<RegistrationModel>(_registrationBoxName);
    _evidenceBox = await Hive.openBox<EvidenceModel>(_evidenceBoxName);
    _settingsBox = await Hive.openBox<SettingsModel>(_settingsBoxName);
    _friendshipBox = await Hive.openBox<FriendshipModel>(_friendshipBoxName);
    _incomingDavaBox = await Hive.openBox(_incomingDavaBoxName);
    _savedDavaBox = await Hive.openBox(_savedDavaBoxName);
    _openedDavaBox = await Hive.openBox(_openedDavaBoxName);
    _friendGroupBox = await Hive.openBox(_friendGroupBoxName);
    _homeFeedBox = await Hive.openBox(_homeFeedBoxName);
    _davaParticipantBox = await Hive.openBox(_davaParticipantBoxName);
    _cezaBox = await Hive.openBox(_cezaBoxName);
    _cezaOyBox = await Hive.openBox(_cezaOyBoxName);
    _hediyeOyBox = await Hive.openBox(_hediyeOyBoxName);
    _masrafBox = await Hive.openBox(_masrafBoxName);
    _reklamBox = await Hive.openBox(_reklamBoxName);
    _tutulanReklamlarBox = await Hive.openBox(_tutulanReklamlarBoxName);
    _hediyeUyariBox = await Hive.openBox(_hediyeUyariBoxName);
    _davaActionsBox = await Hive.openBox(_davaActionsBoxName);
    _davaActionStatsBox = await Hive.openBox(_davaActionStatsBoxName);
    _davaHukumVerisiBox = await Hive.openBox(_davaHukumVerisiBoxName);
    _haykirBox = await Hive.openBox(_haykirBoxName);
    _userLastCommentBox = await Hive.openBox(_userLastCommentBoxName); // ✅ Kullanıcı son yorum zamanı box'ı
    _savedWidgetsBox = await Hive.openBox(_savedWidgetsBoxName); // ✅ Step-1: Kaydedilen widget'lar box'ı
    _albumBox = await Hive.openBox(_albumBoxName); // ✅ Step-3: Albümler box'ı
    _albumImageBox = await Hive.openBox(_albumImageBoxName); // ✅ Step-3: Albüm resimleri box'ı
    _dailyQuotaBox = await Hive.openBox(_dailyQuotaBoxName); // ✅ Günlük kota sayacı box'ı

    // Varsayılan kategorileri yükle (sadece ilk kez)
    await initializeDefaultCategories();
    
    // Varsayılan reklamları yükle (sadece ilk kez)
    await initializeDefaultReklamlar();
    
    // Verified users servisini başlat
    await VerifiedUsersService.initialize();
  }

  // ========== HOME FEED (SEYIR DEFTERI) ==========
  /// Kullanıcının kendi seyir defterine bir paylaşım ekle
  /// post örneği: {
  ///   'id': 'post_<timestamp>',
  ///   'type': 'dava_share',
  ///   'createdAt': DateTime.now().toIso8601String(),
  ///   'authorEmail': userEmail?,
  ///   'payload': { ... serbest alanlar ... }
  /// }
  static void addHomeFeedPost(Map<String, dynamic> post, {String? userEmail}) {
    // ✅ Düzeltme: Kullanıcı bazlı key kullan
    final authorEmail = post['authorEmail'] ?? userEmail;
    if (authorEmail == null || authorEmail.toString().isEmpty) {
      print('⚠️ addHomeFeedPost: authorEmail bulunamadı');
      return;
    }
    
    final key = authorEmail.toString();
    final persisted = _homeFeedBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    list.add(post);
    // Tarihe göre yeni olan en üstte dursun
    list.sort((a, b) {
      final aStr = a['createdAt']?.toString();
      final bStr = b['createdAt']?.toString();
      if (aStr == null && bStr == null) return 0;
      if (aStr == null) return 1;
      if (bStr == null) return -1;
      try {
        return DateTime.parse(bStr).compareTo(DateTime.parse(aStr));
      } catch (_) {
        return 0;
      }
    });
    _homeFeedBox?.put(key, list);
  }

  /// Kullanıcının kendi seyir defterindeki paylaşımları getirir (en yeni en üstte)
  static List<Map<String, dynamic>> getHomeFeedPosts({String? userEmail}) {
    // ✅ Düzeltme: Kullanıcı bazlı key kullan
    if (userEmail == null || userEmail.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    
    final key = userEmail;
    final persisted = _homeFeedBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Var olan bir home feed postunu id ile günceller (id eşleşmezse hiçbir şey yapmaz)
  /// Home feed postunu sil
  static void removeHomeFeedPost(String postId, {String? userEmail}) {
    if (userEmail == null || userEmail.isEmpty) {
      print('⚠️ removeHomeFeedPost: userEmail bulunamadı');
      return;
    }
    
    final key = userEmail;
    final persisted = _homeFeedBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    list.removeWhere((p) => p['id']?.toString() == postId);
    _homeFeedBox?.put(key, list);
    print('✅ Home feed postu silindi: $postId, $userEmail');
  }

  static void updateHomeFeedPost(String postId, Map<String, dynamic> updatedPost, {String? userEmail}) {
    // ✅ Düzeltme: Kullanıcı bazlı key kullan
    final authorEmail = updatedPost['authorEmail'] ?? userEmail;
    if (authorEmail == null || authorEmail.toString().isEmpty) {
      print('⚠️ updateHomeFeedPost: authorEmail bulunamadı');
      return;
    }
    
    final key = authorEmail.toString();
    final persisted = _homeFeedBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final idx = list.indexWhere((p) => p['id']?.toString() == postId);
    if (idx == -1) {
      return;
    }

    list[idx] = updatedPost;

    // createdAt alanına göre yeni olan üste gelecek şekilde sırala
    list.sort((a, b) {
      final aStr = a['createdAt']?.toString();
      final bStr = b['createdAt']?.toString();
      if (aStr == null && bStr == null) return 0;
      if (aStr == null) return 1;
      if (bStr == null) return -1;
      try {
        return DateTime.parse(bStr).compareTo(DateTime.parse(aStr));
      } catch (_) {
        return 0;
      }
    });

    _homeFeedBox?.put(key, list);
  }

  /// Belirli bir postu id ile getir (bulunamazsa null)
  static Map<String, dynamic>? getHomeFeedPostById(String postId, {String? userEmail}) {
    // ✅ Düzeltme: Kullanıcı bazlı arama
    if (userEmail == null || userEmail.isEmpty) {
      return null;
    }
    
    final key = userEmail;
    final persisted = _homeFeedBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    try {
      return list.firstWhere((p) => p['id']?.toString() == postId);
    } catch (_) {
      return null;
    }
  }

  // ========== ARKADAŞ GRUPLANDIRMA (KALICI) ==========
  /// Geçerli 4 kategori ismi için öneri: 'yakın', 'iş', 'okul', 'diğer'
  /// Uygulama tarafı farklı isimler kullanıyorsa, UI hangi string'i veriyorsa onu saklarız.

  /// Bir arkadaşın kategorisini ayarla (owner -> friend)
  static Future<void> setFriendCategory({
    required String ownerEmail,
    required String friendEmail,
    required String category,
  }) async {
    final current = _friendGroupBox?.get(ownerEmail);
    final Map<String, String> map = current != null
        ? Map<String, String>.from((current as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
        : <String, String>{};
    map[friendEmail] = category;
    await _friendGroupBox?.put(ownerEmail, map);
  }

  /// Bir arkadaşın kategorisini getir (yoksa null)
  static String? getFriendCategory({
    required String ownerEmail,
    required String friendEmail,
  }) {
    final current = _friendGroupBox?.get(ownerEmail);
    if (current == null) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(current as Map);
    final val = map[friendEmail];
    return val?.toString();
  }

  /// Bir kullanıcının tüm arkadaş-kategori eşleşmelerini getir
  static Map<String, String> getFriendCategories(String ownerEmail) {
    final current = _friendGroupBox?.get(ownerEmail);
    if (current == null) return <String, String>{};
    return Map<String, String>.from((current as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
  }

  /// Bir arkadaşın kategorisini sil
  static Future<void> removeFriendCategory({
    required String ownerEmail,
    required String friendEmail,
  }) async {
    final current = _friendGroupBox?.get(ownerEmail);
    if (current == null) return;
    final Map<String, dynamic> map = Map<String, dynamic>.from(current as Map);
    map.remove(friendEmail);
    await _friendGroupBox?.put(ownerEmail, Map<String, String>.from(map.map((k, v) => MapEntry(k.toString(), v.toString()))));
  }

  /// Bir kullanıcının tüm arkadas-kategori kaydını temizle
  static Future<void> clearFriendCategories(String ownerEmail) async {
    await _friendGroupBox?.delete(ownerEmail);
  }

  // ========== VERİTABANI TEMİZLİK İŞLEMLERİ ==========

  // Tüm verileri temizleme
  static Future<void> clearAllData() async {
    await _davaBox?.clear();
    await _userBox?.clear();
    await _commentBox?.clear();
    await _categoryBox?.clear();
    await _registrationBox?.clear();
    await _evidenceBox?.clear();
    await _friendshipBox?.clear();
    await _settingsBox?.clear();
    await _incomingDavaBox?.clear();
    await _savedDavaBox?.clear();
    await _openedDavaBox?.clear();
    await _friendGroupBox?.clear();
    await _davaParticipantBox?.clear();
    await _cezaBox?.clear();
    await _cezaOyBox?.clear();
    await _hediyeOyBox?.clear();
    await _masrafBox?.clear();
    await _reklamBox?.clear();
    await _tutulanReklamlarBox?.clear();
    await _dailyQuotaBox?.clear();
  }

  // Veritabanı istatistikleri
  static Map<String, int> getDatabaseStats() {
    // Açılan davaları say (unique ID'lere göre)
    final openedDavaCount = getOpenedDavalar().length;
    
    // Kaydedilen davaları say
    final savedDavaCount = getSavedDavalar().length;
    
    // Tüm gelen davaları say (tüm kullanıcılar için)
    int totalIncomingDava = 0;
    final allRegistrations = getAllRegistrations();
    for (final reg in allRegistrations) {
      totalIncomingDava += getIncomingDavalar(reg.email).length;
    }
    
    // Toplam unique dava sayısı
    final Set<String> uniqueDavaIds = {};
    
    // Açılan davalardan ID'leri topla
    for (final dava in getOpenedDavalar()) {
      if (dava['id'] != null) {
        uniqueDavaIds.add(dava['id'].toString());
      }
    }
    
    // Kaydedilen davalardan ID'leri topla
    for (final dava in getSavedDavalar()) {
      if (dava['id'] != null) {
        uniqueDavaIds.add(dava['id'].toString());
      }
    }
    
    return {
      'davalar': uniqueDavaIds.length, // Toplam unique dava sayısı
      'acilan_davalar': openedDavaCount,
      'kaydedilen_davalar': savedDavaCount,
      'gelen_davalar': totalIncomingDava,
      'kullanicilar': _userBox?.length ?? 0,
      'kayitlar': _registrationBox?.length ?? 0,
      'yorumlar': _commentBox?.length ?? 0,
      'kategoriler': _categoryBox?.length ?? 0,
      'aktif_kategoriler': getActiveCategories().length,
    };
  }

  /// Dava aç sayfasından kaydedilen davaları saklamak için (kalıcı kutu)
  static final List<Map<String, dynamic>> _savedDavalar = []; // bellek önbellek

  /// Dava kaydet
  static void saveDava(Map<String, dynamic> dava) {
    // Kalıcı listeden oku, güncelle/ekle ve geri yaz
    final persisted = _savedDavaBox?.get('saved');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_savedDavalar);

    final existingIndex = list.indexWhere((d) => d['id'] == dava['id']);
    if (existingIndex != -1) {
      list[existingIndex] = dava;
    } else {
      list.add(dava);
    }
    _savedDavalar
      ..clear()
      ..addAll(list);
    _savedDavaBox?.put('saved', list);
  }

  /// Kaydedilen davaları getir (tarihe göre sıralı)
  static List<Map<String, dynamic>> getSavedDavalar() {
    // Kalıcıdan oku, yoksa belleği kullan
    final persisted = _savedDavaBox?.get('saved');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_savedDavalar);
    // Tarihe göre sırala (en yakın tarihli en üstte)
    list.sort((a, b) {
      final dateA = a['kalanSure'] as String;
      final dateB = b['kalanSure'] as String;
      
      // Tarih formatı: DD.MM.YYYY
      if (dateA == ".../.../.....") return 1; // Tarihi belirlenmemiş davalar en alta
      if (dateB == ".../.../.....") return -1;
      
      try {
        final partsA = dateA.split('.');
        final partsB = dateB.split('.');
        final dayA = int.parse(partsA[0]);
        final monthA = int.parse(partsA[1]);
        final yearA = int.parse(partsA[2]);
        final dayB = int.parse(partsB[0]);
        final monthB = int.parse(partsB[1]);
        final yearB = int.parse(partsB[2]);
        
        final dateTimeA = DateTime(yearA, monthA, dayA);
        final dateTimeB = DateTime(yearB, monthB, dayB);
        
        return dateTimeB.compareTo(dateTimeA); // En yakın tarihli en üstte
      } catch (e) {
        return 0;
      }
    });
    
    _savedDavalar
      ..clear()
      ..addAll(list);
    return List.from(list);
  }

  /// Belirli bir kaydedilen davayı sil
  static void deleteSavedDava(String id) {
    final persisted = _savedDavaBox?.get('saved');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_savedDavalar);
    list.removeWhere((d) => d['id'] == id);
    _savedDavalar
      ..clear()
      ..addAll(list);
    _savedDavaBox?.put('saved', list);
  }

  /// Açılan davaları saklamak için (kalıcı kutu)
  static final List<Map<String, dynamic>> _openedDavalar = []; // bellek önbellek

  /// Açılan dava kaydet
  static void saveOpenedDava(Map<String, dynamic> dava) {
    final persisted = _openedDavaBox?.get('opened');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_openedDavalar);
    final existingIndex = list.indexWhere((d) => d['id'] == dava['id']);
    if (existingIndex != -1) {
      list[existingIndex] = dava;
    } else {
      list.add(dava);
    }
    _openedDavalar
      ..clear()
      ..addAll(list);
    _openedDavaBox?.put('opened', list);
  }

  /// Açılan davaları getir (tarihe göre sıralı)
  static List<Map<String, dynamic>> getOpenedDavalar() {
    // Kalıcıdan oku, yoksa belleği kullan
    final persisted = _openedDavaBox?.get('opened');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_openedDavalar);
    // Tarihe göre sırala (en yakın tarihli en üstte)
    list.sort((a, b) {
      final dateA = a['openedAt'] as String;
      final dateB = b['openedAt'] as String;
      try {
        final dateTimeA = DateTime.parse(dateA);
        final dateTimeB = DateTime.parse(dateB);
        return dateTimeB.compareTo(dateTimeA);
      } catch (e) {
        return 0;
      }
    });
    _openedDavalar
      ..clear()
      ..addAll(list);
    return List.from(list);
  }

  /// Belirli bir açılan davayı ID ile getir
  static Map<String, dynamic>? getOpenedDavaById(String davaId) {
    final persisted = _openedDavaBox?.get('opened');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_openedDavalar);
    
    try {
      return list.firstWhere(
        (d) => (d['id']?.toString() ?? '') == davaId || 
               (d['davaId']?.toString() ?? '') == davaId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Açılan davayı güncelle
  static Future<void> updateOpenedDava(String davaId, Map<String, dynamic> updatedData) async {
    final persisted = _openedDavaBox?.get('opened');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_openedDavalar);
    
    final index = list.indexWhere(
      (d) => (d['id']?.toString() ?? '') == davaId || 
             (d['davaId']?.toString() ?? '') == davaId,
    );
    
    if (index != -1) {
      list[index] = {...list[index], ...updatedData};
      _openedDavalar
        ..clear()
        ..addAll(list);
      _openedDavaBox?.put('opened', list);
    }
  }

  /// Çekilme / red vicdan metnini açılan davaya ekle (Seyir Defteri senkronu).
  static Future<void> appendWithdrawalNarrative(
    String davaId,
    String narrative,
  ) async {
    final existing = getOpenedDavaById(davaId);
    if (existing == null) return;
    final list = List<String>.from(existing['withdrawalNarratives'] ?? []);
    list.add(narrative);
    await updateOpenedDava(davaId, {
      'withdrawalNarratives': list,
      'caseParticipantOutcome': 'Reddedildi/Çekildi',
    });
  }

  /// Dava tarihçesine olay ekle.
  static Future<void> appendDavaHistoryEvent(
    String davaId,
    Map<String, dynamic> event,
  ) async {
    final existing = getOpenedDavaById(davaId);
    if (existing == null) return;
    final h = List<Map<String, dynamic>>.from(existing['davaHistory'] ?? []);
    h.add({
      ...event,
      'recordedAt': DateTime.now().toIso8601String(),
    });
    await updateOpenedDava(davaId, {'davaHistory': h});
  }

  /// Temyiz talebi: davacı/davalı kapı ikonundan sonra işaretlenir.
  static Future<void> setDavaAppealRequested({
    required String davaId,
    required String requestedByEmail,
    required String party, // 'davaci' | 'davali'
  }) async {
    // Geriye dönük uyumluluk: doğrudan çağrılarda yalnızca bayrakları günceller.
    await updateOpenedDava(davaId, {
      'isAppealable': true,
      'appealRequestedAt': DateTime.now().toIso8601String(),
      'appealRequestedBy': requestedByEmail,
      'appealRequestedParty': party,
    });
  }

  /// Belirli bir açılan davayı sil
  static void deleteOpenedDava(String id) {
    final persisted = _openedDavaBox?.get('opened');
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : List<Map<String, dynamic>>.from(_openedDavalar);
    list.removeWhere((d) => d['id'] == id);
    _openedDavalar
      ..clear()
      ..addAll(list);
    _openedDavaBox?.put('opened', list);
  }

  /// Tüm açılan davaları temizle
  static void clearOpenedDavalar() {
    _openedDavalar.clear();
    _openedDavaBox?.delete('opened');
  }

  /// Tüm kaydedilen davaları temizle
  static void clearSavedDavalar() {
    _savedDavalar.clear();
    _savedDavaBox?.delete('saved');
  }

  // ========== AYARLAR İŞLEMLERİ ==========
  
  /// Kullanıcı ayarlarını kaydet/güncelle
  static Future<void> saveSettings(SettingsModel settings) async {
    await _settingsBox?.put(settings.userEmail, settings);
  }

  /// Kullanıcı ayarlarını getir
  static SettingsModel? getSettings(String userEmail) {
    return _settingsBox?.get(userEmail);
  }

  /// Kullanıcı ayarlarını oluştur veya getir (yoksa varsayılan ayarlarla oluştur)
  static Future<SettingsModel> getOrCreateSettings(String userEmail) async {
    var settings = getSettings(userEmail);
    if (settings == null) {
      settings = SettingsModel(userEmail: userEmail);
      await saveSettings(settings);
    }
    return settings;
  }

  /// Gizlilik ayarını güncelle
  static Future<void> updatePrivacySetting(String userEmail, String settingKey, bool value) async {
    final settings = await getOrCreateSettings(userEmail);
    settings.updatePrivacySetting(settingKey, value);
    await saveSettings(settings);
  }

  /// Profil bilgilerini güncelle
  static Future<void> updateProfileInfo(String userEmail, {
    String? profileImageUrl,
    String? philosophy,
    String? postrestantAddress,
    String? country,
    String? language,
  }) async {
    final settings = await getOrCreateSettings(userEmail);
    final updatedSettings = settings.copyWith(
      profileImageUrl: profileImageUrl,
      philosophy: philosophy,
      postrestantAddress: postrestantAddress,
      country: country,
      language: language,
    );
    await saveSettings(updatedSettings);
  }

  /// Ayarları varsayılan değerlere sıfırla
  static Future<void> resetSettingsToDefaults(String userEmail) async {
    final settings = SettingsModel(userEmail: userEmail);
    await saveSettings(settings);
  }

  /// Kullanıcı ayarlarını sil
  static Future<void> deleteSettings(String userEmail) async {
    await _settingsBox?.delete(userEmail);
  }

  /// Tüm ayarları getir (admin için)
  static List<SettingsModel> getAllSettings() {
    return _settingsBox?.values.toList() ?? [];
  }

  /// Mevcut tüm kullanıcılar için varsayılan ayarları oluştur
  /// Bu fonksiyon sadece bir kez çalıştırılmalıdır
  static Future<void> createDefaultSettingsForAllUsers() async {
    final allRegistrations = getAllRegistrations();
    
    for (final registration in allRegistrations) {
      // Kullanıcının ayarları var mı kontrol et
      final existingSettings = getSettings(registration.email);
      if (existingSettings == null) {
        // Ayarları yoksa varsayılan ayarlarla oluştur
        final defaultSettings = SettingsModel(userEmail: registration.email);
        await saveSettings(defaultSettings);
        print('Varsayılan ayarlar oluşturuldu: ${registration.email}');
      }
    }
  }

  // ========== ARKADAŞLIK İŞLEMLERİ ==========
  
  /// Arkadaşlık talebi gönder
  static Future<void> sendFriendshipRequest(FriendshipModel friendship) async {
    await _friendshipBox?.put(friendship.id, friendship);
  }

  /// Arkadaşlık talebini güncelle
  static Future<void> updateFriendship(FriendshipModel friendship) async {
    await _friendshipBox?.put(friendship.id, friendship);
  }

  /// Arkadaşlık talebini sil
  static Future<void> deleteFriendship(String friendshipId) async {
    await _friendshipBox?.delete(friendshipId);
  }

  /// Arkadaşlık getir
  static FriendshipModel? getFriendship(String id) {
    return _friendshipBox?.get(id);
  }

  /// Bekleyen arkadaşlık taleplerini getir
  static List<FriendshipModel> getPendingFriendships(String userId) {
    return _friendshipBox?.values
        .where((f) => 
            f.recipientId == userId && 
            f.status == FriendshipStatus.pending)
        .toList() ?? [];
  }

  /// Kabul edilmiş arkadaşlıkları getir
  static List<FriendshipModel> getAcceptedFriendships(String userId) {
    return _friendshipBox?.values
        .where((f) => 
            (f.requesterId == userId || f.recipientId == userId) && 
            f.status == FriendshipStatus.accepted)
        .toList() ?? [];
  }

  /// Takip edilen kullanıcıları getir
  static List<FriendshipModel> getFollowingUsers(String userId) {
    return _friendshipBox?.values
        .where((f) => 
            f.requesterId == userId && 
            f.status == FriendshipStatus.following)
        .toList() ?? [];
  }

  /// Takipçileri getir
  static List<FriendshipModel> getFollowers(String userId) {
    final followers = _friendshipBox?.values
        .where((f) => 
            f.recipientId == userId && 
            f.status == FriendshipStatus.following)
        .toList() ?? [];
    
    print('DEBUG: getFollowers($userId) - Found ${followers.length} followers');
    for (final f in followers) {
      print('  - Follower: ${f.requesterId} -> ${f.recipientId} (${f.status})');
    }
    
    return followers;
  }

  /// İki kullanıcının arkadaş olup olmadığını kontrol et
  static bool areFriends(String userId1, String userId2) {
    return _friendshipBox?.values.any((f) => 
        ((f.requesterId == userId1 && f.recipientId == userId2) ||
         (f.requesterId == userId2 && f.recipientId == userId1)) &&
        f.status == FriendshipStatus.accepted) ?? false;
  }

  /// Bekleyen arkadaşlık talebi var mı kontrol et
  static bool hasPendingRequest(String requesterId, String recipientId) {
    return _friendshipBox?.values.any((f) => 
        f.requesterId == requesterId && 
        f.recipientId == recipientId && 
        f.status == FriendshipStatus.pending) ?? false;
  }

  /// Kullanıcı takip ediliyor mu kontrol et
  static bool isFollowing(String followerId, String followedId) {
    return _friendshipBox?.values.any((f) => 
        f.requesterId == followerId && 
        f.recipientId == followedId && 
        f.status == FriendshipStatus.following) ?? false;
  }

  /// Tüm arkadaşlıkları getir
  static List<FriendshipModel> getAllFriendships() {
    return _friendshipBox?.values.toList() ?? [];
  }

  /// Kullanıcının arkadaşlık durumunu getir
  static FriendshipStatus getFriendshipStatus(String userId1, String userId2) {
    final friendship = _friendshipBox?.values.firstWhere(
      (f) => (f.requesterId == userId1 && f.recipientId == userId2) ||
             (f.requesterId == userId2 && f.recipientId == userId1),
      orElse: () => FriendshipModel(
        id: '',
        requesterId: userId1,
        recipientId: userId2,
        status: FriendshipStatus.none,
        createdAt: DateTime.now(),
      ),
    );
    return friendship?.status ?? FriendshipStatus.none;
  }

  /// Arkadaşlık durumunu güncelle
  static Future<void> updateFriendshipStatus(String requesterId, String recipientId, FriendshipStatus newStatus) async {
    try {
      final friendship = _friendshipBox?.values.firstWhere(
        (f) => f.requesterId == requesterId && f.recipientId == recipientId,
      );
      
      if (friendship != null) {
        final updatedFriendship = friendship.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        await updateFriendship(updatedFriendship);
      }
    } catch (e) {
      // Arkadaşlık bulunamadı, hiçbir şey yapma
    }
  }

  /// Belirli bir arkadaşlık kaydını getir
  static FriendshipModel? getFriendshipByUsers(String requesterId, String recipientId) {
    try {
      return _friendshipBox?.values.firstWhere(
        (f) => f.requesterId == requesterId && f.recipientId == recipientId,
      );
    } catch (e) {
      return null;
    }
  }

  // ========== REGISTRATION (KAYIT) İŞLEMLERİ ==========
  
  /// Tüm kayıtları getir
  static List<RegistrationModel> getAllRegistrations() {
    return _registrationBox?.values.toList() ?? [];
  }

  /// Sabit Grup19 listesindeki kullanıcılardan, uygulamada kaydı bulunanları döndürür.
  static Set<String> getRegisteredGrup19MemberEmails() {
    final registeredEmails = getAllRegistrations()
        .map((r) => r.email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();

    return _grup19Members
        .map((email) => email.trim().toLowerCase())
        .where(registeredEmails.contains)
        .toSet();
  }

  /// E-posta ile kayıt getir
  static RegistrationModel? getRegistrationByEmail(String email) {
    try {
      return _registrationBox?.values.firstWhere((r) => r.email == email);
    } catch (e) {
      return null;
    }
  }

  static String _normalizeJudgeName(String judgeName) {
    return judgeName.trim().toLowerCase();
  }

  /// Yargıç adı ile kayıt getir (case-insensitive, trim)
  static RegistrationModel? getRegistrationByJudgeName(String judgeName) {
    final normalized = _normalizeJudgeName(judgeName);
    if (normalized.isEmpty) return null;

    try {
      return _registrationBox?.values.firstWhere(
        (r) => _normalizeJudgeName(r.judgeName) == normalized,
      );
    } catch (e) {
      return null;
    }
  }

  /// Kayıt ekle
  static Future<void> addRegistration(RegistrationModel registration) async {
    await _registrationBox?.put(registration.id, registration);
  }

  /// Kayıt güncelle
  static Future<void> updateRegistration(RegistrationModel registration) async {
    await _registrationBox?.put(registration.id, registration);
  }

  /// Kayıt sil
  static Future<void> deleteRegistration(String id) async {
    await _registrationBox?.delete(id);
  }

  /// Giriş doğrulama
  static bool validateLogin(String email, String password) {
    final user = getRegistrationByEmail(email);
    if (user == null) return false;
    if (user.password != password) return false;
    return user.canLogin;
  }

  // ========== KATEGORİ İŞLEMLERİ ==========
  
  /// Varsayılan kategorileri kurulumda yükle (sadece Hive boşsa).
  /// Sabit liste [initialCategories] lib/utils/constants.dart içindedir;
  /// ileride Hive üzerinden isim/icon güncellenebilir.
  static Future<void> initializeDefaultCategories() async {
    if ((_categoryBox?.isEmpty ?? true)) {
      final now = DateTime.now();
      for (int i = 0; i < initialCategories.length; i++) {
        final entry = initialCategories[i];
        final id = entry['id'].toString();
        final model = CategoryModel(
          id: id,
          name: entry['name'] as String,
          subCategories: [],
          iconPath: entry['icon'] as String?,
          isActive: true,
          totalDavalar: 0,
          createdAt: now,
          orderIndex: i,
        );
        await _categoryBox?.put(id, model);
      }
    }
  }

  /// Tüm kategorileri getir
  static List<CategoryModel> getAllCategories() {
    return _categoryBox?.values.toList() ?? [];
  }

  /// Aktif kategorileri getir (orderIndex'e göre sıralı)
  static List<CategoryModel> getActiveCategories() {
    final all = getAllCategories();
    final active = all.where((c) => c.isActive).toList();
    active.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return active;
  }

  /// Arama metnine göre kategorileri filtrele
  static List<CategoryModel> filterCategories(String query) {
    final all = getActiveCategories();
    if (query.trim().isEmpty) {
      // "İlişkiler" kategorisini en üste taşı, diğerlerinin sırası korunur
      final list = List<CategoryModel>.from(all);
      final idx = list.indexWhere((c) => c.name.toLowerCase() == 'ilişkiler' || c.name.toLowerCase() == 'ilişkiler' || c.name == 'İlişkiler');
      if (idx > 0) {
        final item = list.removeAt(idx);
        list.insert(0, item);
      }
      return list;
    }
    final q = query.toLowerCase();
    final filtered = all.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      return c.subCategories.any((s) => s.toLowerCase().contains(q));
    }).toList();
    // Arama sonucunda da "İlişkiler" ilk sıraya alınır (varsa)
    final idx = filtered.indexWhere((c) => c.name.toLowerCase() == 'ilişkiler' || c.name.toLowerCase() == 'ilişkiler' || c.name == 'İlişkiler');
    if (idx > 0) {
      final item = filtered.removeAt(idx);
      filtered.insert(0, item);
    }
    return filtered;
  }

  /// Kategori ekle
  static Future<void> addCategory(CategoryModel category) async {
    await _categoryBox?.put(category.id, category);
  }

  /// Kategori güncelle
  static Future<void> updateCategory(CategoryModel category) async {
    await _categoryBox?.put(category.id, category);
  }

  /// Kategori sil
  static Future<void> deleteCategory(String id) async {
    await _categoryBox?.delete(id);
  }

  // ========== GÜNLÜK KOTA İŞLEMLERİ ==========
  static const int _dailyDavaLimit = 19;

  static String _dailyQuotaKey({
    required String action,
    required String email,
    required DateTime date,
  }) {
    final day = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${action}_${email.toLowerCase()}_$day';
  }

  static int _getTodayQuotaCount({
    required String action,
    required String email,
  }) {
    final key = _dailyQuotaKey(action: action, email: email, date: DateTime.now());
    final raw = _dailyQuotaBox?.get(key);
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static Future<void> _incrementTodayQuotaCount({
    required String action,
    required String email,
  }) async {
    final key = _dailyQuotaKey(action: action, email: email, date: DateTime.now());
    final current = _getTodayQuotaCount(action: action, email: email);
    await _dailyQuotaBox?.put(key, current + 1);
  }

  static bool canUserOpenDava(String email) {
    // Admin kullanıcı sınırsız dava açabilir
    if (isAdmin(email)) return true;
    final todayCount = _getTodayQuotaCount(action: 'dava', email: email);
    return todayCount < _dailyDavaLimit;
  }

  static bool canUserHaykir(String email) {
    // Haykır bekleme süresi devre dışı (çalışan proje ile uyumlu)
    return true;
  }

  /// Kullanıcının admin olup olmadığını kontrol et
  static bool isAdmin(String? email) {
    if (email == null) return false;
    final user = getRegistrationByEmail(email);
    return user?.isAdmin ?? false;
  }

  static int getRemainingDavaAcHours(String email) {
    // Geriye uyumluluk: metod adı saat içeriyor ama artık "kalan günlük dava hakkı" döndürür.
    if (isAdmin(email)) return 0;
    final todayCount = _getTodayQuotaCount(action: 'dava', email: email);
    final remaining = _dailyDavaLimit - todayCount;
    return remaining > 0 ? remaining : 0;
  }

  static int getRemainingHaykirHours(String email) {
    return 0;
  }

  static Future<void> updateUserDavaAcTime(String email) async {
    await _incrementTodayQuotaCount(action: 'dava', email: email);
    final user = getRegistrationByEmail(email);
    if (user == null) return;
    final updated = user.copyWith(lastDavaAcTime: DateTime.now());
    await updateRegistration(updated);
  }

  static Future<void> updateUserHaykirTime(String email) async {
    final user = getRegistrationByEmail(email);
    if (user == null) return;
    final updated = user.copyWith(lastHaykirTime: DateTime.now());
    await updateRegistration(updated);
  }

  // ========== DAVA İŞLEMLERİ ==========
  static DavaModel? getDava(String id) {
    return _davaBox?.get(id);
  }

  /// Benzersiz dava/taslak kimliği üretir
  static String generateUniqueDavaId(String userEmail) {
    final safeEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'dava_${safeEmail}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ========== GELEN DAVALAR (KULLANICIYA ATANAN) ==========
  /// Kullanıcıya atanan davaları bellekte saklarız (UX'e dokunmadan hızlı kullanım için)
  static final Map<String, List<Map<String, dynamic>>> _incomingDavalarByUser = {};

  /// Kullanıcıya gelen davayı ekle
  static void addIncomingDava(String userEmail, Map<String, dynamic> dava) {
    // Kalıcı listeden yükle
    final persisted = _incomingDavaBox?.get(userEmail);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : List<Map<String, dynamic>>.from(_incomingDavalarByUser[userEmail] ?? []);
    // Aynı ID varsa güncelle, yoksa ekle
    final existingIndex = list.indexWhere((d) => d['id'] == dava['id']);
    final wasNew = existingIndex == -1;
    if (existingIndex != -1) {
      list[existingIndex] = dava;
    } else {
      list.add(dava);
    }
    _incomingDavalarByUser[userEmail] = list;
    // Kalıcıya yaz
    _incomingDavaBox?.put(userEmail, list);

    if (wasNew) {
      Future.microtask(() => appendGelenDavaBildirimi(userEmail, dava));
    }

    final String? davaId = (dava['id'] ?? dava['davaId'])?.toString();
    if (davaId != null && davaId.isNotEmpty) {
      final nowIso = DateTime.now().toIso8601String();
      final participant = {
        'userEmail': userEmail,
        'displayName': (getRegistrationByEmail(userEmail)?.judgeName ?? userEmail.split('@').first),
        'status': 'pending',
        'statusUpdatedAt': nowIso,
        'assignedAt': dava['assignedAt']?.toString() ?? nowIso,
        'mevkii': dava['mevkii']?.toString(),
      };
      upsertDavaParticipant(davaId, participant);
    }
  }

  /// Kullanıcının gelen davalarını getir (tarihe göre yakın olan üste)
  static List<Map<String, dynamic>> getIncomingDavalar(String userEmail) {
    // Kalıcıdan oku, yoksa bellekten
    final persisted = _incomingDavaBox?.get(userEmail);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : List<Map<String, dynamic>>.from(_incomingDavalarByUser[userEmail] ?? []);
    // openedAt varsa yeni olan üste
    list.sort((a, b) {
      final aStr = a['openedAt'] as String?;
      final bStr = b['openedAt'] as String?;
      if (aStr == null && bStr == null) return 0;
      if (aStr == null) return 1;
      if (bStr == null) return -1;
      try {
        return DateTime.parse(bStr).compareTo(DateTime.parse(aStr));
      } catch (_) {
        return 0;
      }
    });
    // Bellek önbelleğini güncelle
    _incomingDavalarByUser[userEmail] = List<Map<String, dynamic>>.from(list);
    return list;
  }

  /// Kullanıcının gelen davalarını temizle
  static void clearIncomingDavalar(String userEmail) {
    _incomingDavalarByUser.remove(userEmail);
    _incomingDavaBox?.delete(userEmail);
  }

  /// Belirli kullanıcının incoming kutusunu izleme (değişince event yayınlar)
  static Stream<dynamic> watchIncomingFor(String userEmail) {
    if (_incomingDavaBox == null) {
      return const Stream.empty();
    }
    return _incomingDavaBox!.watch(key: userEmail);
  }

  /// Belirli bir dava için engagement verilerini tüm yerlerde güncelle
  /// Bu metod tüm kullanıcıların incoming davalarındaki, opened davalarındaki
  /// ve home feed'deki engagement verilerini senkronize eder
  static Future<void> updateDavaEngagement({
    required String davaId,
    int? yorumSayisi,
    int? retweetSayisi,
    int? begeniSayisi,
    int? begenmemeSayisi,
    bool? userLiked,
    bool? userDisliked,
    bool? userRetweeted,
    List<Map<String, dynamic>>? yorumlar,
    String? userEmail, // Sadece bu kullanıcı için userLiked/userDisliked/userRetweeted güncelle
  }) async {
    try {
      // 1. Tüm kullanıcıların incoming davalarını güncelle
      final allUsers = getAllRegistrations();
      for (final user in allUsers) {
        final incomingDavalar = getIncomingDavalar(user.email);
        final updatedList = incomingDavalar.map((dava) {
          if ((dava['id']?.toString() ?? '') == davaId) {
            final updated = Map<String, dynamic>.from(dava);
            if (yorumSayisi != null) updated['yorumSayisi'] = yorumSayisi;
            if (retweetSayisi != null) updated['retweetSayisi'] = retweetSayisi;
            if (begeniSayisi != null) updated['begeniSayisi'] = begeniSayisi;
            if (begenmemeSayisi != null) updated['begenmemeSayisi'] = begenmemeSayisi;
            if (yorumlar != null) updated['yorumlar'] = yorumlar;
            
            // Kullanıcıya özel engagement durumları (sadece belirtilen kullanıcı için)
            if (userEmail != null && user.email == userEmail) {
              if (userLiked != null) updated['userLiked'] = userLiked;
              if (userDisliked != null) updated['userDisliked'] = userDisliked;
              if (userRetweeted != null) updated['userRetweeted'] = userRetweeted;
            }
            
            return updated;
          }
          return dava;
        }).toList();
        
        // Güncellenmiş listeyi kaydet
        if (updatedList != incomingDavalar) {
          _incomingDavaBox?.put(user.email, updatedList);
          _incomingDavalarByUser[user.email] = updatedList;
        }
      }
      
      // 2. Opened davaları güncelle
      final openedDavalar = getOpenedDavalar();
      final updatedOpenedList = openedDavalar.map((dava) {
        if ((dava['id']?.toString() ?? '') == davaId) {
          final updated = Map<String, dynamic>.from(dava);
          if (yorumSayisi != null) updated['yorumSayisi'] = yorumSayisi;
          if (retweetSayisi != null) updated['retweetSayisi'] = retweetSayisi;
          if (begeniSayisi != null) updated['begeniSayisi'] = begeniSayisi;
          if (begenmemeSayisi != null) updated['begenmemeSayisi'] = begenmemeSayisi;
          if (yorumlar != null) updated['yorumlar'] = yorumlar;
          return updated;
        }
        return dava;
      }).toList();
      
      if (updatedOpenedList != openedDavalar) {
        _openedDavaBox?.put('opened_davalar', updatedOpenedList);
      }
      
      // 3. Tüm kullanıcıların home feed'deki davaları güncelle
      for (final user in allUsers) {
        final homeFeedPosts = getHomeFeedPosts(userEmail: user.email);
        for (final post in homeFeedPosts) {
          final payload = post['payload'];
          if (payload is Map && (payload['id']?.toString() ?? payload['davaId']?.toString() ?? '') == davaId) {
            final updatedPayload = Map<String, dynamic>.from(payload);
            if (yorumSayisi != null) updatedPayload['yorumSayisi'] = yorumSayisi;
            if (retweetSayisi != null) updatedPayload['retweetSayisi'] = retweetSayisi;
            if (begeniSayisi != null) updatedPayload['begeniSayisi'] = begeniSayisi;
            if (begenmemeSayisi != null) updatedPayload['begenmemeSayisi'] = begenmemeSayisi;
            if (yorumlar != null) updatedPayload['yorumlar'] = yorumlar;
            
            // Kullanıcıya özel engagement durumları (sadece belirtilen kullanıcı için)
            if (userEmail != null && user.email == userEmail) {
              if (userLiked != null) updatedPayload['userLiked'] = userLiked;
              if (userDisliked != null) updatedPayload['userDisliked'] = userDisliked;
              if (userRetweeted != null) updatedPayload['userRetweeted'] = userRetweeted;
            }
            
            final updatedPost = Map<String, dynamic>.from(post);
            updatedPost['payload'] = updatedPayload;
            updateHomeFeedPost(post['id'], updatedPost, userEmail: user.email);
          }
        }
      }
      
      print('✅ Engagement verileri güncellendi: davaId=$davaId');
    } catch (e) {
      print('❌ Engagement güncelleme hatası: $e');
    }
  }

  // ========== GRUP ALGORİTMASI (BASİT) ==========
  /// Grup seçimine göre (örn. Grup19) rastgele alıcılar seç
  static Future<List<RegistrationModel>> pickGroupRecipients(
    String openerEmail,
    String groupName, {
    int count = 7,
    String? defendantEmail,
    bool sameCountryOnly = false,
  }) async {
    // Grup adı normalizasyonu ("Grup-19" ve "Grup19" desteklenir)
    final normalized = groupName.toLowerCase().replaceAll('-', '').trim();

    // ✅ ADIM-1: Dava açan kullanıcının mavi tik sahibi olup olmadığını kontrol et
    final opener = getRegistrationByEmail(openerEmail);
    final openerJudgeName = opener?.judgeName ?? '';
    final isOpenerVerified = VerifiedUsersService.isVerified(openerJudgeName);

    // Eğer Grup19 ise eksikleri zincirli fallback ile 7'ye tamamla
    if (normalized == 'grup19') {
      final openerId = opener?.id;
      final openerCountry = opener?.country.trim().toLowerCase() ?? '';
      final allUsers = getAllRegistrations();
      final selected = <RegistrationModel>[];
      final selectedEmails = <String>{};
      final privacyCache = <String, bool>{};

      Future<bool> canReceive(RegistrationModel r) async {
        if (r.email == openerEmail) return false;
        if (defendantEmail != null && r.email == defendantEmail) return false;
        if (selectedEmails.contains(r.email)) return false;

        final cached = privacyCache[r.email];
        if (cached != null) return cached;
        try {
          final s = await getOrCreateSettings(r.email);
          // 7 kişilik hüküm listesine girebilmek için iki şart:
          // 1) Bana Dava Açılsın açık olmalı
          // 2) Davetler > 7-Yargıç açık olmalı
          final allowsDava = s.privacySettings['genel_davaacilsin'] ?? true;
          final allowsSevenJudge = s.privacySettings['davet_7yargic'] ?? true;
          final ok = allowsDava && allowsSevenJudge;
          privacyCache[r.email] = ok;
          return ok;
        } catch (_) {
          privacyCache[r.email] = true;
          return true;
        }
      }

      Future<void> addFromPool(List<RegistrationModel> pool) async {
        for (final r in pool) {
          if (selected.length >= count) break;
          if (await canReceive(r)) {
            selected.add(r);
            selectedEmails.add(r.email);
          }
        }
      }

      // 1) Grup19 havuzu
      final grup19Pool = allUsers
          .where((r) => _grup19Members.contains(r.email))
          .toList()
        ..shuffle();
      await addFromPool(grup19Pool);

      // 2) Arkadaşlar havuzu
      if (selected.length < count) {
        final friendIds = getAcceptedFriendships(openerId ?? '')
            .map((f) => f.requesterId == openerId ? f.recipientId : f.requesterId)
            .toSet();
        final friendsPool = allUsers
            .where((r) => friendIds.contains(r.id))
            .toList()
          ..shuffle();
        await addFromPool(friendsPool);
      }

      // 3) Takipçiler havuzu
      if (selected.length < count) {
        final followerIds = getFollowers(openerId ?? '').map((f) => f.requesterId).toSet();
        final followersPool = allUsers
            .where((r) => followerIds.contains(r.id))
            .toList()
          ..shuffle();
        await addFromPool(followersPool);
      }

      // 4) Herkes havuzu (tanımadıklar / ilişkisiz kullanıcılar)
      if (selected.length < count) {
        final friendIds = getAcceptedFriendships(openerId ?? '')
            .expand((f) => [f.requesterId, f.recipientId])
            .toSet();
        final followerIds = getFollowers(openerId ?? '').map((f) => f.requesterId).toSet();
        final followingIds = getFollowingUsers(openerId ?? '').map((f) => f.recipientId).toSet();
        final excludeIds = <String>{}
          ..addAll(friendIds)
          ..addAll(followerIds)
          ..addAll(followingIds)
          ..add(openerId ?? '');
        final everyonePool = allUsers
            .where((r) => !excludeIds.contains(r.id))
            .toList()
          ..shuffle();
        await addFromPool(everyonePool);
      }

      // 5) Hala eksikse: aynı ülkeden herhangi kullanıcı
      if (selected.length < count && openerCountry.isNotEmpty) {
        final sameCountryPool = allUsers
            .where((r) => r.country.trim().toLowerCase() == openerCountry)
            .toList()
          ..shuffle();
        await addFromPool(sameCountryPool);
      }

      // 6) Hala eksikse: ülke şartı aranmaksızın herhangi kullanıcı
      if (selected.length < count) {
        final anyPool = List<RegistrationModel>.from(allUsers)..shuffle();
        await addFromPool(anyPool);
      }

      if (selected.length <= count) return selected;
      return selected.take(count).toList();
    }

    // Opener bilgisi (yukarıda zaten tanımlanmış, tekrar tanımlamaya gerek yok)
    final openerId = opener?.id;

    List<RegistrationModel> pool;

    // Arkadaşlar / Takipçiler / Tanımadıklarım mantığı
    if (normalized == 'arkadaşlar' || normalized == 'arkadaslar') {
      // Accepted friendships => karşılıklı arkadaşlar
      final friends = getAcceptedFriendships(openerId ?? '')
          .map((f) => f.requesterId == openerId ? f.recipientId : f.requesterId)
          .toSet();
      pool = getAllRegistrations()
          .where((r) => r.email != openerEmail && friends.contains(r.id))
          .toList();
    } else if (normalized == 'takipçiler' || normalized == 'takipciler') {
      // Followers => beni takip edenler
      final followers = getFollowers(openerId ?? '').map((f) => f.requesterId).toSet();
      pool = getAllRegistrations()
          .where((r) => r.email != openerEmail && followers.contains(r.id))
          .toList();
    } else if (normalized == 'tanımadıklarım' || normalized == 'tanimadiklarim') {
      // Tanımadıklarım => arkadaş ve takip ilişkisi olmayanlar
      final friendIds = getAcceptedFriendships(openerId ?? '')
          .expand((f) => [f.requesterId, f.recipientId])
          .toSet();
      final followerIds = getFollowers(openerId ?? '').map((f) => f.requesterId).toSet();
      final followingIds = getFollowingUsers(openerId ?? '').map((f) => f.recipientId).toSet();
      final exclude = <String>{}
        ..addAll(friendIds)
        ..addAll(followerIds)
        ..addAll(followingIds)
        ..add(openerId ?? '');
      pool = getAllRegistrations()
          .where((r) => !exclude.contains(r.id))
          .toList();
    } else {
      // Diğer grup adları için rastgele havuz (tüm kullanıcılar, opener hariç)
      pool = getAllRegistrations().where((r) => r.email != openerEmail).toList();
    }

    // Gizlilik ayarı: Bana Dava Açılsın filtresi
    final allowed = <RegistrationModel>[];
    for (final r in pool) {
      try {
        final s = await getOrCreateSettings(r.email);
        if (s.privacySettings['genel_davaacilsin'] ?? true) {
          allowed.add(r);
        }
      } catch (_) {
        allowed.add(r); // Hata olursa dahil et
      }
    }

    // Eğer seçilen kategoride kimse yoksa tüm kullanıcılardan rastgele 7 kişiye gönder (opener hariç)
    List<RegistrationModel> finalPool = allowed;
    if (finalPool.isEmpty) {
      // Fallback: açan ve davalı hariç tüm kullanıcılar
      var all = getAllRegistrations()
          .where((r) => r.email != openerEmail && (defendantEmail == null || r.email != defendantEmail))
          .toList();
      
      final fallback = <RegistrationModel>[];
      for (final r in all) {
        try {
          final s = await getOrCreateSettings(r.email);
          if (s.privacySettings['genel_davaacilsin'] ?? true) {
            fallback.add(r);
          }
        } catch (_) {
          fallback.add(r);
        }
      }
      finalPool = fallback;
    }

    // ✅ ADIM-3: Eğer dava açan mavi tik sahibi ise, önce mavi tik sahiplerini seç, 7'den azsa mavi tik sahibi olmayanlarla tamamla
    if (isOpenerVerified) {
      final verifiedUsers = finalPool.where((r) {
        return VerifiedUsersService.isVerified(r.judgeName);
      }).toList();
      
      final nonVerifiedUsers = finalPool.where((r) {
        return !VerifiedUsersService.isVerified(r.judgeName);
      }).toList();
      
      // Mavi tik sahiplerini karıştır
      verifiedUsers.shuffle();
      
      // Eğer 7'den az mavi tik sahibi varsa, mavi tik sahibi olmayanlarla tamamla
      if (verifiedUsers.length < count) {
        final remaining = count - verifiedUsers.length;
        nonVerifiedUsers.shuffle();
        final selectedNonVerified = nonVerifiedUsers.take(remaining).toList();
        finalPool = [...verifiedUsers, ...selectedNonVerified];
      } else {
        // 7 veya daha fazla mavi tik sahibi varsa, sadece onları kullan
        finalPool = verifiedUsers.take(count).toList();
      }
    }

    // Ülke önceliği ve tamamlama kuralı
    final openerCountry = opener?.country.trim().toLowerCase() ?? '';

    // "Herkes" seçildiyse: grup bağımsız, sadece aynı ülkeden global havuzdan seç
    if (normalized == 'herkes' && openerCountry.isNotEmpty) {
      final allRegs = getAllRegistrations()
          .where((r) => r.email != openerEmail && (defendantEmail == null || r.email != defendantEmail))
          .toList();
      
      final sameCountryGlobal = <RegistrationModel>[];
      for (final r in allRegs) {
        if (r.country.trim().toLowerCase() != openerCountry) continue;
        try {
          final s = await getOrCreateSettings(r.email);
          if (s.privacySettings['genel_davaacilsin'] ?? true) {
            sameCountryGlobal.add(r);
          }
        } catch (_) {
          sameCountryGlobal.add(r);
        }
      }
      
      // ✅ ADIM-5: "Herkes" seçildiğinde, eğer dava açan mavi tik sahibi ise, önce mavi tik sahiplerini seç, 7'den azsa mavi tik sahibi olmayanlarla tamamla
      if (isOpenerVerified) {
        final verifiedUsers = sameCountryGlobal.where((r) {
          return VerifiedUsersService.isVerified(r.judgeName);
        }).toList();
        
        final nonVerifiedUsers = sameCountryGlobal.where((r) {
          return !VerifiedUsersService.isVerified(r.judgeName);
        }).toList();
        
        // Mavi tik sahiplerini karıştır
        verifiedUsers.shuffle();
        
        // Eğer 7'den az mavi tik sahibi varsa, mavi tik sahibi olmayanlarla tamamla
        if (verifiedUsers.length < count) {
          final remaining = count - verifiedUsers.length;
          nonVerifiedUsers.shuffle();
          final selectedNonVerified = nonVerifiedUsers.take(remaining).toList();
          return [...verifiedUsers, ...selectedNonVerified];
        } else {
          // 7 veya daha fazla mavi tik sahibi varsa, sadece onları kullan
          return verifiedUsers.take(count).toList();
        }
      }
      
      // Normal kullanıcı için mevcut mantık
      sameCountryGlobal.shuffle();
      return sameCountryGlobal.take(count).toList();
    }

    // Diğer gruplar (Grup-19/Arkadaş/Takipçi): ülke şartı aranmaz, grup havuzundan rastgele seç
    var resultPool = finalPool;
    if (sameCountryOnly && openerCountry.isNotEmpty) {
      resultPool = resultPool
          .where((r) => r.country.trim().toLowerCase() == openerCountry)
          .toList();
    }

    resultPool.shuffle();
    if (resultPool.length <= count) return resultPool;
    return resultPool.take(count).toList();
  }

  /// Davet alıcıları seç (dava gönderilmeyen kişilerden)
  static Future<List<RegistrationModel>> pickInvitationRecipients(
    String openerEmail,
    String groupName, {
    required List<String> excludedEmails, // Dava gönderilen kişiler
  }) async {
    print('DEBUG: pickInvitationRecipients - opener: $openerEmail, group: $groupName');
    
    final normalized = groupName.toLowerCase().replaceAll('-', '').trim();
    final opener = getRegistrationByEmail(openerEmail);
    final openerCountry = opener?.country.trim().toLowerCase() ?? '';
    
    // ✅ ADIM-1: Dava açan kullanıcının mavi tik sahibi olup olmadığını kontrol et
    final openerJudgeName = opener?.judgeName ?? '';
    final isOpenerVerified = VerifiedUsersService.isVerified(openerJudgeName);
    
    print('DEBUG: normalized group: $normalized, opener ID: ${opener?.id}, isVerified: $isOpenerVerified');
    
    // Hedef sayılar (istenen kurallara göre)
    int targetCount;
    if (normalized == 'grup19') {
      targetCount = -1; // limitsiz (kişisel Grup-19 listesindeki herkes)
    } else if (normalized == 'arkadaşlar') {
      targetCount = 9;
    } else if (normalized == 'takipçiler') {
      targetCount = 7;
    } else if (normalized == 'herkes') {
      targetCount = 3;
    } else {
      // Diğer gruplar mevcut mantığı kullanabilir
      targetCount = 7;
    }

    List<RegistrationModel> pool = [];
    
    if (normalized == 'grup19') {
      // Opener'ın kişisel Grup-19 listesi: listedeki HERKESE gönder (davet gönderen kişi de dahil)
      final friendCategories = getFriendCategories(openerEmail);
      final grup19Emails = friendCategories.entries
          .where((entry) {
            final v = entry.value.toLowerCase();
            return v.contains('grup19') || v.contains('grup-19');
          })
          .map((e) => e.key)
          .toSet();
      pool = getAllRegistrations()
          .where((r) => grup19Emails.contains(r.email) &&
                       !excludedEmails.contains(r.email)) // ✅ Davet gönderen kişi de dahil
          .toList();
    } else if (normalized == 'arkadaşlar') {
      // Arkadaşlar - Kişisel listeden en fazla 9 kişi (daha az varsa o kadar)
      final friendCategories = getFriendCategories(openerEmail);
      print('DEBUG: All friend categories for $openerEmail: $friendCategories');
      
      final friendEmails = friendCategories.entries
          .where((entry) {
            final categoryLower = entry.value.toLowerCase();
            return categoryLower.contains('arkadaş') || 
                   categoryLower.contains('arkadas') ||
                   categoryLower.contains('friend') ||
                   categoryLower == 'arkadaş' ||
                   categoryLower == 'arkadaşlar';
          })
          .map((entry) => entry.key)
          .toSet();
      
      print('DEBUG: Found ${friendEmails.length} friends in personal list: $friendEmails');
      
      pool = getAllRegistrations()
          .where((r) => friendEmails.contains(r.email) && 
                       !excludedEmails.contains(r.email)) // ✅ Davet gönderen kişi de dahil
          .toList();
      
      
      // Herkes kategorisi mantığını uygula - debug çıktıları ekle
      print('DEBUG: Arkadaş pool after filtering: ${pool.length} users');
      for (final user in pool) {
        print('  - ${user.email} (${user.judgeName})');
      }
    } else if (normalized == 'takipçiler') {
      // Takipçiler - Kişisel listeden en fazla 7 kişi (daha az varsa o kadar)
      final friendCategories = getFriendCategories(openerEmail);
      print('DEBUG: All friend categories for $openerEmail: $friendCategories');
      
      final followerEmails = friendCategories.entries
          .where((entry) {
            final categoryLower = entry.value.toLowerCase();
            return categoryLower.contains('takipçi') || 
                   categoryLower.contains('takipci') ||
                   categoryLower.contains('takip') ||
                   categoryLower.contains('follower') ||
                   categoryLower == 'takipçi' ||
                   categoryLower == 'takipçiler';
          })
          .map((entry) => entry.key)
          .toSet();
      
      print('DEBUG: Found ${followerEmails.length} followers in personal list: $followerEmails');
      
      pool = getAllRegistrations()
          .where((r) => followerEmails.contains(r.email) && 
                       !excludedEmails.contains(r.email)) // ✅ Davet gönderen kişi de dahil
          .toList();
      
      print('DEBUG: Takipçi pool after filtering: ${pool.length} users');
      for (final user in pool) {
        print('  - ${user.email} (${user.judgeName})');
      }
    } else if (normalized == 'herkes') {
      // Herkes - Global havuzdan rastgele 3 kişi (ülke şartı yok, davet gönderen kişi de dahil)
      pool = getAllRegistrations()
          .where((r) => !excludedEmails.contains(r.email)) // ✅ Davet gönderen kişi de dahil
          .toList();
    } else if (normalized == 'tanımadıklarım') {
      // Tanımadıklarım - Kategorize edilmemiş kişiler (aynı ülke, maksimum 7 kişi)
      final friendCategories = getFriendCategories(openerEmail);
      final categorizedEmails = friendCategories.keys.toSet();
      
      pool = getAllRegistrations()
          .where((r) => !categorizedEmails.contains(r.email) &&
                       !excludedEmails.contains(r.email) && // ✅ Davet gönderen kişi de dahil
                       (openerCountry.isEmpty || r.country.trim().toLowerCase() == openerCountry))
          .toList();
    }

    // Eğer havuz boşsa: kişisel listeler için fallback yapma (0 döndür)
    if (pool.isEmpty) {
      print('DEBUG: Pool is empty, using fallback mechanism for group: $normalized');
      // Sadece "tanımadıklarım" ve tanımsız gruplar için önceki fallback korunabilir
      if (normalized == 'tanımadıklarım' || normalized == 'tanimadiklarim') {
        pool = getAllRegistrations()
            .where((r) => r.email != openerEmail && 
                         !excludedEmails.contains(r.email))
            .toList();
        
        print('DEBUG: Fallback pool size (tanımadıklarım): ${pool.length}');
      }
    }

    // Davet gizliliğini kontrol et: sadece "Dava Davetleri" açık olanlara gönder
    final filteredPool = <RegistrationModel>[];
    for (final r in pool) {
      try {
        final s = await getOrCreateSettings(r.email);
        if (s.privacySettings['davet_dava'] ?? true) {
          filteredPool.add(r);
        }
      } catch (_) {
        filteredPool.add(r);
      }
    }

    // Eğer hala boşsa, son fallback: tüm kullanıcılardan rastgele seç
    List<RegistrationModel> finalPool = filteredPool;
    if (finalPool.isEmpty) {
      print('DEBUG: Filtered pool is empty, using global fallback');
      var globalPool = getAllRegistrations()
          .where((r) => r.email != openerEmail && !excludedEmails.contains(r.email))
          .toList();
      
      // ✅ ADIM-8: Global fallback'te de mavi tik filtresi uygula
      if (isOpenerVerified) {
        globalPool = globalPool.where((r) {
          return VerifiedUsersService.isVerified(r.judgeName);
        }).toList();
      }
      
      for (final r in globalPool) {
        try {
          final s = await getOrCreateSettings(r.email);
          if (s.privacySettings['davet_dava'] ?? true) {
            finalPool.add(r);
          }
        } catch (_) {
          finalPool.add(r);
        }
      }
    }

    // ✅ ADIM-8: Eğer dava açan mavi tik sahibi ise, önce mavi tik sahiplerini seç, targetCount'tan azsa mavi tik sahibi olmayanlarla tamamla
    if (isOpenerVerified) {
      final verifiedUsers = finalPool.where((r) {
        return VerifiedUsersService.isVerified(r.judgeName);
      }).toList();
      
      final nonVerifiedUsers = finalPool.where((r) {
        return !VerifiedUsersService.isVerified(r.judgeName);
      }).toList();
      
      // Mavi tik sahiplerini karıştır
      verifiedUsers.shuffle();
      
      // Grup19 için limitsiz (targetCount == -1)
      if (targetCount == -1) {
        // Tüm mavi tik sahiplerini al, eğer yoksa mavi tik sahibi olmayanlarla tamamla
        if (verifiedUsers.isEmpty) {
          nonVerifiedUsers.shuffle();
          final result = nonVerifiedUsers;
          print('DEBUG: Final result (no verified, using non-verified): ${result.length} recipients selected');
          return result;
        } else {
          // Mavi tik sahiplerini al, eğer 7'den azsa mavi tik sahibi olmayanlarla tamamla
          if (verifiedUsers.length < 7) {
            final remaining = 7 - verifiedUsers.length;
            nonVerifiedUsers.shuffle();
            final selectedNonVerified = nonVerifiedUsers.take(remaining).toList();
            final result = [...verifiedUsers, ...selectedNonVerified];
            print('DEBUG: Final result (verified + non-verified): ${result.length} recipients selected');
            return result;
          } else {
            final result = verifiedUsers;
            print('DEBUG: Final result (all verified): ${result.length} recipients selected');
            return result;
          }
        }
      } else {
        // Diğer gruplar için targetCount kadar seç
        if (verifiedUsers.length < targetCount) {
          final remaining = targetCount - verifiedUsers.length;
          nonVerifiedUsers.shuffle();
          final selectedNonVerified = nonVerifiedUsers.take(remaining).toList();
          final result = [...verifiedUsers, ...selectedNonVerified];
          print('DEBUG: Final result (verified + non-verified): ${result.length} recipients selected');
          for (final user in result) {
            print('  - Selected: ${user.email} (${user.judgeName})');
          }
          return result;
        } else {
          // targetCount veya daha fazla mavi tik sahibi varsa, sadece onları kullan
          final result = verifiedUsers.take(targetCount).toList();
          print('DEBUG: Final result (all verified): ${result.length} recipients selected');
          for (final user in result) {
            print('  - Selected: ${user.email} (${user.judgeName})');
          }
          return result;
        }
      }
    }
    
    // Normal kullanıcı için mevcut mantık
    finalPool.shuffle();
    // Grup-19: limitsiz (kişisel listede kim varsa)
    final List<RegistrationModel> result = targetCount == -1
        ? finalPool
        : finalPool.take(targetCount).toList();
    
    print('DEBUG: Final result: ${result.length} recipients selected');
    for (final user in result) {
      print('  - Selected: ${user.email} (${user.judgeName})');
    }
    
    return result;
  }

  /// Davet kaydet - Email ve DavaID tutarlılığı sağlanır
  static void addInvitation(String userEmail, Map<String, dynamic> invitation) {
    print('DEBUG: addInvitation START - userEmail: $userEmail');
    print('DEBUG: addInvitation - invitation data: $invitation');
    
    // Email ve DavaID kontrolü - her ikisi de mevcut olmalı
    if (userEmail.isEmpty || invitation['davaId'] == null || invitation['davaId'].toString().isEmpty) {
      print('ERROR: addInvitation - userEmail veya davaId boş! userEmail: $userEmail, davaId: ${invitation['davaId']}');
      return;
    }
    
    // Davet verilerinde email ve davaId'nin tutarlı olduğundan emin ol
    invitation['userEmail'] = userEmail;
    invitation['davaId'] = invitation['davaId'].toString();
    
    final persisted = _incomingDavaBox?.get('${userEmail}_invitations');
    print('DEBUG: addInvitation - existing data: $persisted');
    
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];
    
    print('DEBUG: addInvitation - current list size: ${list.length}');
    
    // Aynı ID'li veya aynı davaId'li davet varsa güncelle, yoksa ekle
    final existingIndex = list.indexWhere((d) => 
        d['id'] == invitation['id'] || 
        (d['davaId'] == invitation['davaId'] && d['userEmail'] == userEmail));
    
    if (existingIndex != -1) {
      list[existingIndex] = invitation;
      print('DEBUG: addInvitation - updated existing invitation at index $existingIndex');
    } else {
      list.add(invitation);
      print('DEBUG: addInvitation - added new invitation, new size: ${list.length}');
    }
    
    final result = _incomingDavaBox?.put('${userEmail}_invitations', list);
    print('DEBUG: addInvitation - Hive put result: $result');
    print('DEBUG: addInvitation COMPLETE - saved invitation: ${invitation['davaAdi']} for $userEmail (davaId: ${invitation['davaId']})');
  }

  /// Kullanıcının davetlerini getir
  static List<Map<String, dynamic>> getInvitations(String userEmail) {
    try {
      print('DEBUG: getInvitations START - userEmail: $userEmail');
      
      final persisted = _incomingDavaBox?.get('${userEmail}_invitations');
      print('DEBUG: getInvitations - raw persisted data: $persisted');
      print('DEBUG: getInvitations - persisted type: ${persisted.runtimeType}');
      
      if (persisted != null) {
        final result = (persisted as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        
        print('DEBUG: getInvitations - converted to list, size: ${result.length}');
        
        // Eksik alanları varsayılan değerlerle doldur
        for (var invitation in result) {
          invitation['yorumSayisi'] ??= 0;
          invitation['retweetSayisi'] ??= 0;
          invitation['begeniSayisi'] ??= 0;
          invitation['begenmemeSayisi'] ??= 0;
          invitation['userLiked'] ??= false;
          invitation['userDisliked'] ??= false;
          invitation['isOpened'] ??= false;
          invitation['yorumlar'] ??= <Map<String, dynamic>>[];
          
          // Davet tarihini kontrol et ve ekle
          if (invitation['davetTarihi'] == null) {
            invitation['davetTarihi'] = DateTime.now().toIso8601String();
          }
        }
        
        // Tarihe göre sırala (en yeni üstte)
        result.sort((a, b) {
          final aTime = DateTime.tryParse(a['davetTarihi'] ?? '') ?? DateTime(1970);
          final bTime = DateTime.tryParse(b['davetTarihi'] ?? '') ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        
        print('DEBUG: getInvitations COMPLETE - returning ${result.length} invitations for $userEmail');
        for (int i = 0; i < result.length; i++) {
          print('  ${i + 1}. ${result[i]['davaAdi']} (ID: ${result[i]['id']})');
        }
        return result;
      } else {
        print('DEBUG: getInvitations - no invitations found for $userEmail');
        return <Map<String, dynamic>>[];
      }
    } catch (e) {
      print('ERROR: getInvitations($userEmail) - $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Bir daveti kalıcı olarak "bitmiş" işaretle
  /// - isFinished: true ve finishedAt: now alanlarını ekler
  static Future<void> markInvitationFinished({
    required String userEmail,
    required String davaId,
  }) async {
    try {
      final key = '${userEmail}_invitations';
      final persisted = _incomingDavaBox?.get(key);
      final List<Map<String, dynamic>> list = persisted != null
          ? (persisted as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : <Map<String, dynamic>>[];

      final index = list.indexWhere((d) =>
          (d['davaId']?.toString() ?? '') == davaId.toString() ||
          (d['id']?.toString() ?? '') == davaId.toString());
      if (index == -1) {
        return;
      }

      final updated = Map<String, dynamic>.from(list[index])
        ..['isFinished'] = true
        ..['finishedAt'] = DateTime.now().toIso8601String();
      list[index] = updated;
      await _incomingDavaBox?.put(key, list);
    } catch (_) {
      // no-op
    }
  }

  /// Aktif (bitirilmemiş) davetleri getir
  static List<Map<String, dynamic>> getActiveInvitations(String userEmail) {
    final all = getInvitations(userEmail);
    return all.where((inv) => (inv['isFinished'] ?? false) != true).toList();
  }

  // ========== DEBUG ARAÇLARI ==========
  /// Belirtilen kullanıcının gelen davalarını konsola yazdırır (kalıcı kutudan okunur)
  static void debugPrintIncomingFor(String userEmail, {bool withDetails = true}) {
    try {
      final list = getIncomingDavalar(userEmail);
      // Özet satırı
      // ignore: avoid_print
      print('[incoming_dava_box] $userEmail -> ${list.length} kayıt');
      if (!withDetails) return;
      for (final d in list) {
        final id = d['id'];
        final adi = d['adi'] ?? d['davaAdi'];
        final davali = d['davali'];
        final openedAt = d['openedAt'];
        // ignore: avoid_print
        print('  - id=$id | adi=$adi | davali=$davali | openedAt=$openedAt');
      }
    } catch (e) {
      // ignore: avoid_print
      print('debugPrintIncomingFor hata: $e');
    }
  }
  
  /// Hive box'a erişim için getter
  static Box? getIncomingDavaBox() {
    return _incomingDavaBox;
  }

  // ========== TEST VE DEBUG ARAÇLARI ==========
  
  /// Test amaçlı arkadaş kategorileri oluştur
  static Future<void> createTestFriendCategories(String ownerEmail) async {
    print('DEBUG: Creating test friend categories for $ownerEmail');
    
    // Mevcut tüm kullanıcıları al
    final allUsers = getAllRegistrations();
    final otherUsers = allUsers.where((u) => u.email != ownerEmail).toList();
    
    if (otherUsers.isEmpty) {
      print('DEBUG: No other users found for creating test categories');
      return;
    }
    
    // Kategorilere dağıt
    final categories = ['arkadaş', 'takipçi', 'herkes'];
    final Map<String, String> friendCategories = {};
    
    for (int i = 0; i < otherUsers.length && i < 15; i++) {
      final category = categories[i % categories.length];
      friendCategories[otherUsers[i].email] = category;
      print('DEBUG: Added ${otherUsers[i].email} to category: $category');
    }
    
    // Kategorileri kaydet
    await _friendGroupBox?.put(ownerEmail, friendCategories);
    print('DEBUG: Saved ${friendCategories.length} friend categories for $ownerEmail');
  }
  
  /// Kullanıcının arkadaş kategorilerini debug et
  static void debugFriendCategories(String ownerEmail) {
    final categories = getFriendCategories(ownerEmail);
    print('DEBUG: Friend categories for $ownerEmail (${categories.length} total):');
    
    final grouped = <String, List<String>>{};
    categories.forEach((email, category) {
      grouped.putIfAbsent(category, () => []).add(email);
    });
    
    grouped.forEach((category, emails) {
      print('  $category: ${emails.length} kişi - ${emails.take(3).join(', ')}${emails.length > 3 ? '...' : ''}');
    });
  }
  
  /// Davet sistemini test et
  static Future<void> testInvitationSystem(String userEmail) async {
    print('\n=== DAVET SİSTEMİ TEST BAŞLADI ===');
    print('Test kullanıcısı: $userEmail');
    
    // 1. Arkadaş kategorilerini kontrol et
    debugFriendCategories(userEmail);
    
    // 2. Eğer kategoriler boşsa test kategorileri oluştur
    final categories = getFriendCategories(userEmail);
    if (categories.isEmpty) {
      print('Arkadaş kategorileri boş, test kategorileri oluşturuluyor...');
      await createTestFriendCategories(userEmail);
      debugFriendCategories(userEmail);
    }
    
    // 3. Her grup için davet alıcılarını test et
    final testGroups = ['Grup19', 'Arkadaşlar', 'Takipçiler', 'Herkes', 'Tanımadıklarım'];
    
    for (final group in testGroups) {
      print('\n--- Test: $group grubu ---');
      try {
        final recipients = await pickInvitationRecipients(
          userEmail,
          group,
          excludedEmails: [userEmail], // Sadece kendisini hariç tut
        );
        print('✅ $group: ${recipients.length} alıcı seçildi');
        for (final recipient in recipients.take(3)) {
          print('  - ${recipient.email} (${recipient.judgeName})');
        }
        if (recipients.length > 3) {
          print('  ... ve ${recipients.length - 3} kişi daha');
        }
      } catch (e) {
        print('❌ $group: Hata - $e');
      }
    }
    
    print('\n=== DAVET SİSTEMİ TEST TAMAMLANDI ===\n');
  }
  
  /// Belirli kullanıcılar için davet durumunu kontrol et
  static void debugInvitationStatus(String senderEmail, List<String> recipientEmails) {
    print('\n=== DAVET DURUMU KONTROLÜ ===');
    print('Gönderen: $senderEmail');
    
    // Gönderenin arkadaş kategorilerini kontrol et
    debugFriendCategories(senderEmail);
    
    // Her alıcı için davet durumunu kontrol et
    for (final recipientEmail in recipientEmails) {
      print('\n--- $recipientEmail için davet kontrolü ---');
      
      // Bu kişinin davetlerini kontrol et
      final invitations = getInvitations(recipientEmail);
      print('Toplam davet sayısı: ${invitations.length}');
      
      // Gönderenden gelen davetleri filtrele
      final fromSender = invitations.where((inv) => 
          inv['davaci'] == senderEmail || 
          inv['userEmail'] == senderEmail).toList();
      
      print('$senderEmail\'den gelen davetler: ${fromSender.length}');
      
      for (final inv in fromSender) {
        print('  - Dava: ${inv['davaAdi']} (ID: ${inv['davaId']})');
        print('    Grup: ${inv['groupName']}');
        print('    Tarih: ${inv['invitedAt']}');
      }
      
      if (fromSender.isEmpty) {
        print('❌ Bu kişiye $senderEmail\'den davet gelmemiş!');
        
        // Kişisel kategorilerde var mı kontrol et
        final senderCategories = getFriendCategories(senderEmail);
        final isInCategories = senderCategories.containsKey(recipientEmail);
        
        if (isInCategories) {
          print('✅ Kişi gönderenin kategorilerinde mevcut: ${senderCategories[recipientEmail]}');
        } else {
          print('❌ Kişi gönderenin kategorilerinde YOK!');
        }
      }
    }
    
    print('\n=== DAVET DURUMU KONTROLÜ TAMAMLANDI ===\n');
  }

  // ==================== RED EDİLEN DAVALAR ====================

  /// Red edilen dava kaydet
  static Future<void> saveRejectedDava(Map<String, dynamic> dava) async {
    await _ensureRejectedDavaBoxOpen();
    final userEmail = dava['davaci'] ?? dava['userEmail'] ?? 'unknown';
    final key = userEmail;
    
    final persisted = _rejectedDavaBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    
    list.add(dava);
    _rejectedDavaBox?.put(key, list);
  }

  /// Red edilen davaları getir
  static Future<List<Map<String, dynamic>>> getRejectedDavalar(String userEmail) async {
    await _ensureRejectedDavaBoxOpen();
    final key = userEmail;
    final persisted = _rejectedDavaBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Belirli bir dava için reddeden kullanıcıları getir
  static Future<List<Map<String, dynamic>>> _getDavaRejectersInternal(String davaId) async {
    final participants = await getDavaParticipants(davaId);
    return participants
        .where((p) {
          final status = p['status']?.toString();
          return status == 'rejected' || status == 'manual_rejected' || status == 'auto_rejected';
        })
        .toList();
  }

  /// Gelen davadan kaldır
  static Future<void> removeIncomingDava(String davaId) async {
    await _ensureIncomingDavaBoxOpen();
    // Tüm kullanıcıların gelen davalarından kaldır
    final keys = _incomingDavaBox?.keys.toList() ?? [];
    int totalRemoved = 0;
    
    for (final key in keys) {
      final persisted = _incomingDavaBox?.get(key);
      if (persisted != null) {
        final List<Map<String, dynamic>> list = (persisted as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        
        final beforeCount = list.length;
        // Hem 'id' hem 'davaId' alanlarını kontrol et
        list.removeWhere((dava) {
          final itemId = dava['id']?.toString() ?? '';
          final itemDavaId = dava['davaId']?.toString() ?? '';
          return itemId == davaId || itemDavaId == davaId;
        });
        final afterCount = list.length;
        final removed = beforeCount - afterCount;
        
        if (removed > 0) {
          totalRemoved += removed;
          _incomingDavaBox?.put(key, list);
          print('✅ [HiveDatabaseService] removeIncomingDava: $key kullanıcısından $removed dava kaldırıldı (ID: $davaId)');
        }
      }
    }
    
    if (totalRemoved > 0) {
      print('✅ [HiveDatabaseService] removeIncomingDava: Toplam $totalRemoved dava kaldırıldı (ID: $davaId)');
    } else {
      print('⚠️ [HiveDatabaseService] removeIncomingDava: Hiç dava kaldırılamadı (ID: $davaId)');
    }
  }

  /// Yalnızca belirtilen kullanıcının gelen davasından kaldırır.
  static Future<bool> removeIncomingDavaForUser(
    String userEmail,
    String davaId,
  ) async {
    await _ensureIncomingDavaBoxOpen();
    final persisted = _incomingDavaBox?.get(userEmail);
    if (persisted == null) return false;

    final List<Map<String, dynamic>> list = (persisted as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final before = list.length;
    list.removeWhere((dava) {
      final itemId = dava['id']?.toString() ?? '';
      final itemDavaId = dava['davaId']?.toString() ?? '';
      return itemId == davaId || itemDavaId == davaId;
    });
    if (list.length == before) return false;
    _incomingDavaBox?.put(userEmail, list);
    _incomingDavalarByUser[userEmail] = List<Map<String, dynamic>>.from(list);
    return true;
  }

  /// Gelen dava box'ını aç
  static Future<void> _ensureIncomingDavaBoxOpen() async {
    if (_incomingDavaBox == null || !_incomingDavaBox!.isOpen) {
      _incomingDavaBox = await Hive.openBox(_incomingDavaBoxName);
    }
  }

  /// Red edilen dava box'ını aç
  static Future<void> _ensureRejectedDavaBoxOpen() async {
    if (_rejectedDavaBox == null || !_rejectedDavaBox!.isOpen) {
      _rejectedDavaBox = await Hive.openBox(_rejectedDavaBoxName);
    _katildigimDavaBox = await Hive.openBox(_katildigimDavaBoxName);
    }
  }

  // ==================== KABUL EDİLEN DAVALAR ====================

  /// Kabul edilen dava kaydet
  static Future<void> saveAcceptedDava(Map<String, dynamic> dava) async {
    await _ensureAcceptedDavaBoxOpen();
    final userEmail = dava['userEmail'] ?? dava['davaci'] ?? 'unknown';
    final key = userEmail;
    
    final persisted = _acceptedDavaBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    
    list.add(dava);
    _acceptedDavaBox?.put(key, list);
  }

  /// Kabul edilen davaları getir
  static Future<List<Map<String, dynamic>>> getAcceptedDavalar(String userEmail) async {
    await _ensureAcceptedDavaBoxOpen();
    final key = userEmail;
    final persisted = _acceptedDavaBox?.get(key);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return List<Map<String, dynamic>>.from(list);
  }

  /// Belirli bir kabul edilen davayı ID ile getir
  static Future<Map<String, dynamic>?> getAcceptedDavaById(String davaId) async {
    await _ensureAcceptedDavaBoxOpen();
    
    final keys = _acceptedDavaBox?.keys.toList() ?? [];
    for (final key in keys) {
      final list = _acceptedDavaBox?.get(key);
      if (list != null) {
        final List<Map<String, dynamic>> davalar = 
            (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        
        try {
          return davalar.firstWhere(
            (d) => (d['id']?.toString() ?? '') == davaId || 
                   (d['davaId']?.toString() ?? '') == davaId,
          );
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  /// Kabul edilen davayı güncelle
  static Future<void> updateAcceptedDava(String davaId, Map<String, dynamic> updatedData) async {
    await _ensureAcceptedDavaBoxOpen();
    
    final keys = _acceptedDavaBox?.keys.toList() ?? [];
    for (final key in keys) {
      final list = _acceptedDavaBox?.get(key);
      if (list != null) {
        final List<Map<String, dynamic>> davalar = 
            (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        
        final index = davalar.indexWhere(
          (d) => (d['id']?.toString() ?? '') == davaId || 
                 (d['davaId']?.toString() ?? '') == davaId,
        );
        
        if (index != -1) {
          davalar[index] = {...davalar[index], ...updatedData};
          _acceptedDavaBox?.put(key, davalar);
          return;
        }
      }
    }
  }

  /// Kabul edilen dava box'ını aç
  static Future<void> _ensureAcceptedDavaBoxOpen() async {
    if (_acceptedDavaBox == null || !_acceptedDavaBox!.isOpen) {
      _acceptedDavaBox = await Hive.openBox(_acceptedDavaBoxName);
    }
  }

  // ==================== HÜKÜM İŞLEMLERİ ====================

  /// Hüküm box'ını aç
  static Future<void> _ensureHukumBoxOpen() async {
    if (_hukumBox == null || !_hukumBox!.isOpen) {
      _hukumBox = await Hive.openBox(_hukumBoxName);
    }
  }

  /// Debug: Tüm hüküm key'lerini getir (ilk N tanesi)
  static Future<List<String>> getAllHukumKeys({int limit = 50}) async {
    await _ensureHukumBoxOpen();
    final keys = _hukumBox?.keys.toList() ?? [];
    return keys.take(limit).map((k) => k.toString()).toList();
  }

  /// Hüküm kaydet
  /// key: davaId_userRole (örn: "dava_123_Yargıç")
  static Future<void> saveHukum({
    required String davaId,
    required String userRole,
    required String hukumText,
    required String userEmail,
    String? hukumSentiment,
    bool isFinalized = false,
  }) async {
    await _ensureHukumBoxOpen();
    
    final key = '${davaId}_$userRole';
    final existingData = _hukumBox?.get(key) as Map<dynamic, dynamic>?;
    final dynamic existingFinalizedValue = existingData?['isFinalized'];
    final bool persistedFinalized = existingFinalizedValue is bool
        ? existingFinalizedValue
        : (existingFinalizedValue is int
            ? existingFinalizedValue != 0
            : (existingFinalizedValue?.toString().toLowerCase().trim() ==
                'true'));
    if (persistedFinalized) {
      final String? existingText = existingData?['hukumText']?.toString();
      if (existingText != null && existingText != hukumText) {
        print('⚠️ [HiveDatabaseService] Finalize edilmiş hüküm değiştirilemez: $key');
        return;
      }
    }
    final createdAt = existingData?['createdAt']?.toString() ?? DateTime.now().toIso8601String();
    final bool finalizationState = isFinalized || persistedFinalized;
    final hukumData = {
      'davaId': davaId,
      'userRole': userRole,
      'hukumText': hukumText,
      'userEmail': userEmail,
      'createdAt': createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
      if (hukumSentiment != null) 'hukumSentiment': hukumSentiment,
      'isFinalized': finalizationState,
    };
    
    _hukumBox?.put(key, hukumData);
    print('✅ [HiveDatabaseService] Hüküm kaydedildi:');
    print('   - Key: $key');
    print('   - Dava ID: $davaId');
    print('   - User Role: $userRole');
    print('   - Hüküm Text: ${hukumText.length > 50 ? hukumText.substring(0, 50) : hukumText}...');
    print('   - Sentiment: ${hukumSentiment ?? "null"}');
    print('   - Is Finalized: $finalizationState');
  }

  /// Belirli bir dava için hükümleri getir
  static Future<List<Map<String, dynamic>>> getHukumlerByDavaId(String davaId) async {
    await _ensureHukumBoxOpen();
    
    final List<Map<String, dynamic>> hukumler = [];
    final keys = _hukumBox?.keys.toList() ?? [];
    
    for (final key in keys) {
      if (key.toString().startsWith('${davaId}_')) {
        final hukumData = _hukumBox?.get(key);
        if (hukumData != null) {
          hukumler.add(Map<String, dynamic>.from(hukumData as Map));
        }
      }
    }
    
    return hukumler;
  }

  /// Belirli bir dava ve mevki için hükmü getir
  /// Eğer davaId ile bulunamazsa, davaAdi'ne göre de arama yapar
  static Future<Map<String, dynamic>?> getHukumByDavaIdAndRole(String davaId, String userRole, {String? davaAdi}) async {
    await _ensureHukumBoxOpen();
    
    // Önce davaId ile ara
    final key = '${davaId}_$userRole';
    final hukumData = _hukumBox?.get(key);
    
    if (hukumData != null) {
      return Map<String, dynamic>.from(hukumData as Map);
    }
    
    // Eğer bulunamadıysa ve davaAdi verildiyse, davaAdi hash'i ile ara
    if (davaAdi != null && davaAdi.isNotEmpty) {
      final alternativeId = 'dava_${davaAdi.hashCode}';
      final alternativeKey = '${alternativeId}_$userRole';
      final alternativeHukumData = _hukumBox?.get(alternativeKey);
      
      if (alternativeHukumData != null) {
        print('   ✅ Alternatif ID ile hüküm bulundu: Key="$alternativeKey"');
        return Map<String, dynamic>.from(alternativeHukumData as Map);
      }
    }
    
    return null;
  }

  /// Bir dava için tüm hükümleri getir (mevkiye göre)
  /// Eğer davaId ile bulunamazsa, davaAdi'ne göre de arama yapar
  static Future<Map<String, Map<String, dynamic>>> getHukumlerByDavaIdGrouped(String davaId, {String? davaAdi}) async {
    await _ensureHukumBoxOpen();
    
    print('🔍 [HiveDatabaseService] getHukumlerByDavaIdGrouped çağrıldı:');
    print('   - Dava ID: "$davaId"');
    if (davaAdi != null) {
      print('   - Dava Adı: "$davaAdi"');
    }
    
    final Map<String, Map<String, dynamic>> hukumlerByRole = {};
    final keys = _hukumBox?.keys.toList() ?? [];
    
    print('   - Toplam key sayısı: ${keys.length}');
    
    // Debug: Tüm key'leri logla (ilk 10 tanesi)
    if (keys.isNotEmpty) {
      print('   🔍 Veritabanındaki key\'ler (ilk 10):');
      for (int i = 0; i < keys.length && i < 10; i++) {
        print('      ${i + 1}. ${keys[i]}');
      }
    }
    
    int matchCount = 0;
    // Önce davaId ile ara
    for (final key in keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('${davaId}_')) {
        matchCount++;
        final hukumData = _hukumBox?.get(key);
        if (hukumData != null) {
          final hukumMap = Map<String, dynamic>.from(hukumData as Map);
          final userRole = hukumMap['userRole'] as String? ?? '';
          if (userRole.isNotEmpty) {
            hukumlerByRole[userRole] = hukumMap;
            print('   ✅ Eşleşme bulundu: Key="$keyStr", Role="$userRole"');
          }
        }
      }
    }
    
    // Eğer davaId ile bulunamadıysa ve davaAdi verildiyse, davaAdi hash'i ile ara
    if (hukumlerByRole.isEmpty && davaAdi != null && davaAdi.isNotEmpty) {
      final alternativeId = 'dava_${davaAdi.hashCode}';
      print('   ⚠️ Dava ID ile bulunamadı, dava adı hash ile deneniyor: "$alternativeId"');
      
      for (final key in keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('${alternativeId}_')) {
          matchCount++;
          final hukumData = _hukumBox?.get(key);
          if (hukumData != null) {
            final hukumMap = Map<String, dynamic>.from(hukumData as Map);
            final userRole = hukumMap['userRole'] as String? ?? '';
            if (userRole.isNotEmpty) {
              hukumlerByRole[userRole] = hukumMap;
              print('   ✅ Alternatif ID ile eşleşme bulundu: Key="$keyStr", Role="$userRole"');
            }
          }
        }
      }
      
      // Eğer hala bulunamadıysa, tüm key'leri kontrol et ve dava adına göre eşleştir
      if (hukumlerByRole.isEmpty) {
        print('   🔍 Tüm key\'ler kontrol ediliyor (dava adı eşleştirmesi için)...');
        final davaAdiHash = davaAdi.hashCode;
        final davaAdiHashWithoutComma = davaAdi.replaceAll(',', '').trim().hashCode;
        final davaAdiHashClean = davaAdi.replaceAll(RegExp(r'[^\w\s]'), '').trim().hashCode;
        
        print('   🔍 Dava adı hash\'leri:');
        print('      - Orijinal: $davaAdiHash');
        print('      - Virgülsüz: $davaAdiHashWithoutComma');
        print('      - Temizlenmiş: $davaAdiHashClean');
        
        // Önce tüm key'leri logla
        print('   🔍 Veritabanındaki tüm key\'ler:');
        for (int i = 0; i < keys.length; i++) {
          print('      ${i + 1}. ${keys[i]}');
        }
        
        for (final key in keys) {
          final keyStr = key.toString();
          // Key formatı: "davaId_userRole" veya "davaId_Role"
          // Örnek: "dava_1763765980367_Yargıç Kararı"
          // Key'i "_" ile böl, son kısım rol adı, önceki kısımlar dava ID'si
          final parts = keyStr.split('_');
          if (parts.length >= 2) {
            // Son kısmı (rol adı) çıkar, kalan kısımları birleştir (dava ID'si)
            // "dava_1763765980367_Yargıç Kararı" -> ["dava", "1763765980367", "Yargıç", "Kararı"]
            // extractedDavaId = "dava_1763765980367"
            final extractedDavaId = parts.sublist(0, parts.length - 1).join('_');
            
            print('   🔍 Key analizi: "$keyStr" -> Dava ID: "$extractedDavaId"');
            
            // Eğer dava ID'si "dava_" ile başlıyorsa, hash'i çıkar
            if (extractedDavaId.startsWith('dava_')) {
              final hashStr = extractedDavaId.replaceFirst('dava_', '');
              final hash = int.tryParse(hashStr);
              
              print('   🔍 Hash analizi: "$hashStr" -> $hash');
              
              if (hash != null && 
                  (hash == davaAdiHash || 
                   hash == davaAdiHashWithoutComma || 
                   hash == davaAdiHashClean)) {
                print('   ✅ Hash eşleşmesi bulundu! Key: "$keyStr", Dava ID: "$extractedDavaId"');
                final hukumData = _hukumBox?.get(key);
                if (hukumData != null) {
                  final hukumMap = Map<String, dynamic>.from(hukumData as Map);
                  final userRole = hukumMap['userRole'] as String? ?? '';
                  if (userRole.isNotEmpty) {
                    hukumlerByRole[userRole] = hukumMap;
                    print('   ✅ Eşleşme eklendi: Role="$userRole"');
                  }
                }
              } else {
                // Hash eşleşmedi, ancak dava ID'sini direkt kontrol et
                // Eğer extractedDavaId, davaAdi hash'i ile eşleşiyorsa
                final extractedHash = int.tryParse(hashStr);
                if (extractedHash != null) {
                  print('   ⚠️ Hash eşleşmedi: extracted=$extractedHash, davaAdi=$davaAdiHash');
                }
              }
            } else {
              // Dava ID'si "dava_" ile başlamıyor, direkt kontrol et
              print('   ⚠️ Key "dava_" ile başlamıyor: "$extractedDavaId"');
            }
          } else {
            print('   ⚠️ Key formatı beklenmeyen: "$keyStr" (parts: ${parts.length})');
          }
        }
      }
    }
    
    print('   - Eşleşen key sayısı: $matchCount');
    print('   - Dönen hüküm sayısı: ${hukumlerByRole.length}');
    
    return hukumlerByRole;
  }

  // ==================== KATILDIĞIM DAVALAR ====================

  /// Katıldığım dava box'ını aç
  static Future<void> _ensureKatildigimDavaBoxOpen() async {
    if (_katildigimDavaBox == null || !_katildigimDavaBox!.isOpen) {
      _katildigimDavaBox = await Hive.openBox(_katildigimDavaBoxName);
    }
  }

  /// Katıldığım dava ekle
  static Future<void> addKatildigimDava(String userEmail, Map<String, dynamic> dava) async {
    await _ensureKatildigimDavaBoxOpen();
    
    // Mevcut katıldığım davaları al
    final existingList = _katildigimDavaBox!.get(userEmail) as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> davaList = existingList.map((item) {
      if (item is Map) {
        final safeMap = <String, dynamic>{};
        item.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        return safeMap;
      }
      return <String, dynamic>{};
    }).toList();

    // Yeni dava ekle
    davaList.add(dava);
    
    // Güncellenmiş listeyi kaydet
    _katildigimDavaBox!.put(userEmail, davaList);
    
    print('✅ Katıldığım dava eklendi: ${dava['adi']}');
  }

  static bool _isLegacyKatildigimTestRow(Map<String, dynamic> d) {
    final src = d['source']?.toString();
    final id = (d['id'] ?? d['davaId'] ?? '').toString();
    return src == 'test_data' ||
        id == 'test_dava_1' ||
        id == 'test_dava_2';
  }

  /// Eski örnek/test katılım satırlarını siler (`test_data`, test_dava_*).
  static Future<void> purgeLegacyKatildigimTestRows(String userEmail) async {
    final key = userEmail.trim();
    if (key.isEmpty) return;
    await _ensureKatildigimDavaBoxOpen();
    final list = getKatildigimDavalar(key);
    final filtered =
        list.where((d) => !_isLegacyKatildigimTestRow(d)).toList();
    if (filtered.length == list.length) return;
    _katildigimDavaBox!.put(key, filtered);
    print(
      '🧹 Eski test katıldığım dava kayıtları silindi: ${list.length - filtered.length}',
    );
  }

  /// Katıldığım davaları getir
  static List<Map<String, dynamic>> getKatildigimDavalar(String userEmail) {
    if (_katildigimDavaBox == null || !_katildigimDavaBox!.isOpen) {
      return <Map<String, dynamic>>[];
    }
    
    final list = _katildigimDavaBox!.get(userEmail) as List<dynamic>? ?? [];
    return list.map((item) {
      if (item is Map) {
        final safeMap = <String, dynamic>{};
        item.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        return safeMap;
      }
      return <String, dynamic>{};
    }).toList();
  }

  static const List<String> _sekizStandartRoller = <String>[
    'Temyiz hakimi',
    'Yargıç',
    'Davacı avukatı',
    'Davalı avukatı',
    '1.Jüri',
    '2.Jüri',
    'Davacı Şahidi',
    'Davalı Şahidi',
  ];

  static bool _isSekizStandartRol(String? mevkii) {
    final role = (mevkii ?? '').trim();
    if (role.isEmpty) return false;
    final compact = _compactMevkii(role);
    for (final standard in _sekizStandartRoller) {
      if (_compactMevkii(standard) == compact) {
        return true;
      }
    }
    return false;
  }

  static String _compactMevkii(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u');
  }

  /// Kullanıcının 8 standart rolden biriyle kabul ettiği dava kayıtları (davaId başına tek).
  static Future<List<Map<String, dynamic>>> getSekizRolKatilimKayitlari(
    String userEmail,
  ) async {
    final normalizedEmail = userEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final Map<String, Map<String, dynamic>> byDavaId =
        <String, Map<String, dynamic>>{};

    void mergeKayit(String davaId, Map<String, dynamic> meta) {
      if (davaId.isEmpty) return;
      byDavaId[davaId] = <String, dynamic>{
        ...?byDavaId[davaId],
        ...meta,
        'davaId': davaId,
        'id': davaId,
      };
    }

    for (final dava in getKatildigimDavalar(userEmail)) {
      final davaId =
          (dava['id'] ?? dava['davaId'] ?? '').toString().trim();
      final mevkii =
          (dava['mevkii'] ?? dava['userRole'] ?? '').toString();
      if (_isSekizStandartRol(mevkii)) {
        mergeKayit(davaId, dava);
      }
    }

    await _ensureDavaParticipantBoxOpen();
    final keys = _davaParticipantBox?.keys.toList() ?? <dynamic>[];
    for (final key in keys) {
      final davaId = key.toString().trim();
      if (davaId.isEmpty) continue;
      final participants =
          await getDavaParticipants(davaId, normalizeExpired: false);
      for (final participant in participants) {
        final pEmail =
            (participant['userEmail'] ?? '').toString().trim().toLowerCase();
        if (pEmail != normalizedEmail) continue;
        final status = (participant['status'] ?? '').toString();
        if (status != 'accepted') continue;
        final mevkii =
            (participant['mevkii'] ?? participant['userRole'] ?? '')
                .toString();
        if (!_isSekizStandartRol(mevkii)) {
          continue;
        }
        final opened = getOpenedDavaById(davaId);
        mergeKayit(
          davaId,
          <String, dynamic>{
            if (opened != null) ...opened,
            ...participant,
            'mevkii': mevkii,
          },
        );
      }
    }

    return byDavaId.values.toList();
  }

  /// Kullanıcının davalı olduğu (bana açılan) benzersiz dava sayısı.
  static int countBanaAcilanDavalar(String userEmail) {
    final normalizedEmail = userEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return 0;

    final Set<String> davaIds = <String>{};

    void tryAdd(Map<String, dynamic> dava) {
      final id = (dava['id'] ?? dava['davaId'] ?? '').toString().trim();
      if (id.isEmpty) return;
      if (_isUserDefendantInDava(dava, normalizedEmail)) {
        davaIds.add(id);
      }
    }

    for (final dava in getOpenedDavalar()) {
      tryAdd(dava);
    }

    for (final dava in getIncomingDavalar(userEmail)) {
      tryAdd(dava);
    }

    for (final dava in getKatildigimDavalar(userEmail)) {
      tryAdd(dava);
    }

    return davaIds.length;
  }

  static bool _isUserDefendantInDava(
    Map<String, dynamic> dava,
    String normalizedEmail,
  ) {
    final davaliEmail =
        (dava['davaliEmail'] ?? '').toString().trim().toLowerCase();
    if (davaliEmail.isNotEmpty && davaliEmail == normalizedEmail) {
      return true;
    }

    final davaliRaw = (dava['davali'] ?? '').toString().trim();
    if (davaliRaw.isEmpty) return false;

    final davaliLower = davaliRaw.toLowerCase();
    if (davaliLower == normalizedEmail) return true;
    if (davaliRaw.contains('@') && davaliLower == normalizedEmail) {
      return true;
    }

    final user = getRegistrationByEmail(normalizedEmail);
    if (user != null &&
        user.judgeName.trim().toLowerCase() == davaliLower) {
      return true;
    }

    return false;
  }

  /// Katıldığım dava sil
  static Future<void> removeKatildigimDava(String userEmail, String davaId) async {
    await _ensureKatildigimDavaBoxOpen();
    
    final existingList = _katildigimDavaBox!.get(userEmail) as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> davaList = existingList.map((item) {
      if (item is Map) {
        final safeMap = <String, dynamic>{};
        item.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        return safeMap;
      }
      return <String, dynamic>{};
    }).toList();

    // Belirtilen dava ID'sine sahip dava'yı kaldır (id veya davaId)
    davaList.removeWhere((dava) {
      final id = dava['id']?.toString() ?? '';
      final did = dava['davaId']?.toString() ?? '';
      return id == davaId || did == davaId;
    });
    
    // Güncellenmiş listeyi kaydet
    _katildigimDavaBox!.put(userEmail, davaList);
    
    print('✅ Katıldığım dava silindi: $davaId');
  }

  // ==================== KATILDIĞIM HAYKIRLAR ====================

  /// ✅ Adım 1: Katıldığım haykır box'ını aç
  static Future<void> _ensureKatildigimHaykirBoxOpen() async {
    if (_katildigimHaykirBox == null || !_katildigimHaykirBox!.isOpen) {
      _katildigimHaykirBox = await Hive.openBox(_katildigimHaykirBoxName);
    }
  }

  /// ✅ Adım 2: Katıldığım haykır ekle
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> addKatildigimHaykir(String userEmail, Map<String, dynamic> haykir) async {
    await _ensureKatildigimHaykirBoxOpen();
    
    // Mevcut katıldığım haykırları al
    final existingList = _katildigimHaykirBox!.get(userEmail) as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> haykirList = existingList.map((item) {
      if (item is Map) {
        final safeMap = <String, dynamic>{};
        item.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        return safeMap;
      }
      return <String, dynamic>{};
    }).toList();

    // Aynı haykır zaten varsa ekleme
    final haykirId = haykir['haykirId']?.toString() ?? haykir['id']?.toString() ?? '';
    if (haykirId.isNotEmpty) {
      final exists = haykirList.any((h) => 
        (h['haykirId']?.toString() ?? h['id']?.toString() ?? '') == haykirId
      );
      if (exists) {
        print('⚠️ Bu haykır zaten katıldığım listesinde: $haykirId');
        return;
      }
    }

    // Yeni haykır ekle
    haykir['participatedAt'] = DateTime.now().toIso8601String();
    haykirList.add(haykir);
    
    // Güncellenmiş listeyi kaydet
    _katildigimHaykirBox!.put(userEmail, haykirList);
    
    print('✅ Katıldığım haykır eklendi: ${haykir['adi'] ?? haykirId}');
  }

  /// ✅ Adım 3: Katıldığım haykırları getir
  static List<Map<String, dynamic>> getKatildigimHaykirler(String userEmail) {
    if (_katildigimHaykirBox == null || !_katildigimHaykirBox!.isOpen) {
      return <Map<String, dynamic>>[];
    }
    
    final list = _katildigimHaykirBox!.get(userEmail) as List<dynamic>? ?? [];
    return list.map((item) {
      if (item is Map) {
        final safeMap = <String, dynamic>{};
        item.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        return safeMap;
      }
      return <String, dynamic>{};
    }).toList();
  }

  /// ✅ Adım 4: Katıldığım haykır sil
  /// ✅ Veritabanından kalıcı olarak kaldırılıyor
  static Future<void> removeKatildigimHaykir(String userEmail, String haykirId) async {
    await _ensureKatildigimHaykirBoxOpen();
    
    final existingList = _katildigimHaykirBox!.get(userEmail) as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> haykirList = existingList.map((item) {
      if (item is Map) {
        final safeMap = <String, dynamic>{};
        item.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        return safeMap;
      }
      return <String, dynamic>{};
    }).toList();

    // Belirtilen haykır ID'sine sahip haykır'ı kaldır
    haykirList.removeWhere((haykir) => 
      (haykir['haykirId']?.toString() ?? haykir['id']?.toString() ?? '') == haykirId
    );
    
    // Güncellenmiş listeyi kaydet
    _katildigimHaykirBox!.put(userEmail, haykirList);
    
    print('✅ Katıldığım haykır silindi: $haykirId');
  }

  static Future<void> upsertDavaParticipant(String davaId, Map<String, dynamic> participant) async {
    await _ensureDavaParticipantBoxOpen();

    final persisted = _davaParticipantBox?.get(davaId);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final email = participant['userEmail']?.toString();
    if (email == null || email.isEmpty) {
      return;
    }

    final existingIndex = list.indexWhere((p) => (p['userEmail']?.toString() ?? '').toLowerCase() == email.toLowerCase());
    final nowIso = DateTime.now().toIso8601String();

    if (existingIndex != -1) {
      final merged = Map<String, dynamic>.from(list[existingIndex]);
      participant.forEach((key, value) {
        if (value != null) {
          merged[key] = value;
        }
      });
      merged['statusUpdatedAt'] = participant['statusUpdatedAt'] ?? nowIso;
      merged['assignedAt'] = merged['assignedAt'] ?? nowIso;
      list[existingIndex] = merged;
    } else {
      final newParticipant = Map<String, dynamic>.from(participant);
      newParticipant['status'] = newParticipant['status'] ?? 'pending';
      newParticipant['statusUpdatedAt'] = newParticipant['statusUpdatedAt'] ?? nowIso;
      newParticipant['assignedAt'] = newParticipant['assignedAt'] ?? nowIso;
      list.add(newParticipant);
    }

    _davaParticipantBox?.put(davaId, list);
  }

  static Future<void> markDavaParticipantStatus({
    required String davaId,
    required String userEmail,
    required String status,
    String? reason,
    DateTime? statusAt,
    Map<String, dynamic>? extra,
  }) async {
    await _ensureDavaParticipantBoxOpen();

    final persisted = _davaParticipantBox?.get(davaId);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final idx = list.indexWhere((p) => (p['userEmail']?.toString() ?? '').toLowerCase() == userEmail.toLowerCase());
    if (idx == -1) {
      await upsertDavaParticipant(davaId, {
        'userEmail': userEmail,
        'displayName': (getRegistrationByEmail(userEmail)?.judgeName ?? userEmail.split('@').first),
        'status': status,
        'statusUpdatedAt': (statusAt ?? DateTime.now()).toIso8601String(),
        'reason': reason,
        if (extra != null) ...extra,
      });
      return;
    }

    list[idx]['status'] = status;
    list[idx]['statusUpdatedAt'] = (statusAt ?? DateTime.now()).toIso8601String();
    if (reason != null) {
      list[idx]['reason'] = reason;
    }
    if (extra != null) {
      extra.forEach((key, value) {
        if (value != null) {
          list[idx][key] = value;
        }
      });
    }

    _davaParticipantBox?.put(davaId, list);
  }

  static Future<List<Map<String, dynamic>>> getDavaParticipants(String davaId, {bool normalizeExpired = true}) async {
    await _ensureDavaParticipantBoxOpen();

    final persisted = _davaParticipantBox?.get(davaId);
    final List<Map<String, dynamic>> list = persisted != null
        ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    if (!normalizeExpired || list.isEmpty) {
      return list;
    }

    final now = DateTime.now();
    final threshold = now.subtract(const Duration(days: 3));
    bool modified = false;

    for (final participant in list) {
      final status = participant['status']?.toString() ?? 'pending';
      if (status == 'pending') {
        DateTime? assignedAt;
        final assignedAtStr = participant['assignedAt']?.toString();
        if (assignedAtStr != null && assignedAtStr.isNotEmpty) {
          assignedAt = DateTime.tryParse(assignedAtStr);
        }
        assignedAt ??= DateTime.tryParse(participant['statusUpdatedAt']?.toString() ?? '');
        assignedAt ??= now;

        if (assignedAt.isBefore(threshold)) {
          participant['status'] = 'auto_rejected';
          participant['reason'] = 'timeout';
          participant['statusUpdatedAt'] = now.toIso8601String();
          modified = true;
        }
      }
    }

    if (modified) {
      _davaParticipantBox?.put(davaId, list);
    }

    return list;
  }

  static Future<List<Map<String, dynamic>>> getDavaRejecters(String davaId) async {
    return _getDavaRejectersInternal(davaId);
  }

  static Future<List<Map<String, dynamic>>> getDavaAcceptors(String davaId) async {
    final participants = await getDavaParticipants(davaId);
    return participants.where((p) => (p['status']?.toString() ?? '') == 'accepted').toList();
  }

  static Future<List<String>> getDavaRecipients(String davaId) async {
    return _getDavaRecipientsInternalAlias(davaId);
  }

  static Future<Map<String, Map<String, dynamic>>> getDavaParticipantMap(String davaId) async {
    final participants = await getDavaParticipants(davaId);
    return {
      for (final p in participants)
        if (p['userEmail'] != null) p['userEmail'].toString(): p,
    };
  }

  static Future<void> _ensureDavaParticipantBoxOpen() async {
    if (_davaParticipantBox == null || !_davaParticipantBox!.isOpen) {
      _davaParticipantBox = await Hive.openBox(_davaParticipantBoxName);
    }
  }

  static Future<List<String>> _computeDavaRecipients(String davaId) async {
    final participants = await getDavaParticipants(davaId);
    final emails = participants.map((p) => p['userEmail']?.toString()).whereType<String>();
    if (emails.isEmpty) {
      return List<String>.from(_grup19Members);
    }
    final unique = emails.toSet().toList()..sort();
    return unique;
  }

  static Future<List<String>> _getDavaRecipientsInternalAlias(String davaId) async {
    return _computeDavaRecipients(davaId);
  }

  /// Kullanıcının admin durumunu güncelle
  static Future<void> setUserAdminStatus(String email, bool isAdmin) async {
    final user = getRegistrationByEmail(email);
    if (user == null) return;
    if (user.isAdmin == isAdmin) return;
    final updated = user.copyWith(isAdmin: isAdmin);
    await updateRegistration(updated);
  }

  // ========== CEZA BEĞENİLERİ İŞLEMLERİ ==========
  
  /// Ceza beğeni box'ını aç
  static Future<void> _ensureCezaBegeniBoxOpen() async {
    if (_cezaBegeniBox == null || !_cezaBegeniBox!.isOpen) {
      _cezaBegeniBox = await Hive.openBox(_cezaBegeniBoxName);
    }
  }

  /// Ceza beğenisi ekle/kaldır
  static Future<void> toggleCezaBegeni(String cezaName, String userEmail) async {
    try {
      await _ensureCezaBegeniBoxOpen();
      
      final Map<String, dynamic>? existing = _cezaBegeniBox!.get(cezaName) as Map<String, dynamic>?;
      final List<String> likedBy = existing != null 
          ? List<String>.from(existing['likedBy'] ?? <String>[])
          : <String>[];
      
      final int likeCount = existing != null ? (existing['likeCount'] as int? ?? 0) : 0;
      
      if (likedBy.contains(userEmail)) {
        // Beğeniyi kaldır
        likedBy.remove(userEmail);
        final newLikeCount = (likeCount - 1).clamp(0, 999999);
        await _cezaBegeniBox!.put(cezaName, {
          'likeCount': newLikeCount,
          'likedBy': likedBy,
        });
      } else {
        // Beğeni ekle
        likedBy.add(userEmail);
        await _cezaBegeniBox!.put(cezaName, {
          'likeCount': likeCount + 1,
          'likedBy': likedBy,
        });
      }
    } catch (e) {
      print('❌ Ceza beğenisi güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Ceza beğeni sayısını getir
  static Future<int> getCezaBegeniCount(String cezaName) async {
    try {
      await _ensureCezaBegeniBoxOpen();
      final Map<String, dynamic>? data = _cezaBegeniBox!.get(cezaName) as Map<String, dynamic>?;
      return data != null ? (data['likeCount'] as int? ?? 0) : 0;
    } catch (e) {
      print('❌ Ceza beğeni sayısı getirilirken hata: $e');
      return 0;
    }
  }

  /// Kullanıcının cezayı beğenip beğenmediğini kontrol et
  static Future<bool> isCezaLikedByUser(String cezaName, String userEmail) async {
    try {
      await _ensureCezaBegeniBoxOpen();
      final Map<String, dynamic>? data = _cezaBegeniBox!.get(cezaName) as Map<String, dynamic>?;
      if (data == null) return false;
      final List<String> likedBy = List<String>.from(data['likedBy'] ?? <String>[]);
      return likedBy.contains(userEmail);
    } catch (e) {
      print('❌ Ceza beğeni kontrolü yapılırken hata: $e');
      return false;
    }
  }

  /// Tüm ceza beğenilerini getir
  static Future<Map<String, int>> getAllCezaBegenileri() async {
    try {
      await _ensureCezaBegeniBoxOpen();
      final Map<String, int> result = <String, int>{};
      for (final key in _cezaBegeniBox!.keys) {
        final Map<String, dynamic>? data = _cezaBegeniBox!.get(key) as Map<String, dynamic>?;
        if (data != null) {
          result[key.toString()] = data['likeCount'] as int? ?? 0;
        }
      }
      return result;
    } catch (e) {
      print('❌ Tüm ceza beğenileri getirilirken hata: $e');
      return <String, int>{};
    }
  }

  // ========== CEZA İŞLEMLERİ ==========
  
  /// Ceza box'ını aç
  static Future<void> _ensureCezaBoxOpen() async {
    if (_cezaBox == null || !_cezaBox!.isOpen) {
      _cezaBox = await Hive.openBox(_cezaBoxName);
    }
  }

  /// Cezayı kaydet
  /// key: davaId_userEmail, value: String (ceza metni)
  static Future<void> saveCeza({
    required String davaId,
    required String userEmail,
    required String cezaText,
  }) async {
    try {
      await _ensureCezaBoxOpen();
      
      final key = '${davaId}_$userEmail';
      
      await _cezaBox!.put(key, cezaText);
      
      print('✅ Ceza kaydedildi: $key');
    } catch (e) {
      print('❌ Ceza kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Bir dava için ceza kutusunda kayıtlı tüm cezalar.
  /// Anahtarlar e-posta adresinin küçük harf biçimidir (`davaId_userEmail`).
  static Future<Map<String, String>> getCezaMapForDavaId(String davaId) async {
    final Map<String, String> out = <String, String>{};
    if (davaId.trim().isEmpty) {
      return out;
    }
    try {
      await _ensureCezaBoxOpen();
      final box = _cezaBox;
      if (box == null) {
        return out;
      }
      final String prefix = '${davaId}_';
      for (final Object? key in box.keys) {
        final String ks = key.toString();
        if (!ks.startsWith(prefix)) {
          continue;
        }
        final String email = ks.substring(prefix.length).trim();
        if (email.isEmpty) {
          continue;
        }
        final Object? raw = box.get(key);
        if (raw == null) {
          continue;
        }
        final String text = raw.toString().trim();
        if (text.isEmpty) {
          continue;
        }
        out[email.toLowerCase()] = text;
      }
    } catch (e) {
      print('❌ Ceza haritası okunurken hata: $e');
    }
    return out;
  }

  /// Cezayı getir
  /// key: davaId_userEmail, value: String (ceza metni)
  static Future<String?> getCeza({
    required String davaId,
    required String userEmail,
  }) async {
    try {
      await _ensureCezaBoxOpen();
      
      final key = '${davaId}_$userEmail';
      final persisted = _cezaBox!.get(key);
      
      if (persisted == null) {
        return null;
      }
      
      final String cezaText = persisted.toString();
      
      print('✅ Ceza getirildi: $key');
      return cezaText;
    } catch (e) {
      print('❌ Ceza getirilirken hata: $e');
      return null;
    }
  }

  // ========== CEZA OYLARI (HALK) ==========

  static Future<void> _ensureCezaOyBoxOpen() async {
    if (_cezaOyBox == null || !_cezaOyBox!.isOpen) {
      _cezaOyBox = await Hive.openBox(_cezaOyBoxName);
    }
  }

  /// Dava için tüm ceza oylarını döndürür (anahtar: seçen email, değer: rol value).
  static Future<Map<String, String>> getCezaOyMapForDavaId(String davaId) async {
    final Map<String, String> out = <String, String>{};
    if (davaId.trim().isEmpty) {
      return out;
    }
    try {
      await _ensureCezaOyBoxOpen();
      final Object? raw = _cezaOyBox!.get(davaId);
      if (raw is Map) {
        final Object? votes = raw['votesByEmail'];
        if (votes is Map) {
          for (final MapEntry<dynamic, dynamic> e in votes.entries) {
            final String email = e.key.toString().trim().toLowerCase();
            final String role = e.value.toString().trim();
            if (email.isNotEmpty && role.isNotEmpty) {
              out[email] = role;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Ceza oy haritası okunurken hata: $e');
    }
    return out;
  }

  /// Kullanıcının ceza oyunu kaydeder; aynı role tıklanırsa oy kaldırılır.
  static Future<String?> toggleCezaOy({
    required String davaId,
    required String voterEmail,
    required String roleValue,
  }) async {
    try {
      await _ensureCezaOyBoxOpen();
      final String email = voterEmail.trim().toLowerCase();
      final String role = roleValue.trim();
      if (davaId.trim().isEmpty || email.isEmpty || role.isEmpty) {
        return null;
      }
      final Map<String, String> votes =
          await getCezaOyMapForDavaId(davaId);
      if (votes[email] == role) {
        votes.remove(email);
      } else {
        votes[email] = role;
      }
      await _cezaOyBox!.put(davaId, <String, dynamic>{
        'votesByEmail': Map<String, String>.from(votes),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return votes[email];
    } catch (e) {
      print('❌ Ceza oyu kaydedilirken hata: $e');
      rethrow;
    }
  }

  // ========== HEDİYE OYLARI (HALK) ==========

  static Future<void> _ensureHediyeOyBoxOpen() async {
    if (_hediyeOyBox == null || !_hediyeOyBox!.isOpen) {
      _hediyeOyBox = await Hive.openBox(_hediyeOyBoxName);
    }
  }

  static Future<Map<String, String>> getHediyeOyMapForDavaId(String davaId) async {
    final Map<String, String> out = <String, String>{};
    if (davaId.trim().isEmpty) {
      return out;
    }
    try {
      await _ensureHediyeOyBoxOpen();
      final Object? raw = _hediyeOyBox!.get(davaId);
      if (raw is Map) {
        final Object? votes = raw['votesByEmail'];
        if (votes is Map) {
          for (final MapEntry<dynamic, dynamic> e in votes.entries) {
            final String email = e.key.toString().trim().toLowerCase();
            final String role = e.value.toString().trim();
            if (email.isNotEmpty && role.isNotEmpty) {
              out[email] = role;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Hediye oy haritası okunurken hata: $e');
    }
    return out;
  }

  static Future<String?> toggleHediyeOy({
    required String davaId,
    required String voterEmail,
    required String roleValue,
  }) async {
    try {
      await _ensureHediyeOyBoxOpen();
      final String email = voterEmail.trim().toLowerCase();
      final String role = roleValue.trim();
      if (davaId.trim().isEmpty || email.isEmpty || role.isEmpty) {
        return null;
      }
      final Map<String, String> votes =
          await getHediyeOyMapForDavaId(davaId);
      if (votes[email] == role) {
        votes.remove(email);
      } else {
        votes[email] = role;
      }
      await _hediyeOyBox!.put(davaId, <String, dynamic>{
        'votesByEmail': Map<String, String>.from(votes),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return votes[email];
    } catch (e) {
      print('❌ Hediye oyu kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Dava kabul tarihi (opened / accepted kayıtlarından).
  static Future<DateTime?> getDavaAcceptedAt(String davaId) async {
    DateTime? acceptedAt;
    final opened = getOpenedDavaById(davaId);
    final openedAcceptedAt = opened?['acceptedAt']?.toString();
    if (openedAcceptedAt != null && openedAcceptedAt.isNotEmpty) {
      acceptedAt = DateTime.tryParse(openedAcceptedAt);
    }
    if (acceptedAt == null) {
      final accepted = await getAcceptedDavaById(davaId);
      final acceptedAcceptedAt = accepted?['acceptedAt']?.toString();
      if (acceptedAcceptedAt != null && acceptedAcceptedAt.isNotEmpty) {
        acceptedAt = DateTime.tryParse(acceptedAcceptedAt);
      }
    }
    return acceptedAt;
  }

  /// Belirli bir dava için cezayı sil
  static Future<void> deleteCeza({
    required String davaId,
    required String userEmail,
  }) async {
    try {
      await _ensureCezaBoxOpen();
      
      final key = '${davaId}_$userEmail';
      await _cezaBox!.delete(key);
      
      print('✅ Ceza silindi: $key');
    } catch (e) {
      print('❌ Ceza silinirken hata: $e');
      rethrow;
    }
  }

  // ========== MASRAF İŞLEMLERİ ==========
  
  /// Masraf box'ını aç
  static Future<void> _ensureMasrafBoxOpen() async {
    if (_masrafBox == null || !_masrafBox!.isOpen) {
      _masrafBox = await Hive.openBox(_masrafBoxName);
    }
  }

  /// Masrafları kaydet
  /// key: davaId_userEmail, value: List<String> (masraf isimleri)
  static Future<void> saveMasrafExpenses({
    required String davaId,
    required String userEmail,
    required List<String> expenses,
  }) async {
    try {
      await _ensureMasrafBoxOpen();
      
      final key = '${davaId}_$userEmail';
      final List<String> expensesList = List<String>.from(expenses);
      
      await _masrafBox!.put(key, expensesList);
      
      print('✅ Masraflar kaydedildi: $key (${expensesList.length} adet)');
    } catch (e) {
      print('❌ Masraflar kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// [HukumGiftSelectionPage] satır biçimi: emoji, isim, `· ⭐`, kategori `›` alt başlık.
  static String? _pickGiftMasrafLine(List<dynamic> raw) {
    final List<String> lines = raw
        .map((e) => e.toString().trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return null;
    }
    for (final String s in lines) {
      if (s.contains('⭐') && s.contains('›')) {
        return s;
      }
    }
    return lines.first;
  }

  /// Bir dava için masraf kutusundan kullanıcı başına tek hediye satırı (ilk uygun satır).
  /// Anahtarlar e-postanın küçük harf biçimidir (`davaId_userEmail`).
  static Future<Map<String, String>> getMasrafGiftLineMapForDavaId(String davaId) async {
    final Map<String, String> out = <String, String>{};
    if (davaId.trim().isEmpty) {
      return out;
    }
    try {
      await _ensureMasrafBoxOpen();
      final box = _masrafBox;
      if (box == null) {
        return out;
      }
      final String prefix = '${davaId}_';
      for (final Object? key in box.keys) {
        final String ks = key.toString();
        if (!ks.startsWith(prefix)) {
          continue;
        }
        final String email = ks.substring(prefix.length).trim();
        if (email.isEmpty) {
          continue;
        }
        final Object? raw = box.get(key);
        if (raw == null) {
          continue;
        }
        if (raw is! List) {
          continue;
        }
        final String? line = _pickGiftMasrafLine(raw);
        if (line == null || line.isEmpty) {
          continue;
        }
        out[email.toLowerCase()] = line;
      }
    } catch (e) {
      print('❌ Hediye (masraf) haritası okunurken hata: $e');
    }
    return out;
  }

  /// Masrafları getir
  /// key: davaId_userEmail, value: List<String> (masraf isimleri)
  static Future<List<String>?> getMasrafExpenses({
    required String davaId,
    required String userEmail,
  }) async {
    try {
      await _ensureMasrafBoxOpen();
      
      final key = '${davaId}_$userEmail';
      final persisted = _masrafBox!.get(key);
      
      if (persisted == null) {
        return null;
      }
      
      final List<String> expensesList = List<String>.from(persisted as List);
      
      print('✅ Masraflar getirildi: $key (${expensesList.length} adet)');
      return expensesList;
    } catch (e) {
      print('❌ Masraflar getirilirken hata: $e');
      return null;
    }
  }

  /// Belirli bir dava için masrafları sil
  static Future<void> deleteMasrafExpenses({
    required String davaId,
    required String userEmail,
  }) async {
    try {
      await _ensureMasrafBoxOpen();
      
      final key = '${davaId}_$userEmail';
      await _masrafBox!.delete(key);
      
      print('✅ Masraflar silindi: $key');
    } catch (e) {
      print('❌ Masraflar silinirken hata: $e');
      rethrow;
    }
  }

  // ========== REKLAM İŞLEMLERİ ==========
  
  /// Reklam box'ını aç
  static Future<void> _ensureReklamBoxOpen() async {
    if (_reklamBox == null || !_reklamBox!.isOpen) {
      _reklamBox = await Hive.openBox(_reklamBoxName);
    }
  }

  /// Tutulan reklamlar box'ını aç
  static Future<void> _ensureTutulanReklamlarBoxOpen() async {
    if (_tutulanReklamlarBox == null || !_tutulanReklamlarBox!.isOpen) {
      _tutulanReklamlarBox = await Hive.openBox(_tutulanReklamlarBoxName);
    }
  }

  /// Reklam kaydet
  static Future<void> saveReklam(Map<String, dynamic> reklamData) async {
    try {
      await _ensureReklamBoxOpen();
      
      final String reklamId = reklamData['id'] as String;
      await _reklamBox!.put(reklamId, reklamData);
      
      print('✅ Reklam kaydedildi: $reklamId');
    } catch (e) {
      print('❌ Reklam kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Reklam getir
  static Future<Map<String, dynamic>?> getReklam(String reklamId) async {
    try {
      await _ensureReklamBoxOpen();
      
      final persisted = _reklamBox!.get(reklamId);
      if (persisted == null) return null;
      
      return Map<String, dynamic>.from(persisted as Map);
    } catch (e) {
      print('❌ Reklam getirilirken hata: $e');
      return null;
    }
  }

  /// Reklam sil
  static Future<void> deleteReklam(String reklamId) async {
    try {
      await _ensureReklamBoxOpen();
      
      await _reklamBox!.delete(reklamId);
      
      print('✅ Reklam silindi: $reklamId');
    } catch (e) {
      print('❌ Reklam silinirken hata: $e');
      rethrow;
    }
  }

  /// Tüm aktif reklamları getir
  static Future<List<Map<String, dynamic>>> getAllActiveReklamlar() async {
    try {
      await _ensureReklamBoxOpen();
      
      final List<Map<String, dynamic>> reklamlar = [];
      final now = DateTime.now();
      
      for (final key in _reklamBox!.keys) {
        final persisted = _reklamBox!.get(key);
        if (persisted == null) continue;
        
        final reklam = Map<String, dynamic>.from(persisted as Map);
        
        // Durum kontrolü
        if (reklam['durum'] != 'aktif') continue;
        
        // Tarih kontrolü
        if (reklam['baslangicTarihi'] != null) {
          final baslangic = DateTime.parse(reklam['baslangicTarihi'] as String);
          if (now.isBefore(baslangic)) continue;
        }
        
        if (reklam['bitisTarihi'] != null) {
          final bitis = DateTime.parse(reklam['bitisTarihi'] as String);
          if (now.isAfter(bitis)) continue;
        }
        
        reklamlar.add(reklam);
      }
      
      // Priority'ye göre sırala (yüksek priority önce)
      reklamlar.sort((a, b) {
        final priorityA = (a['priority'] as int?) ?? 1;
        final priorityB = (b['priority'] as int?) ?? 1;
        return priorityB.compareTo(priorityA);
      });
      
      return reklamlar;
    } catch (e) {
      print('❌ Aktif reklamlar getirilirken hata: $e');
      return [];
    }
  }

  /// Tüm reklamları getir (aktif, pasif, taslak - filtreleme yok)
  static Future<List<Map<String, dynamic>>> getAllReklamlar() async {
    try {
      await _ensureReklamBoxOpen();
      
      final List<Map<String, dynamic>> reklamlar = [];
      
      for (final key in _reklamBox!.keys) {
        final persisted = _reklamBox!.get(key);
        if (persisted == null) continue;
        
        final reklam = Map<String, dynamic>.from(persisted as Map);
        reklamlar.add(reklam);
      }
      
      // Oluşturulma tarihine göre sırala (en yeni üstte)
      reklamlar.sort((a, b) {
        final aDate = a['olusturulmaTarihi'] as String? ?? '';
        final bDate = b['olusturulmaTarihi'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
      
      return reklamlar;
    } catch (e) {
      print('❌ Tüm reklamlar getirilirken hata: $e');
      return [];
    }
  }

  /// Kategoriye göre aktif reklamları getir
  static Future<List<Map<String, dynamic>>> getReklamlarByKategori(String kategori) async {
    try {
      final allActive = await getAllActiveReklamlar();
      return allActive.where((reklam) {
        final reklamKategori = reklam['reklamKategorisi'] as String?;
        return reklamKategori == kategori || reklamKategori == 'TUTULANLAR';
      }).toList();
    } catch (e) {
      print('❌ Kategori reklamları getirilirken hata: $e');
      return [];
    }
  }

  /// Kullanıcının tutulan reklamlarını getir
  static Future<List<String>> getTutulanReklamlar(String userEmail) async {
    try {
      await _ensureTutulanReklamlarBoxOpen();
      
      final persisted = _tutulanReklamlarBox!.get(userEmail);
      if (persisted == null) return [];
      
      final List<String> reklamIds = List<String>.from(persisted as List);
      
      // Süresi dolmuş reklamları temizle
      final now = DateTime.now();
      final validIds = <String>[];
      
      for (final reklamId in reklamIds) {
        final reklam = await getReklam(reklamId);
        if (reklam == null) continue;
        
        // Süre kontrolü
        if (reklam['bitisTarihi'] != null) {
          final bitis = DateTime.parse(reklam['bitisTarihi'] as String);
          if (now.isAfter(bitis)) continue; // Süresi dolmuş, ekleme
        }
        
        validIds.add(reklamId);
      }
      
      // Güncellenmiş listeyi kaydet
      if (validIds.length != reklamIds.length) {
        await _tutulanReklamlarBox!.put(userEmail, validIds);
      }
      
      return validIds;
    } catch (e) {
      print('❌ Tutulan reklamlar getirilirken hata: $e');
      return [];
    }
  }

  /// Kullanıcının tutulan reklamlarına ekle
  static Future<void> addTutulanReklam(String userEmail, String reklamId) async {
    try {
      await _ensureTutulanReklamlarBoxOpen();
      
      final current = await getTutulanReklamlar(userEmail);
      if (!current.contains(reklamId)) {
        current.add(reklamId);
        await _tutulanReklamlarBox!.put(userEmail, current);
        print('✅ Tutulan reklam eklendi: $reklamId');
      }
    } catch (e) {
      print('❌ Tutulan reklam eklenirken hata: $e');
      rethrow;
    }
  }

  /// Reklam gösterim sayısını artır
  static Future<void> incrementReklamGosterim(String reklamId) async {
    try {
      final reklam = await getReklam(reklamId);
      if (reklam == null) return;
      
      final currentGosterim = (reklam['gosterimSayisi'] as int?) ?? 0;
      reklam['gosterimSayisi'] = currentGosterim + 1;
      reklam['guncellenmeTarihi'] = DateTime.now().toIso8601String();
      
      await saveReklam(reklam);
    } catch (e) {
      print('❌ Reklam gösterim sayısı artırılırken hata: $e');
    }
  }

  /// Reklam tıklama sayısını artır
  static Future<void> incrementReklamTiklama(String reklamId) async {
    try {
      final reklam = await getReklam(reklamId);
      if (reklam == null) return;
      
      final currentTiklama = (reklam['tiklanmaSayisi'] as int?) ?? 0;
      reklam['tiklanmaSayisi'] = currentTiklama + 1;
      reklam['guncellenmeTarihi'] = DateTime.now().toIso8601String();
      
      await saveReklam(reklam);
    } catch (e) {
      print('❌ Reklam tıklama sayısı artırılırken hata: $e');
    }
  }

  /// Varsayılan reklamları oluştur (her kategori için 1 adet)
  static Future<void> initializeDefaultReklamlar() async {
    try {
      await _ensureReklamBoxOpen();
      
      // Eğer zaten reklamlar varsa, oluşturma
      if (_reklamBox!.isNotEmpty) {
        return;
      }
      
      final kategoriler = [
        {'id': 1, 'name': 'OTOMOTİV', 'icon': '🚗'},
        {'id': 2, 'name': 'İŞ DÜNYASI & ENDÜSTRİ', 'icon': '💼'},
        {'id': 3, 'name': 'EĞLENCE & KÜLTÜR', 'icon': '🎭'},
        {'id': 4, 'name': 'AİLE & EBEVEYNLİK', 'icon': '👨‍👩‍👧'},
        {'id': 5, 'name': 'YEMEK & İÇECEK', 'icon': '🍔'},
        {'id': 6, 'name': 'SAĞLIK & ZİNDELİK', 'icon': '🏥'},
        {'id': 7, 'name': 'EV & BAHÇE', 'icon': '🏠'},
        {'id': 8, 'name': 'MEDYA & YAYINCILIK', 'icon': '📰'},
        {'id': 9, 'name': 'MODA & AKSESUAR', 'icon': '👕'},
        {'id': 10, 'name': 'SEYAHAT & TURİZM', 'icon': '✈️'},
        {'id': 11, 'name': 'SPOR', 'icon': '⚽'},
        {'id': 12, 'name': 'TEKNOLOJİ & ELEKTRONİK', 'icon': '💻'},
        {'id': 13, 'name': 'TELEKOMÜNİKASYON', 'icon': '📱'},
        {'id': 14, 'name': 'EĞİTİM', 'icon': '🎓'},
        {'id': 15, 'name': 'FİNANS & BANKACILIK', 'icon': '💰'},
        {'id': 16, 'name': 'EMLAK & GAYRİMENKUL', 'icon': '🏢'},
        {'id': 17, 'name': 'ALIŞVERİŞ', 'icon': '🛒'},
        {'id': 18, 'name': 'TOPLUM & KAMU', 'icon': '👥'},
        {'id': 19, 'name': 'KİŞİSEL HİZMETLER & İŞLETMELER', 'icon': '👔'},
        {'id': 20, 'name': 'HOBİLER & İLGİ ALANLARI', 'icon': '🎨'},
        {'id': 21, 'name': 'İŞ KARİYER & KURUMSAL YAŞAM', 'icon': '💼'},
        {'id': 22, 'name': 'DİĞER', 'icon': '📌'},
      ];
      
      final now = DateTime.now();
      final bitisTarihi = now.add(const Duration(days: 365)); // 1 yıl geçerli
      
      for (final kategori in kategoriler) {
        final reklamId = 'reklam_${kategori['id']}_default';
        final reklamData = {
          'id': reklamId,
          'reklamAdi': 'WhoBoom Premium Abonelik',
          'reklamBasligi': '${kategori['icon']} ${kategori['name']} Kategorisi İçin Özel Hediye!',
          'reklamAciklamasi': 'WhoBoom Premium abonelik hediye et! ${kategori['name']} kategorisindeki özel avantajlardan yararlan.',
          'reklamResmi': 'https://via.placeholder.com/400x300?text=WhoBoom+Premium',
          'reklamKodu': 'WB-PREM-${kategori['id']}',
          'reklamKategorisi': kategori['name'] as String,
          'durum': 'aktif',
          'baslangicTarihi': now.toIso8601String(),
          'bitisTarihi': bitisTarihi.toIso8601String(),
          'hedefUrl': 'https://whoboom.com/premium',
          'tiklanmaSayisi': 0,
          'gosterimSayisi': 0,
          'maksimumButce': null,
          'harcananButce': 0.0,
          'olusturulmaTarihi': now.toIso8601String(),
          'guncellenmeTarihi': now.toIso8601String(),
          'olusturanKullaniciId': 'system',
          'hedefKitlesi': null,
          'priority': 1,
        };
        
        await saveReklam(reklamData);
      }
      
      print('✅ Varsayılan reklamlar oluşturuldu (${kategoriler.length} adet)');
    } catch (e) {
      print('❌ Varsayılan reklamlar oluşturulurken hata: $e');
    }
  }

  // ========== HEDİYE/UYARI SİSTEMİ ==========
  /// Hediye durumunu kaydet veya güncelle
  /// key: davaId_userEmail, value: Map<String, dynamic>
  static Future<void> saveHediyeDurumu({
    required String davaId,
    required String userEmail,
    required bool evetTiklandi,
    DateTime? sonUyariTarihi,
  }) async {
    try {
      final key = '${davaId}_$userEmail';
      final existing = _hediyeUyariBox?.get(key);
      final List<String> uyariGecmisi = existing != null
          ? List<String>.from(existing['uyariGecmisi'] ?? [])
          : [];
      
      if (sonUyariTarihi != null) {
        uyariGecmisi.add(sonUyariTarihi.toIso8601String());
      }
      
      final data = {
        'davaId': davaId,
        'userEmail': userEmail,
        'evetTiklandi': evetTiklandi,
        'sonUyariTarihi': sonUyariTarihi?.toIso8601String(),
        'uyariGecmisi': uyariGecmisi,
        'guncellenmeTarihi': DateTime.now().toIso8601String(),
      };
      
      await _hediyeUyariBox?.put(key, data);
      print('✅ Hediye durumu kaydedildi: $key');
    } catch (e) {
      print('❌ Hediye durumu kaydedilirken hata: $e');
    }
  }

  /// Hediye durumunu al
  static Map<String, dynamic>? getHediyeDurumu(String davaId, String userEmail) {
    try {
      final key = '${davaId}_$userEmail';
      final data = _hediyeUyariBox?.get(key);
      if (data != null) {
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    } catch (e) {
      print('❌ Hediye durumu alınırken hata: $e');
      return null;
    }
  }

  /// Uyarı gönder (19 günlük cooldown kontrolü ile)
  static Future<bool> sendUyari({
    required String davaId,
    required String userEmail,
    required String davaci,
    required String davali,
    required String davaAdi,
    required String davaTarihi,
    required String hediyeAlinacakKisiRol,
    required String hediyeAlinacakKisiAdi,
  }) async {
    try {
      final key = '${davaId}_$userEmail';
      final existing = _hediyeUyariBox?.get(key);
      
      // EVET tıklanmışsa uyarı gönderilemez
      if (existing != null) {
        final evetTiklandi = existing['evetTiklandi'] as bool? ?? false;
        if (evetTiklandi) {
          print('⚠️ EVET tıklanmış, uyarı gönderilemez');
          return false;
        }
        
        // 19 günlük cooldown kontrolü
        final sonUyariTarihiStr = existing['sonUyariTarihi'] as String?;
        if (sonUyariTarihiStr != null) {
          final sonUyariTarihi = DateTime.tryParse(sonUyariTarihiStr);
          if (sonUyariTarihi != null) {
            final now = DateTime.now();
            final fark = now.difference(sonUyariTarihi);
            if (fark.inDays < 19) {
              final kalanGun = 19 - fark.inDays;
              print('⚠️ 19 günlük cooldown aktif, kalan gün: $kalanGun');
              return false;
            }
          }
        }
      }
      
      // Uyarı mesajını oluştur
      final uyariMesaji = '"$davaci" ın "$davaTarihi" Tarihli "$davali" Ya Karşı açtığı\n'
          'Davanın hediyelerinden birini "$hediyeAlinacakKisiRol" "$hediyeAlinacakKisiAdi"ya henüz almadığı\n'
          'bildirilmiştir. Bir hediye alması için destekleriniz beklenmektedir.';
      
      // Uyarıyı sadece davacı ve davalıya bildirim olarak ekle
      final uyariData = {
        'id': 'uyari_${davaId}_${DateTime.now().millisecondsSinceEpoch}',
        'davaId': davaId,
        'davaAdi': davaAdi,
        'davaci': davaci,
        'davali': davali,
        'davaTarihi': davaTarihi,
        'hediyeAlinacakKisiRol': hediyeAlinacakKisiRol,
        'hediyeAlinacakKisiAdi': hediyeAlinacakKisiAdi,
        'uyariMesaji': uyariMesaji,
        'olusturmaTarihi': DateTime.now().toIso8601String(),
        'gondericiEmail': userEmail,
      };
      
      // Davacı ve davalı email'lerini bul (judgeName'e göre)
      String? davaciEmail;
      String? davaliEmail;
      
      final allUsers = _registrationBox?.values.toList() ?? [];
      for (final user in allUsers) {
        if (user.judgeName == davaci) {
          davaciEmail = user.email;
        }
        if (user.judgeName == davali) {
          davaliEmail = user.email;
        }
        // Her ikisi de bulunduysa döngüden çık
        if (davaciEmail != null && davaliEmail != null) {
          break;
        }
      }
      
      // Email bulunamazsa, isim olarak kullan (fallback)
      davaciEmail ??= davaci;
      davaliEmail ??= davali;
      
      // Sadece davacı ve davalıya bildirim gönder
      final bildirimAlacaklar = <String>{davaciEmail, davaliEmail};
      for (final recipientEmail in bildirimAlacaklar) {
        if (recipientEmail.isEmpty) continue;
        
        final bildirimKey = 'bildirimler_$recipientEmail';
        final existingBildirimler = _hediyeUyariBox?.get(bildirimKey);
        final List<Map<String, dynamic>> bildirimler = existingBildirimler != null
            ? (existingBildirimler as List).map((item) {
                // Hive'dan gelen map'i Map<String, dynamic>'e dönüştür
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return item as Map<String, dynamic>;
              }).toList()
            : <Map<String, dynamic>>[];
        
        bildirimler.add(uyariData);
        await _hediyeUyariBox?.put(bildirimKey, bildirimler);
        print('✅ Bildirim gönderildi: $recipientEmail');
      }
      
      // Hediye durumunu güncelle (son uyarı tarihini kaydet)
      await saveHediyeDurumu(
        davaId: davaId,
        userEmail: userEmail,
        evetTiklandi: false,
        sonUyariTarihi: DateTime.now(),
      );
      
      print('✅ Uyarı gönderildi: $davaId');
      return true;
    } catch (e) {
      print('❌ Uyarı gönderilirken hata: $e');
      return false;
    }
  }

  /// Yeni gelen dava için [UyarilarPage] bildirimi (Hive).
  static Future<void> appendGelenDavaBildirimi(
    String userEmail,
    Map<String, dynamic> dava,
  ) async {
    try {
      if (_hediyeUyariBox == null || !_hediyeUyariBox!.isOpen) {
        _hediyeUyariBox = await Hive.openBox(_hediyeUyariBoxName);
      }
      final bildirimKey = 'bildirimler_$userEmail';
      final existingBildirimler = _hediyeUyariBox?.get(bildirimKey);
      final List<Map<String, dynamic>> bildirimler = existingBildirimler != null
          ? (existingBildirimler as List).map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return item as Map<String, dynamic>;
            }).toList()
          : <Map<String, dynamic>>[];

      final davaId = (dava['id'] ?? dava['davaId'])?.toString() ?? '';
      final adi = (dava['davaAdi'] ?? dava['adi'] ?? 'Dava').toString();
      bildirimler.add({
        'id': 'gelen_${davaId}_${userEmail}_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'gelen_dava',
        'davaId': davaId,
        'davaAdi': adi,
        'uyariMesaji': 'Dikkat! Gelen DAVA var.',
        'olusturmaTarihi': DateTime.now().toIso8601String(),
      });
      await _hediyeUyariBox?.put(bildirimKey, bildirimler);
    } catch (e) {
      print('❌ Gelen dava bildirimi eklenemedi: $e');
    }
  }

  /// Kullanıcının bildirimlerini al
  static List<Map<String, dynamic>> getBildirimler(String userEmail) {
    try {
      final bildirimKey = 'bildirimler_$userEmail';
      final bildirimler = _hediyeUyariBox?.get(bildirimKey);
      if (bildirimler != null) {
        return (bildirimler as List).map((item) {
          // Hive'dan gelen map'i Map<String, dynamic>'e dönüştür
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return item as Map<String, dynamic>;
        }).toList().reversed.toList(); // En yeni önce
      }
      return [];
    } catch (e) {
      print('❌ Bildirimler alınırken hata: $e');
      return [];
    }
  }

  /// Bildirimi sil
  static Future<void> deleteBildirim(String userEmail, String bildirimId) async {
    try {
      final bildirimKey = 'bildirimler_$userEmail';
      final bildirimler = _hediyeUyariBox?.get(bildirimKey);
      if (bildirimler != null) {
        final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(bildirimler as List);
        list.removeWhere((b) => b['id'] == bildirimId);
        await _hediyeUyariBox?.put(bildirimKey, list);
      }
    } catch (e) {
      print('❌ Bildirim silinirken hata: $e');
    }
  }

  // ========== DAVA AKSIYONLARI (BEĞENME, BEĞENMEME, YORUM, PAYLAŞ) ==========

  /// Dava için global istatistikleri getir
  static Map<String, dynamic> getDavaActionStats(String davaId) {
    try {
      final stats = _davaActionStatsBox?.get(davaId);
      if (stats == null) {
        return {
          'totalLikes': 0,
          'totalDislikes': 0,
          'totalComments': 0,
          'totalShares': 0,
          'likedBy': <String>[],
          'dislikedBy': <String>[],
        };
      }
      return Map<String, dynamic>.from(stats as Map);
    } catch (e) {
      print('❌ Dava istatistikleri alınırken hata: $e');
      return {
        'totalLikes': 0,
        'totalDislikes': 0,
        'totalComments': 0,
        'totalShares': 0,
        'likedBy': <String>[],
        'dislikedBy': <String>[],
      };
    }
  }

  /// Kullanıcının dava için aksiyonunu getir
  static Map<String, dynamic> getUserDavaAction(String davaId, String userEmail) {
    try {
      final key = '${davaId}_$userEmail';
      final action = _davaActionsBox?.get(key);
      if (action == null) {
        return {
          'like': false,
          'dislike': false,
          'commentCount': 0,
          'sharedAt': null,
        };
      }
      return Map<String, dynamic>.from(action as Map);
    } catch (e) {
      print('❌ Kullanıcı aksiyonu alınırken hata: $e');
      return {
        'like': false,
        'dislike': false,
        'commentCount': 0,
        'sharedAt': null,
      };
    }
  }

  /// Dava beğenme/beğenmeme toggle (birbirini dışlar)
  static Future<void> toggleDavaLike(String davaId, String userEmail, bool isLike) async {
    try {
      // Hüküm süresi sonrası destek/kına kilidi:
      // Dava tarihi geçmişse sayaçların değişmesini servis katmanında da engelle.
      if (await _isLikeDislikeLockedAfter76Days(davaId)) {
        print('⚠️ $_hukumFreezeDays gün doldu: destek/kına güncellenemez. davaId=$davaId');
        return;
      }

      final key = '${davaId}_$userEmail';
      final userAction = getUserDavaAction(davaId, userEmail);
      final stats = getDavaActionStats(davaId);
      
      final likedBy = List<String>.from(stats['likedBy'] ?? []);
      final dislikedBy = List<String>.from(stats['dislikedBy'] ?? []);
      int totalLikes = stats['totalLikes'] ?? 0;
      int totalDislikes = stats['totalDislikes'] ?? 0;
      
      final currentLike = userAction['like'] ?? false;
      final currentDislike = userAction['dislike'] ?? false;
      
      // Yeni aksiyon
      final newAction = Map<String, dynamic>.from(userAction);
      
      if (isLike) {
        // Beğenme işlemi
        if (currentLike) {
          // Beğenmeyi kaldır
          newAction['like'] = false;
          totalLikes = (totalLikes - 1).clamp(0, 999999);
          likedBy.remove(userEmail);
        } else {
          // Beğenme ekle
          if (currentDislike) {
            // Önce beğenmeme varsa kaldır
            newAction['dislike'] = false;
            totalDislikes = (totalDislikes - 1).clamp(0, 999999);
            dislikedBy.remove(userEmail);
          }
          newAction['like'] = true;
          totalLikes++;
          if (!likedBy.contains(userEmail)) {
            likedBy.add(userEmail);
          }
        }
      } else {
        // Beğenmeme işlemi
        if (currentDislike) {
          // Beğenmemeyi kaldır
          newAction['dislike'] = false;
          totalDislikes = (totalDislikes - 1).clamp(0, 999999);
          dislikedBy.remove(userEmail);
        } else {
          // Beğenmeme ekle
          if (currentLike) {
            // Önce beğenme varsa kaldır
            newAction['like'] = false;
            totalLikes = (totalLikes - 1).clamp(0, 999999);
            likedBy.remove(userEmail);
          }
          newAction['dislike'] = true;
          totalDislikes++;
          if (!dislikedBy.contains(userEmail)) {
            dislikedBy.add(userEmail);
          }
        }
      }
      
      // Kullanıcı aksiyonunu kaydet
      await _davaActionsBox?.put(key, newAction);
      
      // Global istatistikleri güncelle
      final updatedStats = {
        'totalLikes': totalLikes,
        'totalDislikes': totalDislikes,
        'totalComments': stats['totalComments'] ?? 0,
        'totalShares': stats['totalShares'] ?? 0,
        'likedBy': likedBy,
        'dislikedBy': dislikedBy,
      };
      await _davaActionStatsBox?.put(davaId, updatedStats);
      
      print('✅ Dava beğenme/beğenmeme güncellendi: $davaId, $userEmail, isLike: $isLike');
    } catch (e) {
      print('❌ Dava beğenme/beğenmeme güncellenirken hata: $e');
    }
  }

  static const int _hukumFreezeDays = 19;

  static Future<bool> _isLikeDislikeLockedAfter76Days(String davaId) async {
    DateTime? acceptedAt;

    final opened = getOpenedDavaById(davaId);
    final openedAcceptedAt = opened?['acceptedAt']?.toString();
    if (openedAcceptedAt != null && openedAcceptedAt.isNotEmpty) {
      acceptedAt = DateTime.tryParse(openedAcceptedAt);
    }

    if (acceptedAt == null) {
      final accepted = await getAcceptedDavaById(davaId);
      final acceptedAcceptedAt = accepted?['acceptedAt']?.toString();
      if (acceptedAcceptedAt != null && acceptedAcceptedAt.isNotEmpty) {
        acceptedAt = DateTime.tryParse(acceptedAcceptedAt);
      }
    }

    if (acceptedAt == null) return false;
    final passedDays = DateTime.now().difference(acceptedAt).inDays;
    return passedDays >= _hukumFreezeDays;
  }

  /// Dava için gizli tanık sayacını getir
  static int getGizliTanikCounter(String davaId) {
    try {
      final stats = getDavaActionStats(davaId);
      return stats['gizliTanikCounter'] ?? 0;
    } catch (e) {
      print('❌ Gizli tanık sayacı alınırken hata: $e');
      return 0;
    }
  }

  /// Dava için gizli tanık sayacını artır ve yeni ID döndür
  static int incrementGizliTanikCounter(String davaId) {
    try {
      final stats = getDavaActionStats(davaId);
      final currentCounter = stats['gizliTanikCounter'] ?? 0;
      final newCounter = currentCounter + 1;
      
      // İstatistikleri güncelle
      final updatedStats = Map<String, dynamic>.from(stats);
      updatedStats['gizliTanikCounter'] = newCounter;
      _davaActionStatsBox?.put(davaId, updatedStats);
      
      print('✅ Gizli tanık sayacı artırıldı: $davaId, yeni sayı: $newCounter');
      return newCounter;
    } catch (e) {
      print('❌ Gizli tanık sayacı artırılırken hata: $e');
      return 1; // Hata durumunda 1 döndür
    }
  }

  /// Gizli tanık yorumlarında görünen sabit takma ad.
  static const String gizliTanikDisplayName = 'GizliTanık-19';

  /// Gizli tanık ID oluştur (görünen ad her zaman [gizliTanikDisplayName]).
  static String generateGizliTanikId(String davaId) {
    incrementGizliTanikCounter(davaId);
    return gizliTanikDisplayName;
  }

  /// Dava yorum ekle (max 19 kontrolü)
  /// ✅ 19 saniye kuralı: Hiç kimse 19 saniye geçmeden yorum yapamaz
  static Future<bool> addDavaComment(
    String davaId,
    String userEmail, {
    String? yorumMetni,
    bool isGizliTanik = false,
    String? parentCommentId,
  }) async {
    try {
      // ✅ 19 saniye kuralı kontrolü
      final lastCommentTime = _userLastCommentBox?.get(userEmail);
      if (lastCommentTime != null) {
        try {
          final lastTime = DateTime.parse(lastCommentTime.toString());
          final now = DateTime.now();
          final difference = now.difference(lastTime);
          
          if (difference.inSeconds < 19) {
            print('⚠️ 19 saniye kuralı: Kullanıcı ${difference.inSeconds} saniye önce yorum yaptı. ${19 - difference.inSeconds} saniye beklemeli.');
            return false;
          }
        } catch (e) {
          print('⚠️ Son yorum zamanı parse edilemedi: $e');
        }
      }
      
      final key = '${davaId}_$userEmail';
      final userAction = getUserDavaAction(davaId, userEmail);
      final stats = getDavaActionStats(davaId);
      
      final commentCount = userAction['commentCount'] ?? 0;
      
      // Maksimum 19 yorum kontrolü
      if (commentCount >= 19) {
        print('⚠️ Maksimum yorum sayısına ulaşıldı: $davaId, $userEmail');
        return false;
      }
      
      // Kullanıcı aksiyonunu güncelle
      final newAction = Map<String, dynamic>.from(userAction);
      newAction['commentCount'] = commentCount + 1;
      
      // Yorum metni varsa kaydet
      if (yorumMetni != null && yorumMetni.isNotEmpty) {
        final yorumlar =
            List<Map<String, dynamic>>.from(newAction['yorumlar'] ?? []);

        final userName = isGizliTanik
            ? generateGizliTanikId(davaId)
            : (getRegistrationByEmail(userEmail)?.judgeName ??
                userEmail.split('@')[0]);

        final yeniYorum = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'userEmail': userEmail,
          'userName': userName,
          'yorum': yorumMetni,
          'tarih': DateTime.now().toIso8601String(),
          'begeniSayisi': 0,
          'isGizliTanik': isGizliTanik,
          'parentId': parentCommentId,
          'replies': <Map<String, dynamic>>[],
        };

        newAction['yorumlar'] =
            CommentUtils.addComment(yorumlar, yeniYorum);
      }
      
      await _davaActionsBox?.put(key, newAction);
      
      // ✅ Son yorum zamanını güncelle (19 saniye kuralı için)
      final now = DateTime.now();
      await _userLastCommentBox?.put(userEmail, now.toIso8601String());
      
      // Global istatistikleri güncelle
      final updatedStats = {
        'totalLikes': stats['totalLikes'] ?? 0,
        'totalDislikes': stats['totalDislikes'] ?? 0,
        'totalComments': (stats['totalComments'] ?? 0) + 1,
        'totalShares': stats['totalShares'] ?? 0,
        'likedBy': stats['likedBy'] ?? <String>[],
        'dislikedBy': stats['dislikedBy'] ?? <String>[],
        'gizliTanikCounter': stats['gizliTanikCounter'] ?? 0, // Gizli tanık sayacını koru
      };
      await _davaActionStatsBox?.put(davaId, updatedStats);
      
      print('✅ Dava yorum eklendi: $davaId, $userEmail, yorum sayısı: ${commentCount + 1}');
      return true;
    } catch (e) {
      print('❌ Dava yorum eklenirken hata: $e');
      return false;
    }
  }

  /// Dava paylaş (seyir defterine ekle)
  static Future<void> shareDava(String davaId, String userEmail) async {
    try {
      final key = '${davaId}_$userEmail';
      final userAction = getUserDavaAction(davaId, userEmail);
      final stats = getDavaActionStats(davaId);
      
      // Eğer daha önce paylaşılmışsa tekrar paylaşma
      if (userAction['sharedAt'] != null) {
        print('⚠️ Dava daha önce paylaşılmış: $davaId, $userEmail');
        return;
      }
      
      // Kullanıcı aksiyonunu güncelle
      final newAction = Map<String, dynamic>.from(userAction);
      newAction['sharedAt'] = DateTime.now().toIso8601String();
      await _davaActionsBox?.put(key, newAction);
      
      // Global istatistikleri güncelle
      final updatedStats = {
        'totalLikes': stats['totalLikes'] ?? 0,
        'totalDislikes': stats['totalDislikes'] ?? 0,
        'totalComments': stats['totalComments'] ?? 0,
        'totalShares': (stats['totalShares'] ?? 0) + 1,
        'likedBy': stats['likedBy'] ?? <String>[],
        'dislikedBy': stats['dislikedBy'] ?? <String>[],
      };
      await _davaActionStatsBox?.put(davaId, updatedStats);
      
      // Seyir defterine ekle
      final davaData = _getDavaDataForShare(davaId, viewerEmail: userEmail);
      if (davaData != null) {
        // ✅ Düzeltme: davaci bilgisini normalize et ve displayName ekle
        String davaciDisplayName = '';
        final davaciRaw = (davaData['davaci'] ?? '').toString().trim();
        if (davaciRaw.isNotEmpty) {
          if (davaciRaw.contains('@')) {
            // Email formatındaysa judgeName'e çevir
            try {
              final user = getRegistrationByEmail(davaciRaw);
              davaciDisplayName = user?.judgeName ?? davaciRaw.split('@')[0];
            } catch (e) {
              davaciDisplayName = davaciRaw.split('@')[0];
            }
          } else {
            // Zaten judgeName formatındaysa direkt kullan
            davaciDisplayName = davaciRaw;
          }
        }
        
        // displayName ve normalize edilmiş davaci'yi ekle
        final updatedDavaData = Map<String, dynamic>.from(davaData);
        if (davaciDisplayName.isNotEmpty) {
          updatedDavaData['displayName'] = davaciDisplayName;
          updatedDavaData['davaci'] = davaciDisplayName;
        }
        
        final postData = {
          'id': 'dava_share_${davaId}_${userEmail}_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'dava_share',
          'createdAt': DateTime.now().toIso8601String(),
          'authorEmail': userEmail,
          'payload': {
            ...updatedDavaData,
            'sharedBy': userEmail,
            'sharedAt': DateTime.now().toIso8601String(),
          },
        };
        addHomeFeedPost(postData, userEmail: userEmail);
        print('✅ Dava seyir defterine eklendi: $davaId, $userEmail, davaci: $davaciDisplayName');
      }
      
      print('✅ Dava paylaşıldı: $davaId, $userEmail');
    } catch (e) {
      print('❌ Dava paylaşılırken hata: $e');
    }
  }

  /// Kullanıcı bu davayı seyir defterinde retweet etmiş mi?
  static bool hasUserRetweetedDava(String davaId, String userEmail) {
    final posts = getHomeFeedPosts(userEmail: userEmail);
    return posts.any((post) => _isDavaRetweetPostFor(post, davaId, userEmail));
  }

  static bool _isDavaRetweetPostFor(
    Map<String, dynamic> post,
    String davaId,
    String userEmail,
  ) {
    if (post['type']?.toString() != 'dava_share') return false;
    if (post['authorEmail']?.toString() != userEmail) return false;
    final payload = post['payload'];
    if (payload is! Map) return false;
    if (payload['isRetweet'] != true) return false;
    final pid = (payload['davaId'] ?? payload['id'])?.toString() ?? '';
    return pid == davaId;
  }

  /// Retweet: basan kişinin seyir defterine `dava_share` (isRetweet) ekler.
  static Future<bool> retweetDavaToSeyirDefteri({
    required String davaId,
    required String userEmail,
    String? sourcePostId,
    String? sourceAuthorEmail,
    Map<String, dynamic>? payloadOverride,
  }) async {
    try {
      if (hasUserRetweetedDava(davaId, userEmail)) {
        print('⚠️ Dava zaten retweet edilmiş: $davaId, $userEmail');
        return false;
      }

      Map<String, dynamic>? raw = payloadOverride != null
          ? Map<String, dynamic>.from(payloadOverride)
          : _getDavaDataForShare(davaId, viewerEmail: userEmail);
      if (raw == null || raw.isEmpty) {
        print('⚠️ Retweet için dava verisi bulunamadı: $davaId');
        return false;
      }

      final Map<String, dynamic> davaData = Map<String, dynamic>.from(raw);
      davaData['id'] = davaId;
      davaData['davaId'] = davaId;

      String davaciDisplayName = '';
      final davaciRaw = (davaData['davaci'] ?? '').toString().trim();
      if (davaciRaw.isNotEmpty) {
        if (davaciRaw.contains('@')) {
          try {
            final user = getRegistrationByEmail(davaciRaw);
            davaciDisplayName = user?.judgeName ?? davaciRaw.split('@').first;
          } catch (_) {
            davaciDisplayName = davaciRaw.split('@').first;
          }
        } else {
          davaciDisplayName = davaciRaw;
        }
      }
      if (davaciDisplayName.isNotEmpty) {
        davaData['displayName'] = davaciDisplayName;
        davaData['davaci'] = davaciDisplayName;
      }

      final String nowIso = DateTime.now().toIso8601String();
      final postData = <String, dynamic>{
        'id':
            'dava_retweet_${davaId}_${userEmail}_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'dava_share',
        'createdAt': nowIso,
        'authorEmail': userEmail,
        'payload': <String, dynamic>{
          ...davaData,
          'isRetweet': true,
          'retweetedAt': nowIso,
          'retweetedBy': userEmail,
          'sourcePostId': sourcePostId,
          'sourceAuthorEmail': sourceAuthorEmail,
          'userRetweeted': true,
        },
      };
      addHomeFeedPost(postData, userEmail: userEmail);

      final key = '${davaId}_$userEmail';
      final userAction = Map<String, dynamic>.from(getUserDavaAction(davaId, userEmail));
      userAction['retweetedAt'] = nowIso;
      await _davaActionsBox?.put(key, userAction);

      print('✅ Dava retweet seyir defterine eklendi: $davaId, $userEmail');
      return true;
    } catch (e) {
      print('❌ Dava retweet eklenirken hata: $e');
      return false;
    }
  }

  /// Retweet'i basan kullanıcının seyir defterinden kaldırır.
  static Future<bool> undoRetweetDavaFromSeyirDefteri(
    String davaId,
    String userEmail,
  ) async {
    try {
      final posts = getHomeFeedPosts(userEmail: userEmail);
      final retweetPost = posts.cast<Map<String, dynamic>>().firstWhere(
            (p) => _isDavaRetweetPostFor(p, davaId, userEmail),
            orElse: () => <String, dynamic>{},
          );

      if (retweetPost.isEmpty) {
        return false;
      }

      final postId = retweetPost['id']?.toString() ?? '';
      if (postId.isNotEmpty) {
        removeHomeFeedPost(postId, userEmail: userEmail);
      }

      final key = '${davaId}_$userEmail';
      final userAction = Map<String, dynamic>.from(getUserDavaAction(davaId, userEmail));
      userAction.remove('retweetedAt');
      await _davaActionsBox?.put(key, userAction);

      print('✅ Dava retweet kaldırıldı: $davaId, $userEmail');
      return true;
    } catch (e) {
      print('❌ Dava retweet kaldırılırken hata: $e');
      return false;
    }
  }

  /// Belirli bir dava için tüm kullanıcı yorumlarını birleştirir.
  static List<Map<String, dynamic>> getAllDavaComments(String davaId) {
    try {
      if (_davaActionsBox == null) {
        return <Map<String, dynamic>>[];
      }
      final List<Map<String, dynamic>> collected = [];
      final prefix = '${davaId}_';
      for (final entry in _davaActionsBox!.toMap().entries) {
        final key = entry.key?.toString() ?? '';
        if (!key.startsWith(prefix)) continue;
        final value = entry.value;
        if (value is Map && value['yorumlar'] != null) {
          collected.addAll(CommentUtils.normalizeComments(value['yorumlar']));
        }
      }
      collected.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['tarih']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            DateTime.tryParse(b['tarih']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return collected;
    } catch (e) {
      print('❌ Dava yorumları birleştirilirken hata: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Paylaşım için dava verilerini getir
  static Map<String, dynamic>? _getDavaDataForShare(
    String davaId, {
    String? viewerEmail,
  }) {
    try {
      // Önce açılmış davalarda ara
      final openedDavalar = getOpenedDavalar();
      final dava = openedDavalar.firstWhere(
        (d) => (d['id'] ?? d['davaId'] ?? '').toString() == davaId,
        orElse: () => <String, dynamic>{},
      );
      
      if (dava.isNotEmpty) {
        return Map<String, dynamic>.from(dava);
      }
      
      // Kaydedilmiş davalarda ara
      final savedDavalar = getSavedDavalar();
      final savedDava = savedDavalar.firstWhere(
        (d) => (d['id'] ?? d['davaId'] ?? '').toString() == davaId,
        orElse: () => <String, dynamic>{},
      );
      
      if (savedDava.isNotEmpty) {
        return Map<String, dynamic>.from(savedDava);
      }

      // Gelen dava (8-Hüküm vb.): yalnızca bu kullanıcının gelen kutusu
      final String? inbox = viewerEmail?.trim();
      if (inbox != null && inbox.isNotEmpty) {
        final incoming = getIncomingDavalar(inbox);
        final incomingDava = incoming.firstWhere(
          (d) => (d['id'] ?? d['davaId'] ?? '').toString() == davaId,
          orElse: () => <String, dynamic>{},
        );
        if (incomingDava.isNotEmpty) {
          return Map<String, dynamic>.from(incomingDava);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Dava verileri alınırken hata: $e');
      return null;
    }
  }

  /// 8-Hüküm: Ceza mühürü + masraf sonrası hüküm kesinleşince, kullanıcının kendi
  /// seyir defterine [IlgililerinSeyirDefteriWidgeti] ile uyumlu `dava_share` postu.
  /// Aynı dava + kullanıcı için yalnızca bir kez eklenir.
  static Map<String, dynamic>? composeHomeFeedDavaSharePostAfterHukumFinalized({
    required String davaId,
    required String userEmail,
    Map<String, dynamic>? fallbackSnapshot,
  }) {
    final String id = davaId.trim();
    final String email = userEmail.trim();
    if (id.isEmpty || email.isEmpty) {
      return null;
    }
    final String postId = 'dava_share_hukum_${id}_$email';
    final List<Map<String, dynamic>> existing =
        getHomeFeedPosts(userEmail: email);
    if (existing.any((Map<String, dynamic> p) =>
        p['id']?.toString() == postId)) {
      return null;
    }

    Map<String, dynamic>? raw =
        _getDavaDataForShare(id, viewerEmail: email);
    if ((raw == null || raw.isEmpty) && fallbackSnapshot != null) {
      raw = Map<String, dynamic>.from(fallbackSnapshot);
    }
    if (raw == null || raw.isEmpty) {
      print(
          '⚠️ composeHomeFeedDavaSharePostAfterHukumFinalized: dava bulunamadı: $id');
      return null;
    }

    final Map<String, dynamic> davaData = Map<String, dynamic>.from(raw);
    final String davaAdiForShare =
        (davaData['davaAdi'] ?? davaData['adi'] ?? 'Dava').toString().trim();
    davaData['davaAdi'] = davaAdiForShare;
    davaData['id'] = id;
    davaData['davaId'] = id;

    String davaciDisplayName = '';
    final String davaciRaw = (davaData['davaci'] ?? '').toString().trim();
    if (davaciRaw.isNotEmpty) {
      if (davaciRaw.contains('@')) {
        try {
          final RegistrationModel? u = getRegistrationByEmail(davaciRaw);
          davaciDisplayName = u?.judgeName ?? davaciRaw.split('@').first;
        } catch (_) {
          davaciDisplayName = davaciRaw.split('@').first;
        }
      } else {
        davaciDisplayName = davaciRaw;
      }
    }
    if (davaciDisplayName.isNotEmpty) {
      davaData['displayName'] = davaciDisplayName;
      davaData['davaci'] = davaciDisplayName;
    }

    final String nowIso = DateTime.now().toIso8601String();
    return <String, dynamic>{
      'id': postId,
      'type': 'dava_share',
      'createdAt': nowIso,
      'authorEmail': email,
      'payload': <String, dynamic>{
        ...davaData,
        'sharedBy': email,
        'sharedAt': nowIso,
        'hukumFinalizeAutoShare': true,
      },
    };
  }

  // ==================== DAVA HÜKÜM VERİSİ İŞLEMLERİ ====================

  /// Dava hüküm verisi box'ını aç
  static Future<void> _ensureDavaHukumVerisiBoxOpen() async {
    if (_davaHukumVerisiBox == null || !_davaHukumVerisiBox!.isOpen) {
      _davaHukumVerisiBox = await Hive.openBox(_davaHukumVerisiBoxName);
    }
  }

  /// Dava hüküm verisini kaydet
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> saveDavaHukumVerisi(String davaId, Map<String, dynamic> hukumVerisi) async {
    try {
      await _ensureDavaHukumVerisiBoxOpen();
      _davaHukumVerisiBox?.put(davaId, hukumVerisi);
      print('✅ Dava hüküm verisi kaydedildi: $davaId');
    } catch (e) {
      print('❌ Dava hüküm verisi kaydedilirken hata: $e');
    }
  }

  /// Dava hüküm verisini getir
  static Map<String, dynamic>? getDavaHukumVerisi(String davaId) {
    try {
      final hukumVerisi = _davaHukumVerisiBox?.get(davaId);
      if (hukumVerisi != null) {
        return Map<String, dynamic>.from(hukumVerisi as Map);
      }
      return null;
    } catch (e) {
      print('❌ Dava hüküm verisi alınırken hata: $e');
      return null;
    }
  }

  // ========== HAYKIR (HAYKIRIŞ) İŞLEMLERİ ==========
  
  /// Haykır box'ını döndürür
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Box getHaykirBox() {
    if (_haykirBox == null) {
      throw Exception('Haykır box henüz başlatılmamış. HiveDatabaseService.initialize() çağrılmalı.');
    }
    return _haykirBox!;
  }

  /// Yeni haykırış ekle
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> addHaykir(Map<String, dynamic> haykirData) async {
    try {
      final box = getHaykirBox();
      final haykirId = haykirData['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Haykırış verisini hazırla ve tüm değerleri güvenli şekilde işle
      final haykirMap = <String, dynamic>{};
      
      // Tüm değerleri güvenli şekilde kopyala ve dönüştür
      haykirData.forEach((key, value) {
        if (value == null) {
          haykirMap[key] = '';
        } else if (value is bool) {
          // ✅ Boolean değerleri String'e dönüştür (Hive uyumluluğu için)
          haykirMap[key] = value.toString();
        } else if (value is String) {
          haykirMap[key] = value;
        } else {
          // Diğer tüm değerleri String'e dönüştür
          haykirMap[key] = value.toString();
        }
      });
      
      haykirMap['id'] = haykirId;
      if (!haykirMap.containsKey('createdAt')) {
        haykirMap['createdAt'] = DateTime.now().toIso8601String();
      }
      // ✅ Haykırış sayfasında görünürlük flag'i (varsayılan: true)
      if (!haykirMap.containsKey('isVisibleInHaykirPage')) {
        haykirMap['isVisibleInHaykirPage'] = 'true';
      }
      
      // ✅ Veritabanına kaydet
      await box.put(haykirId, haykirMap);
      print('✅ Haykırış veritabanına kaydedildi: $haykirId');
    } catch (e) {
      print('❌ Haykırış eklenirken hata: $e');
      rethrow;
    }
  }

  /// Haykırışı güncelle
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> updateHaykir(String haykirId, Map<String, dynamic> haykirData) async {
    try {
      final box = getHaykirBox();
      final existingData = box.get(haykirId);
      
      if (existingData == null) {
        throw Exception('Haykırış bulunamadı: $haykirId');
      }
      
      // Mevcut veriyi güncelle
      final updatedData = Map<String, dynamic>.from(existingData as Map);
      updatedData.addAll(haykirData);
      updatedData['updatedAt'] = DateTime.now().toIso8601String();
      
      // ✅ Veritabanına kaydet
      await box.put(haykirId, updatedData);
      print('✅ Haykırış güncellendi: $haykirId');
    } catch (e) {
      print('❌ Haykırış güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Haykır ile ilişkili tüm seyir defteri postlarını kaldırır (tüm kullanıcılar)
  static void removeHaykirPostsFromAllHomeFeeds(String haykirId) {
    if (_homeFeedBox == null || haykirId.isEmpty) return;

    final targetPostId = 'haykir_$haykirId';
    final retweetPrefix = 'haykir_retweet_${haykirId}_';

    for (final key in _homeFeedBox!.keys) {
      final persisted = _homeFeedBox!.get(key);
      if (persisted == null) continue;

      final list = (persisted as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final originalLength = list.length;

      list.removeWhere((post) {
        if (post['type']?.toString() != 'haykir') return false;

        final postId = post['id']?.toString() ?? '';
        if (postId == targetPostId || postId.startsWith(retweetPrefix)) {
          return true;
        }

        return post['payload']?['haykirId']?.toString() == haykirId;
      });

      if (list.length != originalLength) {
        _homeFeedBox!.put(key, list);
        print('✅ Haykır postları seyir defterinden kaldırıldı: $haykirId, $key');
      }
    }
  }

  /// Haykırışı ve ilişkili verileri kalıcı olarak sil
  static Future<void> deleteHaykir(String haykirId) async {
    try {
      removeHaykirPostsFromAllHomeFeeds(haykirId);

      final box = getHaykirBox();
      await box.delete(haykirId);
      await box.delete('haykir_stats_$haykirId');
      await box.delete('haykir_comments_$haykirId');
      print('✅ Haykırış silindi: $haykirId');
    } catch (e) {
      print('❌ Haykırış silinirken hata: $e');
      rethrow;
    }
  }

  /// Belirli bir haykırışı getir
  static Map<String, dynamic>? getHaykir(String haykirId) {
    try {
      final box = getHaykirBox();
      final data = box.get(haykirId);
      return data != null ? Map<String, dynamic>.from(data as Map) : null;
    } catch (e) {
      print('❌ Haykırış getirilirken hata: $e');
      return null;
    }
  }

  /// Kullanıcının haykırışlarını getir
  static List<Map<String, dynamic>> getUserHaykirislar(String userEmail) {
    try {
      final box = getHaykirBox();
      final allHaykirislar = <Map<String, dynamic>>[];
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final haykirMap = Map<String, dynamic>.from(data as Map);
          // ✅ Boolean değeri güvenli şekilde kontrol et (String olarak saklanıyor)
          final isActive = haykirMap['isActive'];
          final bool isActiveValue = isActive is bool 
              ? isActive 
              : (isActive?.toString().toLowerCase() == 'true' || isActive == null || isActive.toString().isEmpty);
          
          if (haykirMap['userEmail'] == userEmail && isActiveValue) {
            allHaykirislar.add(haykirMap);
          }
        }
      }
      
      // Tarihe göre sırala (en yeni önce)
      allHaykirislar.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      return allHaykirislar;
    } catch (e) {
      print('❌ Kullanıcı haykırışları getirilirken hata: $e');
      return [];
    }
  }

  /// Tüm aktif haykırışları getir (haykir_page.dart için - isVisibleInHaykirPage kontrolü ile)
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static List<Map<String, dynamic>> getAllActiveHaykirislar() {
    try {
      final box = getHaykirBox();
      final allHaykirislar = <Map<String, dynamic>>[];
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final haykirMap = Map<String, dynamic>.from(data as Map);
          // ✅ Boolean değeri güvenli şekilde kontrol et (String olarak saklanıyor)
          final isActive = haykirMap['isActive'];
          final bool isActiveValue = isActive is bool 
              ? isActive 
              : (isActive?.toString().toLowerCase() == 'true' || isActive == null || isActive.toString().isEmpty);
          
          // ✅ Haykırış sayfasında görünürlük kontrolü
          final isVisibleInHaykirPage = haykirMap['isVisibleInHaykirPage'];
          final bool isVisibleValue = isVisibleInHaykirPage is bool 
              ? isVisibleInHaykirPage 
              : (isVisibleInHaykirPage?.toString().toLowerCase() == 'true' || isVisibleInHaykirPage == null || isVisibleInHaykirPage.toString().isEmpty);
          
          if (isActiveValue && isVisibleValue) {
            allHaykirislar.add(haykirMap);
          }
        }
      }
      
      // Tarihe göre sırala (en yeni önce)
      allHaykirislar.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      return allHaykirislar;
    } catch (e) {
      print('❌ Tüm haykırışlar getirilirken hata: $e');
      return [];
    }
  }

  /// Direm kategorilerini ve verilerini veritabanına kaydet (seed)
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> seedDiremCategories() async {
    try {
      final box = getHaykirBox();
      const diremCategoriesKey = 'direm_categories';
      
      // Direm kategorilerini kaydet
      final categoriesData = {
        'categories': DiremData.categories.map((cat) => {
          'name': cat.name,
          'icon': cat.icon,
          'color': cat.color.value,
          'diremler': cat.diremler,
        }).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await box.put(diremCategoriesKey, categoriesData);
      print('✅ Direm kategorileri veritabanına kaydedildi');
    } catch (e) {
      print('❌ Direm kategorileri kaydedilirken hata: $e');
    }
  }

  /// Direm kategorilerini veritabanından getir
  static Map<String, dynamic>? getDiremCategories() {
    try {
      final box = getHaykirBox();
      const diremCategoriesKey = 'direm_categories';
      final data = box.get(diremCategoriesKey);
      return data != null ? Map<String, dynamic>.from(data as Map) : null;
    } catch (e) {
      print('❌ Direm kategorileri getirilirken hata: $e');
      return null;
    }
  }

  // ========== ÖZEL DİREN YÖNETİMİ (BAŞKA BİR DİREN) ==========
  
  /// Özel diren ekle (Başka bir diren kategorisine)
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> addOzelDirem(String diremText) async {
    try {
      if (diremText.trim().isEmpty || diremText.length > 19) {
        throw Exception('Direm metni boş olamaz ve maksimum 19 karakter olmalıdır');
      }
      
      final box = getHaykirBox();
      const ozelDiremlerKey = 'ozel_diremler_list';
      
      // Mevcut özel direnleri getir
      final existingData = box.get(ozelDiremlerKey);
      List<String> ozelDiremler = [];
      
      if (existingData != null) {
        final data = Map<String, dynamic>.from(existingData as Map);
        ozelDiremler = List<String>.from(data['diremler'] ?? []);
      }
      
      // Tekrar eklenmesini önle
      if (!ozelDiremler.contains(diremText.trim())) {
        ozelDiremler.add(diremText.trim());
        
        // ✅ Veritabanına kaydet
        await box.put(ozelDiremlerKey, {
          'diremler': ozelDiremler,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
        
        print('✅ Özel diren veritabanına kaydedildi: $diremText');
      }
    } catch (e) {
      print('❌ Özel diren eklenirken hata: $e');
      rethrow;
    }
  }

  /// Özel direnleri getir (Başka bir diren kategorisi)
  /// ✅ Veritabanından kalıcı olarak getiriliyor
  static List<String> getOzelDiremler() {
    try {
      final box = getHaykirBox();
      const ozelDiremlerKey = 'ozel_diremler_list';
      final data = box.get(ozelDiremlerKey);
      
      if (data != null) {
        final dataMap = Map<String, dynamic>.from(data as Map);
        return List<String>.from(dataMap['diremler'] ?? []);
      }
      
      return [];
    } catch (e) {
      print('❌ Özel direnler getirilirken hata: $e');
      return [];
    }
  }

  /// Özel direni sil
  /// ✅ Veritabanından kalıcı olarak siliniyor
  static Future<void> deleteOzelDirem(String diremText) async {
    try {
      final box = getHaykirBox();
      const ozelDiremlerKey = 'ozel_diremler_list';
      
      final existingData = box.get(ozelDiremlerKey);
      if (existingData != null) {
        final data = Map<String, dynamic>.from(existingData as Map);
        List<String> ozelDiremler = List<String>.from(data['diremler'] ?? []);
        
        ozelDiremler.remove(diremText.trim());
        
        // ✅ Veritabanına kaydet
        await box.put(ozelDiremlerKey, {
          'diremler': ozelDiremler,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
        
        print('✅ Özel diren silindi: $diremText');
      }
    } catch (e) {
      print('❌ Özel diren silinirken hata: $e');
      rethrow;
    }
  }

  // ========== ÜYELERDEN KATEGORİSİ YÖNETİMİ ==========
  
  /// Üyelerden kategorisine diren ekle
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> addUyelerdenDirem(String diremText) async {
    try {
      if (diremText.trim().isEmpty || diremText.length > 19) {
        throw Exception('Direm metni boş olamaz ve maksimum 19 karakter olmalıdır');
      }
      
      final box = getHaykirBox();
      const uyelerdenDiremlerKey = 'uyelerden_diremler_list';
      
      // Mevcut Üyelerden direnlerini getir
      final existingData = box.get(uyelerdenDiremlerKey);
      List<String> uyelerdenDiremler = [];
      
      if (existingData != null) {
        final data = Map<String, dynamic>.from(existingData as Map);
        uyelerdenDiremler = List<String>.from(data['diremler'] ?? []);
      }
      
      // Tekrar eklenmesini önle
      if (!uyelerdenDiremler.contains(diremText.trim())) {
        uyelerdenDiremler.add(diremText.trim());
        
        // ✅ Veritabanına kaydet
        await box.put(uyelerdenDiremlerKey, {
          'diremler': uyelerdenDiremler,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
        
        print('✅ Üyelerden diren veritabanına kaydedildi: $diremText');
      }
    } catch (e) {
      print('❌ Üyelerden diren eklenirken hata: $e');
      rethrow;
    }
  }

  /// Üyelerden kategorisindeki direnleri getir
  /// ✅ Veritabanından kalıcı olarak getiriliyor
  static List<String> getUyelerdenDiremler() {
    try {
      final box = getHaykirBox();
      const uyelerdenDiremlerKey = 'uyelerden_diremler_list';
      final data = box.get(uyelerdenDiremlerKey);
      
      if (data != null) {
        final dataMap = Map<String, dynamic>.from(data as Map);
        return List<String>.from(dataMap['diremler'] ?? []);
      }
      
      return [];
    } catch (e) {
      print('❌ Üyelerden direnler getirilirken hata: $e');
      return [];
    }
  }

  // ========== HAYKIR ETKİLEŞİM İSTATİSTİKLERİ ==========
  
  /// Haykır etkileşim istatistiklerini güncelle
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> updateHaykirInteractionStats({
    required String haykirId,
    required String userEmail,
    String? action, // 'share', 'comment', 'retweet', 'like', 'kina', 'save'
    bool? isLiked,
    bool? isSaved,
  }) async {
    try {
      final box = getHaykirBox();
      final statsKey = 'haykir_stats_$haykirId';
      
      // Mevcut istatistikleri getir
      final existingStats = box.get(statsKey);
      final stats = existingStats != null 
          ? Map<String, dynamic>.from(existingStats as Map)
          : <String, dynamic>{
              'haykirId': haykirId,
              'shareCount': 0,
              'commentCount': 0,
              'retweetCount': 0,
              'likeCount': 0,
              'kinaCount': 0,
              'userLikes': <String>[], // Beğenen kullanıcılar
              'userKinas': <String>[], // ✅ Kına yapan kullanıcılar
              'userSaves': <String>[], // Kaydeden kullanıcılar
              'userRetweets': <String>[], // ✅ Retweet yapan kullanıcılar
              'userComments': <String>[], // ✅ Yorum yapan kullanıcılar
              'lastUpdated': DateTime.now().toIso8601String(),
            };
      
      // Action'a göre istatistikleri güncelle
      if (action != null) {
        switch (action) {
          case 'share':
            stats['shareCount'] = (stats['shareCount'] as int? ?? 0) + 1;
            break;
          case 'comment':
            stats['commentCount'] = (stats['commentCount'] as int? ?? 0) + 1;
            // ✅ Kullanıcı yorum yaptıysa listeye ekle
            final userComments = List<String>.from(stats['userComments'] ?? []);
            if (!userComments.contains(userEmail)) {
              userComments.add(userEmail);
              stats['userComments'] = userComments;
            }
            break;
          case 'retweet':
            final userRetweets = List<String>.from(stats['userRetweets'] ?? []);
            if (userRetweets.contains(userEmail)) {
              userRetweets.remove(userEmail);
              final current = stats['retweetCount'] as int? ?? 1;
              stats['retweetCount'] = current > 0 ? current - 1 : 0;
            } else {
              userRetweets.add(userEmail);
              stats['retweetCount'] = (stats['retweetCount'] as int? ?? 0) + 1;
            }
            stats['userRetweets'] = userRetweets;
            break;
          case 'like':
            final userLikes = List<String>.from(stats['userLikes'] ?? []);
            if (userLikes.contains(userEmail)) {
              userLikes.remove(userEmail);
              stats['likeCount'] = (stats['likeCount'] as int? ?? 1) - 1;
            } else {
              userLikes.add(userEmail);
              stats['likeCount'] = (stats['likeCount'] as int? ?? 0) + 1;
            }
            stats['userLikes'] = userLikes;
            break;
          case 'kina':
            final userKinas = List<String>.from(stats['userKinas'] ?? []);
            if (userKinas.contains(userEmail)) {
              // Kına zaten yapılmış, kaldır
              userKinas.remove(userEmail);
              stats['kinaCount'] = (stats['kinaCount'] as int? ?? 1) - 1;
            } else {
              // Kına yap
              userKinas.add(userEmail);
              stats['kinaCount'] = (stats['kinaCount'] as int? ?? 0) + 1;
              
              // ✅ Beğen'i kaldır (birbirini dışlamalı)
              final userLikes = List<String>.from(stats['userLikes'] ?? []);
              if (userLikes.contains(userEmail)) {
                userLikes.remove(userEmail);
                stats['likeCount'] = (stats['likeCount'] as int? ?? 1) - 1;
              }
              stats['userLikes'] = userLikes;
            }
            stats['userKinas'] = userKinas;
            break;
        }
      }
      
      // Like/Save durumlarını güncelle
      if (isLiked != null) {
        final userLikes = List<String>.from(stats['userLikes'] ?? []);
        final userKinas = List<String>.from(stats['userKinas'] ?? []);
        
        if (isLiked && !userLikes.contains(userEmail)) {
          // ✅ Beğen yapılıyor - Kına'yı kaldır
          if (userKinas.contains(userEmail)) {
            userKinas.remove(userEmail);
            stats['kinaCount'] = (stats['kinaCount'] as int? ?? 1) - 1;
          }
          userLikes.add(userEmail);
          stats['likeCount'] = (stats['likeCount'] as int? ?? 0) + 1;
        } else if (!isLiked && userLikes.contains(userEmail)) {
          userLikes.remove(userEmail);
          stats['likeCount'] = (stats['likeCount'] as int? ?? 1) - 1;
        }
        stats['userLikes'] = userLikes;
        stats['userKinas'] = userKinas;
      }
      
      if (isSaved != null) {
        final userSaves = List<String>.from(stats['userSaves'] ?? []);
        if (isSaved && !userSaves.contains(userEmail)) {
          userSaves.add(userEmail);
        } else if (!isSaved && userSaves.contains(userEmail)) {
          userSaves.remove(userEmail);
        }
        stats['userSaves'] = userSaves;
      }
      
      stats['lastUpdated'] = DateTime.now().toIso8601String();
      
      // ✅ Veritabanına kaydet
      await box.put(statsKey, stats);
      print('✅ Haykır etkileşim istatistikleri güncellendi: $haykirId');
    } catch (e) {
      print('❌ Haykır etkileşim istatistikleri güncellenirken hata: $e');
      rethrow;
    }
  }
  
  /// Haykır etkileşim istatistiklerini getir
  static Map<String, dynamic> getHaykirInteractionStats(String haykirId, {String? userEmail}) {
    try {
      final box = getHaykirBox();
      final statsKey = 'haykir_stats_$haykirId';
      final stats = box.get(statsKey);
      
      if (stats == null) {
        return {
          'shareCount': 0,
          'commentCount': 0,
          'retweetCount': 0,
          'likeCount': 0,
          'kinaCount': 0,
          'isLiked': false,
          'isSaved': false,
          'isKina': false, // ✅ Kına durumu
          'isRetweeted': false, // ✅ Retweet durumu
          'isCommented': false, // ✅ Yorum durumu
        };
      }
      
      final statsMap = Map<String, dynamic>.from(stats as Map);
      final userLikes = List<String>.from(statsMap['userLikes'] ?? []);
      final userSaves = List<String>.from(statsMap['userSaves'] ?? []);
      final userKinas = List<String>.from(statsMap['userKinas'] ?? []); // ✅ Kına yapan kullanıcılar
      final userRetweets = List<String>.from(statsMap['userRetweets'] ?? []); // ✅ Retweet yapan kullanıcılar
      final userComments = List<String>.from(statsMap['userComments'] ?? []); // ✅ Yorum yapan kullanıcılar
      
      return {
        'shareCount': statsMap['shareCount'] ?? 0,
        'commentCount': statsMap['commentCount'] ?? 0,
        'retweetCount': statsMap['retweetCount'] ?? 0,
        'likeCount': statsMap['likeCount'] ?? 0,
        'kinaCount': statsMap['kinaCount'] ?? 0,
        'isLiked': userEmail != null && userLikes.contains(userEmail),
        'isSaved': userEmail != null && userSaves.contains(userEmail),
        'isKina': userEmail != null && userKinas.contains(userEmail), // ✅ Kına durumu
        'isRetweeted': userEmail != null && userRetweets.contains(userEmail), // ✅ Retweet durumu
        'isCommented': userEmail != null && userComments.contains(userEmail), // ✅ Yorum durumu
      };
    } catch (e) {
      print('❌ Haykır etkileşim istatistikleri getirilirken hata: $e');
      return {
        'shareCount': 0,
        'commentCount': 0,
        'retweetCount': 0,
        'likeCount': 0,
        'kinaCount': 0,
        'isLiked': false,
        'isSaved': false,
        'isKina': false, // ✅ Kına durumu
        'isRetweeted': false, // ✅ Retweet durumu
        'isCommented': false, // ✅ Yorum durumu
      };
    }
  }

  /// ✅ Step-1: Kullanıcının kaydettiği haykırları getir
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static List<Map<String, dynamic>> getSavedHaykirlar(String userEmail) {
    try {
      final box = getHaykirBox();
      final savedHaykirlar = <Map<String, dynamic>>[];
      
      // Tüm haykırları kontrol et
      for (var key in box.keys) {
        final keyStr = key.toString();
        
        // İstatistik anahtarlarını atla
        if (keyStr.startsWith('haykir_stats_')) {
          continue;
        }
        
        final data = box.get(key);
        if (data != null) {
          final haykirMap = Map<String, dynamic>.from(data as Map);
          
          // Haykır ID'sini al (key'den veya haykirMap'ten)
          final haykirId = haykirMap['id']?.toString() ?? keyStr;
          
          // Bu haykırın istatistiklerini kontrol et
          final statsKey = 'haykir_stats_$haykirId';
          final stats = box.get(statsKey);
          
          if (stats != null) {
            final statsMap = Map<String, dynamic>.from(stats as Map);
            final userSaves = List<String>.from(statsMap['userSaves'] ?? []);
            
            // Kullanıcı bu haykırı kaydetmiş mi?
            if (userSaves.contains(userEmail)) {
              // Haykır verilerini ve istatistikleri birleştir
              final combinedData = Map<String, dynamic>.from(haykirMap);
              combinedData['id'] = haykirId; // ID'yi garanti altına al
              combinedData['stats'] = statsMap;
              savedHaykirlar.add(combinedData);
            }
          }
        }
      }
      
      // Tarihe göre sırala (en yeni önce)
      savedHaykirlar.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      return savedHaykirlar;
    } catch (e) {
      print('❌ Kaydedilen haykırlar getirilirken hata: $e');
      return [];
    }
  }

  // ========== HAYKIR YORUMLARI ==========
  
  /// Haykır yorumu ekle
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  /// ✅ 19 saniye kuralı: Hiç kimse 19 saniye geçmeden yorum yapamaz
  static Future<Map<String, dynamic>> addHaykirComment({
    required String haykirId,
    required String userEmail,
    required String commentText,
  }) async {
    try {
      // ✅ 19 saniye kuralı kontrolü
      final lastCommentTime = _userLastCommentBox?.get(userEmail);
      if (lastCommentTime != null) {
        try {
          final lastTime = DateTime.parse(lastCommentTime.toString());
          final now = DateTime.now();
          final difference = now.difference(lastTime);
          
          if (difference.inSeconds < 19) {
            final remainingSeconds = 19 - difference.inSeconds;
            return {
              'success': false,
              'error': '19 saniye kuralı: Lütfen $remainingSeconds saniye sonra tekrar deneyin.',
              'remainingSeconds': remainingSeconds,
            };
          }
        } catch (e) {
          print('⚠️ Son yorum zamanı parse edilemedi: $e');
        }
      }
      
      final box = getHaykirBox();
      final commentsKey = 'haykir_comments_$haykirId';
      
      // Mevcut yorumları getir
      final existingComments = box.get(commentsKey);
      final comments = existingComments != null
          ? List<Map<String, dynamic>>.from(existingComments as List)
          : <Map<String, dynamic>>[];
      
      // Kullanıcı adını al
      final userName = getRegistrationByEmail(userEmail)?.judgeName ?? userEmail.split('@')[0];
      
      // Yeni yorum oluştur
      final now = DateTime.now();
      final newComment = {
        'id': now.millisecondsSinceEpoch.toString(),
        'haykirId': haykirId,
        'userEmail': userEmail,
        'userName': userName,
        'commentText': commentText,
        'createdAt': now.toIso8601String(),
        'likeCount': 0,
      };
      
      comments.add(newComment);
      
      // ✅ Veritabanına kaydet
      await box.put(commentsKey, comments);
      
      // ✅ Son yorum zamanını güncelle
      await _userLastCommentBox?.put(userEmail, now.toIso8601String());
      
      // Yorum sayısını güncelle
      await updateHaykirInteractionStats(
        haykirId: haykirId,
        userEmail: userEmail,
        action: 'comment',
      );
      
      print('✅ Haykır yorumu eklendi: $haykirId');
      return {
        'success': true,
        'message': 'Yorum başarıyla eklendi',
      };
    } catch (e) {
      print('❌ Haykır yorumu eklenirken hata: $e');
      return {
        'success': false,
        'error': 'Yorum eklenirken hata oluştu: $e',
      };
    }
  }
  
  /// Haykır yorumlarını getir
  static List<Map<String, dynamic>> getHaykirComments(String haykirId) {
    try {
      final box = getHaykirBox();
      final commentsKey = 'haykir_comments_$haykirId';
      final comments = box.get(commentsKey);
      
      if (comments == null) {
        return [];
      }
      
      final commentsList = List<Map<String, dynamic>>.from(comments as List);
      // Tarihe göre sırala (en yeni önce)
      commentsList.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      return commentsList;
    } catch (e) {
      print('❌ Haykır yorumları getirilirken hata: $e');
      return [];
    }
  }

  // ========== KAYDEDİLEN WIDGET'LAR ==========
  
  /// ✅ Step-1: Widget kaydet
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static void saveWidget({
    required String userEmail,
    required String widgetId,
    required String label,
    required String iconCodePoint, // IconData'nın codePoint'i
    required int colorValue, // Color'ın value'su
    required int count,
    bool isActive = false,
    bool isDisabled = false,
    String? sourcePage, // Hangi sayfadan kaydedildi (home_page, haykir_page, vb.)
    Map<String, dynamic>? additionalData, // Ekstra veriler
  }) {
    try {
      if (userEmail.isEmpty) {
        print('⚠️ saveWidget: userEmail boş');
        return;
      }

      final key = userEmail;
      final persisted = _savedWidgetsBox?.get(key);
      final List<Map<String, dynamic>> list = persisted != null
          ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      // Aynı widgetId'ye sahip widget varsa güncelle, yoksa ekle
      final existingIndex = list.indexWhere((w) => w['widgetId']?.toString() == widgetId);
      
      final widgetData = {
        'widgetId': widgetId,
        'label': label,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'count': count,
        'isActive': isActive,
        'isDisabled': isDisabled,
        'sourcePage': sourcePage ?? 'unknown',
        'savedAt': DateTime.now().toIso8601String(),
        'additionalData': additionalData ?? {},
      };

      if (existingIndex != -1) {
        list[existingIndex] = widgetData;
      } else {
        list.add(widgetData);
      }

      // Tarihe göre sırala (en yeni önce)
      list.sort((a, b) {
        final aTime = DateTime.tryParse(a['savedAt']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['savedAt']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      _savedWidgetsBox?.put(key, list);
      print('✅ Widget kaydedildi: $label (userEmail: $userEmail)');
    } catch (e) {
      print('❌ Widget kaydedilirken hata: $e');
    }
  }

  /// ✅ Step-1: Kaydedilen widget'ları getir
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static List<Map<String, dynamic>> getSavedWidgets(String userEmail) {
    try {
      if (userEmail.isEmpty) {
        return [];
      }

      final key = userEmail;
      final persisted = _savedWidgetsBox?.get(key);
      final List<Map<String, dynamic>> list = persisted != null
          ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      // Tarihe göre sırala (en yeni önce)
      list.sort((a, b) {
        final aTime = DateTime.tryParse(a['savedAt']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['savedAt']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      print('❌ Kaydedilen widget\'lar getirilirken hata: $e');
      return [];
    }
  }

  /// ✅ Step-1: Kaydedilen widget'ı sil
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static void deleteSavedWidget({
    required String userEmail,
    required String widgetId,
  }) {
    try {
      if (userEmail.isEmpty) {
        print('⚠️ deleteSavedWidget: userEmail boş');
        return;
      }

      final key = userEmail;
      final persisted = _savedWidgetsBox?.get(key);
      final List<Map<String, dynamic>> list = persisted != null
          ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      list.removeWhere((w) => w['widgetId']?.toString() == widgetId);
      _savedWidgetsBox?.put(key, list);
      print('✅ Widget silindi: $widgetId (userEmail: $userEmail)');
    } catch (e) {
      print('❌ Widget silinirken hata: $e');
    }
  }

  /// ✅ Step-1: Widget'ın kaydedilip kaydedilmediğini kontrol et
  static bool isWidgetSaved({
    required String userEmail,
    required String widgetId,
  }) {
    try {
      if (userEmail.isEmpty) {
        return false;
      }

      final key = userEmail;
      final persisted = _savedWidgetsBox?.get(key);
      final List<Map<String, dynamic>> list = persisted != null
          ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      return list.any((w) => w['widgetId']?.toString() == widgetId);
    } catch (e) {
      print('❌ Widget kayıt kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // ========== ALBÜM İŞLEMLERİ (STEP-3) ==========

  /// ✅ Veritabanına kaydediliyor: Yeni albüm oluştur
  static Future<String> createAlbum({
    required String name,
    required String userEmail,
    String? description,
  }) async {
    try {
      final albumId = 'album_${DateTime.now().millisecondsSinceEpoch}';
      final album = AlbumModel(
        id: albumId,
        name: name,
        userEmail: userEmail,
        createdAt: DateTime.now(),
        description: description,
      );

      final key = userEmail;
      final persisted = _albumBox?.get(key);
      final List<Map<String, dynamic>> list = persisted != null
          ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      list.add(album.toJson());
      await _albumBox?.put(key, list);

      // ✅ Kalıcı olarak saklanıyor
      print('✅ Albüm oluşturuldu: $albumId');
      return albumId;
    } catch (e) {
      print('❌ Albüm oluşturulurken hata: $e');
      rethrow;
    }
  }

  /// ✅ Uygulama yeniden başlatıldığında korunuyor: Kullanıcının tüm albümlerini getir
  static List<AlbumModel> getAlbums(String userEmail) {
    try {
      final key = userEmail;
      final persisted = _albumBox?.get(key);
      if (persisted == null) {
        return [];
      }

      final List<Map<String, dynamic>> list = (persisted as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      return list.map((json) => AlbumModel.fromJson(json)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni önce
    } catch (e) {
      print('❌ Albümler getirilirken hata: $e');
      return [];
    }
  }

  /// ✅ Veritabanına kaydediliyor: Albümü güncelle
  static Future<bool> updateAlbum({
    required String albumId,
    required String userEmail,
    String? name,
    String? description,
  }) async {
    try {
      final key = userEmail;
      final persisted = _albumBox?.get(key);
      if (persisted == null) {
        return false;
      }

      final List<Map<String, dynamic>> list = (persisted as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final index = list.indexWhere((a) => a['id'] == albumId);
      if (index == -1) {
        return false;
      }

      final album = AlbumModel.fromJson(list[index]);
      final updatedAlbum = album.copyWith(
        name: name ?? album.name,
        description: description ?? album.description,
        updatedAt: DateTime.now(),
      );

      list[index] = updatedAlbum.toJson();
      await _albumBox?.put(key, list);

      // ✅ Kalıcı olarak saklanıyor
      print('✅ Albüm güncellendi: $albumId');
      return true;
    } catch (e) {
      print('❌ Albüm güncellenirken hata: $e');
      return false;
    }
  }

  /// ✅ Veritabanına kaydediliyor: Albümü sil
  static Future<bool> deleteAlbum({
    required String albumId,
    required String userEmail,
  }) async {
    try {
      final key = userEmail;
      final persisted = _albumBox?.get(key);
      if (persisted == null) {
        return false;
      }

      final List<Map<String, dynamic>> list = (persisted as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      list.removeWhere((a) => a['id'] == albumId);
      await _albumBox?.put(key, list);

      // Albüm resimlerini de sil
      await deleteAllAlbumImages(albumId);

      // ✅ Kalıcı olarak saklanıyor
      print('✅ Albüm silindi: $albumId');
      return true;
    } catch (e) {
      print('❌ Albüm silinirken hata: $e');
      return false;
    }
  }

  /// ✅ Veritabanına kaydediliyor: Albüme resim ekle
  static Future<String> addImageToAlbum({
    required String albumId,
    required String imageUrl,
    String? imagePath,
    String? title,
    String? description,
    int fileSize = 0,
  }) async {
    try {
      final imageId = 'img_${DateTime.now().millisecondsSinceEpoch}';
      final image = AlbumImageModel(
        id: imageId,
        albumId: albumId,
        imageUrl: imageUrl,
        imagePath: imagePath,
        createdAt: DateTime.now(),
        title: title,
        description: description,
        fileSize: fileSize,
      );

      final key = albumId;
      final persisted = _albumImageBox?.get(key);
      final List<Map<String, dynamic>> list = persisted != null
          ? (persisted as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      list.add(image.toJson());
      await _albumImageBox?.put(key, list);

      // ✅ Kalıcı olarak saklanıyor
      print('✅ Resim albüme eklendi: $imageId');
      return imageId;
    } catch (e) {
      print('❌ Resim albüme eklenirken hata: $e');
      rethrow;
    }
  }

  /// ✅ Uygulama yeniden başlatıldığında korunuyor: Albümdeki tüm resimleri getir
  static List<AlbumImageModel> getAlbumImages(String albumId) {
    try {
      final key = albumId;
      final persisted = _albumImageBox?.get(key);
      if (persisted == null) {
        return [];
      }

      final List<Map<String, dynamic>> list = (persisted as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      return list.map((json) => AlbumImageModel.fromJson(json)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni önce
    } catch (e) {
      print('❌ Albüm resimleri getirilirken hata: $e');
      return [];
    }
  }

  /// ✅ Veritabanına kaydediliyor: Albüm resmini sil
  static Future<bool> deleteAlbumImage({
    required String imageId,
    required String albumId,
  }) async {
    try {
      final key = albumId;
      final persisted = _albumImageBox?.get(key);
      if (persisted == null) {
        return false;
      }

      final List<Map<String, dynamic>> list = (persisted as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      list.removeWhere((img) => img['id'] == imageId);
      await _albumImageBox?.put(key, list);

      // ✅ Kalıcı olarak saklanıyor
      print('✅ Albüm resmi silindi: $imageId');
      return true;
    } catch (e) {
      print('❌ Albüm resmi silinirken hata: $e');
      return false;
    }
  }

  /// ✅ Veritabanına kaydediliyor: Albümdeki tüm resimleri sil
  static Future<bool> deleteAllAlbumImages(String albumId) async {
    try {
      final key = albumId;
      await _albumImageBox?.delete(key);
      // ✅ Kalıcı olarak saklanıyor
      print('✅ Albümdeki tüm resimler silindi: $albumId');
      return true;
    } catch (e) {
      print('❌ Albüm resimleri silinirken hata: $e');
      return false;
    }
  }

  /// ✅ Step-4.1: Albümü kopyala (tüm resimlerle birlikte)
  /// ✅ Veritabanına kaydediliyor
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<String> copyAlbum({
    required String albumId,
    required String userEmail,
    String? newName,
  }) async {
    try {
      // Orijinal albümü al
      final albums = getAlbums(userEmail);
      final originalAlbum = albums.firstWhere(
        (a) => a.id == albumId,
        orElse: () => throw Exception('Albüm bulunamadı'),
      );

      // Yeni albüm oluştur
      final newAlbumName = newName ?? '${originalAlbum.name} (Kopya)';
      final newAlbumId = await createAlbum(
        name: newAlbumName,
        userEmail: userEmail,
        description: originalAlbum.description,
      );

      // Orijinal albümün resimlerini al
      final originalImages = getAlbumImages(albumId);

      // Resimleri yeni albüme kopyala
      for (final image in originalImages) {
        await addImageToAlbum(
          albumId: newAlbumId,
          imageUrl: image.imageUrl,
          imagePath: image.imagePath,
          fileSize: image.fileSize,
        );
      }

      print('✅ Albüm kopyalandı: $albumId -> $newAlbumId');
      return newAlbumId;
    } catch (e) {
      print('❌ Albüm kopyalanırken hata: $e');
      rethrow;
    }
  }
}