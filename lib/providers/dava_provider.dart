import 'dart:async';
import '../services/hive_database_service.dart';
import 'base_provider.dart';

/// Dava yönetimi için provider
class DavaProvider extends BaseProvider {
  List<Map<String, dynamic>> _incomingDavalar = [];
  List<Map<String, dynamic>> _savedDavalar = [];
  List<Map<String, dynamic>> _openedDavalar = [];
  List<Map<String, dynamic>> _invitations = [];
  List<Map<String, dynamic>> _homeFeedPosts = [];
  List<Map<String, dynamic>> _rejectedDavalar = [];
  List<Map<String, dynamic>> _acceptedDavalar = [];
  List<Map<String, dynamic>> _katildigimDavalar = [];
  
  StreamSubscription? _incomingSubscription;
  String? _currentUserEmail;
  
  // Hüküm güncellemelerini takip etmek için versiyon numarası
  int _hukumUpdateVersion = 0;
  
  /// Hüküm güncelleme versiyonu (senkronizasyon için)
  int get hukumUpdateVersion => _hukumUpdateVersion;

  /// Gelen davalar
  List<Map<String, dynamic>> get incomingDavalar => _incomingDavalar;

  /// Kaydedilen davalar
  List<Map<String, dynamic>> get savedDavalar => _savedDavalar;

  /// Açılan davalar
  List<Map<String, dynamic>> get openedDavalar => _openedDavalar;

  /// Davetler
  List<Map<String, dynamic>> get invitations => _invitations;

  /// Home feed postları
  List<Map<String, dynamic>> get homeFeedPosts => _homeFeedPosts;

  /// Red edilen davalar
  List<Map<String, dynamic>> get rejectedDavalar => _rejectedDavalar;

  /// Kabul edilen davalar (Yargıla sayfası için)
  List<Map<String, dynamic>> get acceptedDavalar => _acceptedDavalar;

  /// Katıldığım davalar
  List<Map<String, dynamic>> get katildigimDavalar => _katildigimDavalar;

  /// Gelen dava sayısı
  int get incomingDavaCount => _incomingDavalar.length;

  /// Kaydedilen dava sayısı
  int get savedDavaCount => _savedDavalar.length;

  /// Açılan dava sayısı
  int get openedDavaCount => _openedDavalar.length;

  /// Davet sayısı
  int get invitationCount => _invitations.length;

  /// Aktif davet sayısı
  int get activeInvitationCount => _invitations.where((inv) => !(inv['isFinished'] ?? false)).length;

  /// Red edilen dava sayısı
  int get rejectedDavaCount => _rejectedDavalar.length;

  /// Mevcut kullanıcı e-postası
  String? get currentUserEmail => _currentUserEmail;

  /// Kullanıcı için dava verilerini yükle
  Future<void> loadUserData(String userEmail) async {
    if (_currentUserEmail == userEmail && _incomingDavalar.isNotEmpty) {
      return; // Zaten yüklenmiş
    }

    _currentUserEmail = userEmail;
    
    await executeAsync(
      () async {
        // Tüm dava verilerini paralel olarak yükle
        await Future.wait([
          _loadIncomingDavalar(userEmail),
          _loadSavedDavalar(),
          _loadOpenedDavalar(),
          _loadInvitations(userEmail),
          _loadHomeFeedPosts(userEmail), // ✅ Düzeltme: userEmail parametresi eklendi
          _loadKatildigimDavalar(userEmail),
        ]);
      },
      errorMessage: 'Dava verileri yüklenirken hata oluştu',
    );
  }

  /// Gelen davaları yükle
  Future<void> _loadIncomingDavalar(String userEmail) async {
    _incomingDavalar = HiveDatabaseService.getIncomingDavalar(userEmail);
  }

  /// Kaydedilen davaları yükle
  Future<void> _loadSavedDavalar() async {
    _savedDavalar = HiveDatabaseService.getSavedDavalar();
  }

  /// Açılan davaları yükle
  Future<void> _loadOpenedDavalar() async {
    _openedDavalar = HiveDatabaseService.getOpenedDavalar();
  }

  /// Davetleri yükle
  Future<void> _loadInvitations(String userEmail) async {
    _invitations = HiveDatabaseService.getInvitations(userEmail);
  }

  /// Home feed postlarını yükle (bitirilen postları filtrele)
  Future<void> _loadHomeFeedPosts(String userEmail) async {
    // ✅ Düzeltme: Kullanıcı bazlı paylaşımları getir
    final allPosts = HiveDatabaseService.getHomeFeedPosts(userEmail: userEmail);
    // Bitirilen postları filtrele
    _homeFeedPosts = allPosts.where((post) {
      final payload = post['payload'];
      if (payload is Map) {
        return !(payload['isFinished'] ?? false);
      }
      return true;
    }).toList();
  }

  /// Katıldığım davaları yükle
  Future<void> _loadKatildigimDavalar(String userEmail) async {
    _katildigimDavalar = HiveDatabaseService.getKatildigimDavalar(userEmail);
  }

  /// Katıldığım davaları yeniden yükle (public)
  Future<void> reloadKatildigimDavalar(String userEmail) async {
    await _loadKatildigimDavalar(userEmail);
    notifyListeners();
  }

  /// Gelen davaları yeniden yükle (public)
  Future<void> reloadIncomingDavalar(String userEmail) async {
    await _loadIncomingDavalar(userEmail);
    notifyListeners();
  }

  /// Gelen davaları canlı izle
  void startWatchingIncoming(String userEmail) {
    if (_currentUserEmail == userEmail && _incomingSubscription != null) {
      return; // Zaten izleniyor
    }

    _incomingSubscription?.cancel();
    _currentUserEmail = userEmail;

    _incomingSubscription = HiveDatabaseService
        .watchIncomingFor(userEmail)
        .listen((_) {
      if (_currentUserEmail == userEmail) {
        _loadIncomingDavalar(userEmail);
        notifyListeners();
      }
    });
  }

  /// Canlı izlemeyi durdur
  void stopWatchingIncoming() {
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
  }

  /// Dava kaydet
  Future<bool> saveDava(Map<String, dynamic> dava) async {
    return await executeAsync(
      () async {
        HiveDatabaseService.saveDava(dava);
        await _loadSavedDavalar();
        return true;
      },
      errorMessage: 'Dava kaydedilirken hata oluştu',
      successMessage: 'Dava başarıyla kaydedildi',
    ) ?? false;
  }

  /// Dava aç
  Future<bool> openDava(Map<String, dynamic> dava) async {
    return await executeAsync(
      () async {
        HiveDatabaseService.saveOpenedDava(dava);
        await _loadOpenedDavalar();
        return true;
      },
      errorMessage: 'Dava açılırken hata oluştu',
      successMessage: 'Dava başarıyla açıldı',
    ) ?? false;
  }

  /// Kaydedilen davayı sil
  Future<bool> deleteSavedDava(String davaId) async {
    return await executeAsync(
      () async {
        HiveDatabaseService.deleteSavedDava(davaId);
        await _loadSavedDavalar();
        return true;
      },
      errorMessage: 'Dava silinirken hata oluştu',
      successMessage: 'Dava başarıyla silindi',
    ) ?? false;
  }

  /// Açılan davayı sil
  Future<bool> deleteOpenedDava(String davaId) async {
    return await executeAsync(
      () async {
        HiveDatabaseService.deleteOpenedDava(davaId);
        await _loadOpenedDavalar();
        return true;
      },
      errorMessage: 'Dava silinirken hata oluştu',
      successMessage: 'Dava başarıyla silindi',
    ) ?? false;
  }

  /// Davet ekle
  Future<bool> addInvitation(String userEmail, Map<String, dynamic> invitation) async {
    return await executeAsync(
      () async {
        HiveDatabaseService.addInvitation(userEmail, invitation);
        if (_currentUserEmail == userEmail) {
          await _loadInvitations(userEmail);
        }
        return true;
      },
      errorMessage: 'Davet eklenirken hata oluştu',
      successMessage: 'Davet başarıyla eklendi',
    ) ?? false;
  }

  /// Daveti bitir
  Future<bool> markInvitationFinished(String userEmail, String davaId) async {
    return await executeAsync(
      () async {
        await HiveDatabaseService.markInvitationFinished(
          userEmail: userEmail,
          davaId: davaId,
        );
        if (_currentUserEmail == userEmail) {
          await _loadInvitations(userEmail);
        }
        return true;
      },
      errorMessage: 'Davet bitirilirken hata oluştu',
      successMessage: 'Davet başarıyla bitirildi',
    ) ?? false;
  }

  /// Home feed postu ekle
  Future<bool> addHomeFeedPost(Map<String, dynamic> post) async {
    return await executeAsync(
      () async {
        // ✅ Düzeltme: authorEmail'den userEmail'i al
        final userEmail = post['authorEmail'] ?? _currentUserEmail;
        HiveDatabaseService.addHomeFeedPost(post, userEmail: userEmail);
        if (_currentUserEmail != null) {
          await _loadHomeFeedPosts(_currentUserEmail!);
        }
        return true;
      },
      errorMessage: 'Post eklenirken hata oluştu',
      successMessage: 'Post başarıyla eklendi',
    ) ?? false;
  }

  /// Home feed postunu güncelle
  Future<bool> updateHomeFeedPost(String postId, Map<String, dynamic> updatedPost) async {
    return await executeAsync(
      () async {
        // ✅ Düzeltme: authorEmail'den userEmail'i al
        final userEmail = updatedPost['authorEmail'] ?? _currentUserEmail;
        HiveDatabaseService.updateHomeFeedPost(postId, updatedPost, userEmail: userEmail);
        if (_currentUserEmail != null) {
          await _loadHomeFeedPosts(_currentUserEmail!);
        }
        return true;
      },
      errorMessage: 'Post güncellenirken hata oluştu',
      successMessage: 'Post başarıyla güncellendi',
    ) ?? false;
  }

  /// Home feed postunu sil
  Future<bool> removeHomeFeedPost(String postId) async {
    return await executeAsync(
      () async {
        if (_currentUserEmail == null) {
          return false;
        }
        HiveDatabaseService.removeHomeFeedPost(postId, userEmail: _currentUserEmail);
        await _loadHomeFeedPosts(_currentUserEmail!);
        return true;
      },
      errorMessage: 'Post silinirken hata oluştu',
      successMessage: 'Post başarıyla silindi',
    ) ?? false;
  }

  /// Belirli bir davayı getir
  Map<String, dynamic>? getDavaById(String davaId) {
    // Önce kaydedilen davalarda ara
    try {
      return _savedDavalar.firstWhere((d) => d['id'] == davaId);
    } catch (e) {
      // Sonra açılan davalarda ara
      try {
        return _openedDavalar.firstWhere((d) => d['id'] == davaId);
      } catch (e) {
        // Son olarak gelen davalarda ara
        try {
          return _incomingDavalar.firstWhere((d) => d['id'] == davaId);
        } catch (e) {
          return null;
        }
      }
    }
  }

  /// Belirli bir daveti getir
  Map<String, dynamic>? getInvitationById(String invitationId) {
    try {
      return _invitations.firstWhere((inv) => inv['id'] == invitationId);
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir home feed postunu getir
  Map<String, dynamic>? getHomeFeedPostById(String postId) {
    try {
      return _homeFeedPosts.firstWhere((post) => post['id'] == postId);
    } catch (e) {
      return null;
    }
  }

  /// Tüm verileri yenile
  Future<void> refreshAll() async {
    if (_currentUserEmail == null) return;

    await executeAsync(
      () async {
        await Future.wait([
          _loadIncomingDavalar(_currentUserEmail!),
          _loadSavedDavalar(),
          _loadOpenedDavalar(),
          _loadInvitations(_currentUserEmail!),
          _loadHomeFeedPosts(_currentUserEmail!), // ✅ Düzeltme: userEmail parametresi eklendi
        ]);
      },
      errorMessage: 'Veriler yenilenirken hata oluştu',
    );
  }

  /// Belirli kategorideki davaları filtrele
  List<Map<String, dynamic>> getDavalarByCategory(String category) {
    return _savedDavalar.where((dava) => 
        dava['davaKategorisi'] == category || 
        dava['kategori'] == category
    ).toList();
  }

  /// Belirli kullanıcının davalarını filtrele
  List<Map<String, dynamic>> getDavalarByUser(String userEmail) {
    return _savedDavalar.where((dava) => 
        dava['davaci'] == userEmail || 
        dava['userEmail'] == userEmail
    ).toList();
  }

  /// Tüm kaydedilen davaları temizle
  Future<bool> clearSavedDavalar() async {
    return await executeAsync(
      () async {
        HiveDatabaseService.clearSavedDavalar();
        await _loadSavedDavalar();
        return true;
      },
      errorMessage: 'Davalar temizlenirken hata oluştu',
      successMessage: 'Tüm davalar temizlendi',
    ) ?? false;
  }

  /// Tüm açılan davaları temizle
  Future<bool> clearOpenedDavalar() async {
    return await executeAsync(
      () async {
        HiveDatabaseService.clearOpenedDavalar();
        await _loadOpenedDavalar();
        return true;
      },
      errorMessage: 'Davalar temizlenirken hata oluştu',
      successMessage: 'Tüm açılan davalar temizlendi',
    ) ?? false;
  }

  /// Dava red et - gelen davalardan kaldır ve red edilenlere ekle
  Future<bool> rejectDava(Map<String, dynamic> dava) async {
    return await executeAsync(
      () async {
        // Dava verilerini güncelle
        final rejectedDava = Map<String, dynamic>.from(dava);
        rejectedDava['status'] = 'rejected';
        rejectedDava['rejectedAt'] = DateTime.now().toIso8601String();
        rejectedDava['isActive'] = false;
        
        // Gelen davalardan kaldır
        _incomingDavalar.removeWhere((item) => item['id'] == dava['id']);
        
        // Red edilen davalara ekle
        _rejectedDavalar.add(rejectedDava);
        
        // Veritabanına kaydet
        await HiveDatabaseService.saveRejectedDava(rejectedDava);
        await HiveDatabaseService.removeIncomingDava(dava['id']);
        final String? davaId = rejectedDava['id']?.toString() ?? rejectedDava['davaId']?.toString();
        final String? participantEmail = rejectedDava['userEmail']?.toString();
        if (davaId != null && participantEmail != null && participantEmail.isNotEmpty) {
          await HiveDatabaseService.markDavaParticipantStatus(
            davaId: davaId,
            userEmail: participantEmail,
            status: 'manual_rejected',
            statusAt: DateTime.tryParse(rejectedDava['rejectedAt']?.toString() ?? ''),
            reason: 'user_rejected',
          );
        }

        notifyListeners();
        return true;
      },
      errorMessage: 'Dava red edilirken hata oluştu',
      successMessage: 'Dava reddedildi',
    ) ?? false;
  }

  /// Red edilen davaları yükle
  Future<void> loadRejectedDavalar() async {
    try {
      _rejectedDavalar = await HiveDatabaseService.getRejectedDavalar(_currentUserEmail ?? '');
      notifyListeners();
    } catch (e) {
      print('Red edilen davalar yüklenirken hata: $e');
      _rejectedDavalar = [];
    }
  }

  /// Dava kabul et - gelen davalardan kaldır ve kabul edilenlere ekle
  Future<bool> acceptDava(Map<String, dynamic> dava) async {
    return await executeAsync(
      () async {
        // Dava verilerini güncelle
        final acceptedDava = Map<String, dynamic>.from(dava);
        acceptedDava['status'] = 'accepted';
        acceptedDava['acceptedAt'] = DateTime.now().toIso8601String();
        acceptedDava['isActive'] = true;
        
        // Dava ID'sini belirle (id veya davaId alanından)
        final String? davaIdToRemove = dava['id']?.toString() ?? dava['davaId']?.toString();
        
        if (davaIdToRemove == null || davaIdToRemove.isEmpty) {
          print('❌ [DavaProvider] acceptDava: Dava ID bulunamadı!');
          return false;
        }
        
        print('✅ [DavaProvider] acceptDava çağrıldı:');
        print('   - Dava ID (kaldırılacak): $davaIdToRemove');
        print('   - Dava Adı: ${dava['adi']}');
        print('   - User Email: ${dava['userEmail']}');
        
        // Gelen davalardan kaldır (hem id hem davaId ile kontrol et)
        final removedCount = _incomingDavalar.length;
        _incomingDavalar.removeWhere((item) {
          final itemId = item['id']?.toString() ?? '';
          final itemDavaId = item['davaId']?.toString() ?? '';
          return itemId == davaIdToRemove || itemDavaId == davaIdToRemove;
        });
        final newCount = _incomingDavalar.length;
        print('   - Gelen davalardan kaldırıldı: ${removedCount - newCount} adet');
        
        // Kabul edilen davalara ekle
        _acceptedDavalar.add(acceptedDava);
        
        // Veritabanına kaydet
        await HiveDatabaseService.saveAcceptedDava(acceptedDava);
        await HiveDatabaseService.removeIncomingDava(davaIdToRemove);
        final String? davaId = acceptedDava['id']?.toString() ?? acceptedDava['davaId']?.toString();
        final String? participantEmail = acceptedDava['userEmail']?.toString();
        if (davaId != null && participantEmail != null && participantEmail.isNotEmpty) {
          await HiveDatabaseService.markDavaParticipantStatus(
            davaId: davaId,
            userEmail: participantEmail,
            status: 'accepted',
            statusAt: DateTime.tryParse(acceptedDava['acceptedAt']?.toString() ?? ''),
            extra: {
              if (acceptedDava['userRole'] != null) 'mevkii': acceptedDava['userRole'],
              if (acceptedDava['mevkii'] != null) 'mevkii': acceptedDava['mevkii'],
            },
          );
        }

        notifyListeners();
        return true;
      },
      errorMessage: 'Dava kabul edilirken hata oluştu',
      successMessage: 'Dava kabul edildi',
    ) ?? false;
  }

  /// Kabul edilen davaları yükle
  Future<void> loadAcceptedDavalar() async {
    try {
      _acceptedDavalar = await HiveDatabaseService.getAcceptedDavalar(_currentUserEmail ?? '');
      notifyListeners();
    } catch (e) {
      print('Kabul edilen davalar yüklenirken hata: $e');
      _acceptedDavalar = [];
    }
  }

  /// Belirli bir dava için engagement verilerini güncelle
  /// Bu metod tüm sayfalardaki engagement verilerini senkronize eder
  Future<bool> updateDavaEngagement({
    required String davaId,
    int? yorumSayisi,
    int? retweetSayisi,
    int? begeniSayisi,
    int? begenmemeSayisi,
    bool? userLiked,
    bool? userDisliked,
    bool? userRetweeted,
    List<Map<String, dynamic>>? yorumlar,
    String? userEmail,
  }) async {
    return await executeAsync(
      () async {
        await HiveDatabaseService.updateDavaEngagement(
          davaId: davaId,
          yorumSayisi: yorumSayisi,
          retweetSayisi: retweetSayisi,
          begeniSayisi: begeniSayisi,
          begenmemeSayisi: begenmemeSayisi,
          userLiked: userLiked,
          userDisliked: userDisliked,
          userRetweeted: userRetweeted,
          yorumlar: yorumlar,
          userEmail: userEmail,
        );
        
        // Tüm verileri yeniden yükle
        if (_currentUserEmail != null) {
          await Future.wait([
            _loadIncomingDavalar(_currentUserEmail!),
            _loadOpenedDavalar(),
            _loadHomeFeedPosts(_currentUserEmail!), // ✅ Düzeltme: userEmail parametresi eklendi
          ]);
        }
        return true;
      },
      errorMessage: 'Engagement verileri güncellenirken hata oluştu',
    ) ?? false;
  }

  /// Belirli bir dava için hüküm verilerini getir
  Future<Map<String, Map<String, dynamic>>> getHukumlerByDavaId(String davaId, {String? davaAdi}) async {
    return await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId, davaAdi: davaAdi);
  }

  /// Belirli bir dava için hüküm verilerini güncelle
  /// Bu metod tüm sayfalardaki hüküm verilerini senkronize eder
  Future<bool> updateHukumForDava({
    required String davaId,
    required String userRole,
    required String hukumText,
    required String userEmail,
    String? hukumSentiment,
    bool isFinalized = false,
  }) async {
    return await executeAsync(
      () async {
        await HiveDatabaseService.saveHukum(
          davaId: davaId,
          userRole: userRole,
          hukumText: hukumText,
          userEmail: userEmail,
          hukumSentiment: hukumSentiment,
          isFinalized: isFinalized,
        );
        // Hüküm güncelleme versiyonunu artır (senkronizasyon için)
        _hukumUpdateVersion++;
        // Hüküm kaydedildikten sonra tüm dinleyicilere bildir
        notifyListeners();
        return true;
      },
      errorMessage: 'Hüküm kaydedilirken hata oluştu',
      successMessage: 'Hüküm başarıyla kaydedildi',
    ) ?? false;
  }

  /// Belirli bir dava için ceza verilerini güncelle
  /// Bu metod tüm sayfalardaki ceza verilerini senkronize eder
  Future<bool> updateCezaForDava({
    required String davaId,
    required String userEmail,
    required String cezaText,
  }) async {
    return await executeAsync(
      () async {
        await HiveDatabaseService.saveCeza(
          davaId: davaId,
          userEmail: userEmail,
          cezaText: cezaText,
        );
        print('✅ [DavaProvider] Ceza kaydedildi ve dinleyicilere bildirildi');
        // Ceza kaydedildikten sonra tüm dinleyicilere bildir
        notifyListeners();
        return true;
      },
      errorMessage: 'Ceza kaydedilirken hata oluştu',
      successMessage: 'Ceza başarıyla kaydedildi',
    ) ?? false;
  }

  /// Belirli bir dava için masraf verilerini güncelle
  /// Bu metod tüm sayfalardaki masraf verilerini senkronize eder
  Future<bool> updateMasrafForDava({
    required String davaId,
    required String userEmail,
    required List<String> masraflar,
  }) async {
    return await executeAsync(
      () async {
        await HiveDatabaseService.saveMasrafExpenses(
          davaId: davaId,
          userEmail: userEmail,
          expenses: masraflar,
        );
        print('✅ [DavaProvider] Masraf kaydedildi ve dinleyicilere bildirildi');
        // Masraf kaydedildikten sonra tüm dinleyicilere bildir
        notifyListeners();
        return true;
      },
      errorMessage: 'Masraf kaydedilirken hata oluştu',
      successMessage: 'Masraf başarıyla kaydedildi',
    ) ?? false;
  }

  @override
  void dispose() {
    stopWatchingIncoming();
    super.dispose();
  }
}
