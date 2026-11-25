import 'package:hive/hive.dart';
import '../models/evidence_model.dart';

class EvidenceService {
  static const String _boxName = 'evidence_box';
  late Box<EvidenceModel> _evidenceBox;

  // Singleton pattern
  static final EvidenceService _instance = EvidenceService._internal();
  factory EvidenceService() => _instance;
  EvidenceService._internal();

  // Hive box'ını başlat
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _evidenceBox = await Hive.openBox<EvidenceModel>(_boxName);
    } else {
      _evidenceBox = Hive.box<EvidenceModel>(_boxName);
    }
  }

  // Delil ekleme (geliştirilmiş doğrulama ile)
  Future<Map<String, dynamic>> addEvidence(EvidenceModel evidence) async {
    try {
      print('🔍 EvidenceService.addEvidence başlatılıyor...');
      print('📋 Delil bilgileri: ID=${evidence.id}, DavaID=${evidence.davaId}, Tip=${evidence.type}, Başlık=${evidence.title}');
      
      // Doğrulama kontrolleri
      print('🔍 Doğrulama kontrolleri yapılıyor...');
      final validationResult = _validateEvidence(evidence);
      print('🔍 Doğrulama sonucu: $validationResult');
      
      if (!validationResult['isValid']) {
        print('❌ Doğrulama başarısız: ${validationResult['error']}');
        return validationResult;
      }

      // Özel ID oluşturma
      print('🔍 Özel ID oluşturuluyor...');
      final existingEvidences = getEvidenceByDavaId(evidence.davaId);
      print('🔍 Mevcut delil sayısı: ${existingEvidences.length}');
      
      final newId = EvidenceModel.generateEvidenceId(evidence.davaId, existingEvidences.length);
      print('🔍 Yeni ID oluşturuldu: $newId');
      
      evidence = evidence.copyWith(id: newId);
      print('🔍 EvidenceModel güncellendi, yeni ID: ${evidence.id}');
      print('🔍 Delil detayları: DavaId=${evidence.davaId}, Type=${evidence.type}, Title=${evidence.title}');

      print('🔍 Hive box\'a kaydediliyor...');
      await _evidenceBox.put(evidence.id, evidence);
      
      print('✅ Veritabanına kaydediliyor: ${evidence.title}');
      print('✅ Kalıcı olarak saklanıyor: ${evidence.type} delili');
      print('✅ Uygulama yeniden başlatıldığında korunuyor');
      
      // Kaydedilen delili doğrulama için tekrar oku
      final savedEvidence = _evidenceBox.get(evidence.id);
      if (savedEvidence != null) {
        print('✅ Kaydedilen delil doğrulandı: ID=${savedEvidence.id}, DavaId=${savedEvidence.davaId}, Type=${savedEvidence.type}');
      } else {
        print('❌ Delil kaydedilemedi!');
      }
      
      final result = {'isValid': true, 'evidence': evidence};
      print('✅ İşlem tamamlandı: $result');
      return result;
    } catch (e) {
      print('❌ Delil eklenirken hata: $e');
      print('❌ Hata detayı: ${e.toString()}');
      return {'isValid': false, 'error': 'Delil eklenirken hata oluştu: $e'};
    }
  }

  // Delil doğrulama
  Map<String, dynamic> _validateEvidence(EvidenceModel evidence) {
    // Başlık doğrulama
    if (!EvidenceLimits.isValidTitle(evidence.title)) {
      return {
        'isValid': false,
        'error': 'Delil başlığı en az ${EvidenceLimits.minTitleLength} karakter olmalıdır'
      };
    }

    // Açıklama doğrulama
    if (!EvidenceLimits.isValidDescription(evidence.description)) {
      return {
        'isValid': false,
        'error': 'Delil açıklaması en az ${EvidenceLimits.minDescriptionLength} karakter olmalıdır'
      };
    }

    // Başlık benzersizlik kontrolü
    final existingEvidences = getEvidenceByDavaId(evidence.davaId);
    if (!EvidenceLimits.isTitleUnique(evidence.title, evidence.davaId, existingEvidences)) {
      return {
        'isValid': false,
        'error': 'Bu dava için aynı başlıkta başka bir delil bulunmaktadır'
      };
    }

    // Tip bazlı limit kontrolleri
    final counts = getEvidenceCountsByDavaId(evidence.davaId);
    switch (evidence.type) {
      case 'image':
        if (counts['image']! >= EvidenceLimits.maxImages) {
          return {
            'isValid': false,
            'error': 'Maksimum ${EvidenceLimits.maxImages} resim eklenebilir'
          };
        }
        break;
      case 'video':
        if (counts['video']! >= EvidenceLimits.maxVideos) {
          return {
            'isValid': false,
            'error': 'Maksimum ${EvidenceLimits.maxVideos} video eklenebilir'
          };
        }
        break;
      case 'text':
        if (counts['text']! >= EvidenceLimits.maxPdfs) {
          return {
            'isValid': false,
            'error': 'Maksimum ${EvidenceLimits.maxPdfs} PDF eklenebilir'
          };
        }
        break;
      case 'link':
        if (counts['link']! >= EvidenceLimits.maxLinks) {
          return {
            'isValid': false,
            'error': 'Maksimum ${EvidenceLimits.maxLinks} link eklenebilir'
          };
        }
        break;
    }

    // Dosya boyutu kontrolleri
    if (evidence.fileSize > 0) {
      switch (evidence.type) {
        case 'image':
          if (evidence.fileSize > EvidenceLimits.maxImageSize) {
            return {
              'isValid': false,
              'error': 'Resim dosyası ${EvidenceLimits.maxImageSize ~/ (1024 * 1024)}MB\'dan büyük olamaz'
            };
          }
          break;
        case 'video':
          if (evidence.fileSize > EvidenceLimits.maxVideoSize) {
            return {
              'isValid': false,
              'error': 'Video dosyası ${EvidenceLimits.maxVideoSize ~/ (1024 * 1024)}MB\'dan büyük olamaz'
            };
          }
          break;
        case 'text':
          if (evidence.fileSize > EvidenceLimits.maxPdfSize) {
            return {
              'isValid': false,
              'error': 'PDF dosyası ${EvidenceLimits.maxPdfSize ~/ (1024 * 1024)}MB\'dan büyük olamaz'
            };
          }
          break;
      }
    }

    return {'isValid': true};
  }

  // Dava ID'sine göre delilleri getir
  // Trim ve case-insensitive karşılaştırma yaparak eşleşmeyi garanti eder
  List<EvidenceModel> getEvidenceByDavaId(String davaId) {
    try {
      final normalizedDavaId = davaId.trim().toLowerCase();
      final allEvidences = _evidenceBox.values.toList();
      final filtered = allEvidences
          .where((evidence) => evidence.davaId.trim().toLowerCase() == normalizedDavaId)
          .toList();
      
      // Debug: Eğer delil bulunamadıysa log yaz
      if (filtered.isEmpty && allEvidences.isNotEmpty) {
        print('⚠️ DavaId için delil bulunamadı: $davaId (normalized: $normalizedDavaId)');
        print('🔍 Mevcut delil davaId\'leri: ${allEvidences.map((e) => e.davaId).toSet().take(5).join(", ")}');
      } else if (filtered.isNotEmpty) {
        print('✅ DavaId için ${filtered.length} delil bulundu: $davaId');
      }
      
      return filtered;
    } catch (e) {
      print('❌ Deliller getirilirken hata: $e');
      return [];
    }
  }

  // Delil tipine göre sayıları getir.
  // Hata yutulmaz; sayfa boş liste yerine yeniden deneme gösterebilsin.
  Map<String, int> getEvidenceCountsByDavaId(String davaId) {
    return loadEvidenceCounts(davaId);
  }

  /// Sayfa yüklemesi. Kutu okunamazsa fırlatır, sıfırla boş listeye düşmez.
  Map<String, int> loadEvidenceCounts(String davaId) {
    final normalizedDavaId = davaId.trim().toLowerCase();
    final filtered = _evidenceBox.values
        .where((evidence) => evidence.davaId.trim().toLowerCase() == normalizedDavaId)
        .toList();
    return _countsOf(filtered);
  }

  Map<String, int> _countsOf(List<EvidenceModel> evidences) {
    return {
      'image': evidences.where((e) => e.type == 'image').length,
      'video': evidences.where((e) => e.type == 'video').length,
      'text': evidences.where((e) => e.type == 'text').length,
      'link': evidences.where((e) => e.type == 'link').length,
    };
  }

  // Delil silme
  Future<void> deleteEvidence(String evidenceId) async {
    try {
      await _evidenceBox.delete(evidenceId);
      print('✅ Delil silindi: $evidenceId');
    } catch (e) {
      print('❌ Delil silinirken hata: $e');
      rethrow;
    }
  }

  /// Kutu okunamazsa fırlatır.
  List<EvidenceModel> loadAllEvidence() {
    return _evidenceBox.values.toList();
  }

  // Tüm delilleri getir
  List<EvidenceModel> getAllEvidence() {
    try {
      final allEvidence = _evidenceBox.values.toList();
      return allEvidence;
    } catch (e) {
      print('❌ Tüm deliller getirilirken hata: $e');
      return [];
    }
  }

  /// Kullanıcı oyunu yeni bir haritaya yazar. Yerinde değişiklik Hive'da kaybolabiliyor.
  /// Yalnızca bu delildeki bu kullanıcının anahtarı değişir.
  void _replaceUserVote(EvidenceModel evidence, String userEmail, String? vote) {
    final emailKey = userEmail.trim();
    final wanted = emailKey.toLowerCase();
    final next = <String, String>{};
    evidence.likedBy.forEach((key, value) {
      final rawKey = key?.toString();
      final rawValue = value?.toString();
      if (rawKey == null || rawValue == null || rawValue.isEmpty) return;
      if (wanted.isNotEmpty && rawKey.trim().toLowerCase() == wanted) return;
      next[rawKey] = rawValue;
    });
    if (vote != null && emailKey.isNotEmpty) {
      next[emailKey] = vote;
    }
    evidence.likedBy = next;
  }

  Future<void> _saveEvidence(EvidenceModel evidence) {
    return _evidenceBox.put(evidence.id, evidence);
  }

  Future<void> persistEvidence(EvidenceModel evidence) => _saveEvidence(evidence);

  void _changeVoteCount(EvidenceModel evidence, String vote, int delta) {
    if (vote == 'like') {
      evidence.likeCount = (evidence.likeCount + delta).clamp(0, 999999);
    } else if (vote == 'dislike') {
      evidence.dislikeCount = (evidence.dislikeCount + delta).clamp(0, 999999);
    } else if (vote == 'neutral') {
      evidence.neutralCount = (evidence.neutralCount + delta).clamp(0, 999999);
    }
  }

  /// Oy haritasını hemen günceller. Disk yazması ayrıca [persistEvidence] ile yapılır,
  /// böylece ekran eski kopyada kalmaz.
  EvidenceModel? mutateUserToggle(
    String evidenceId,
    String userEmail,
    String vote,
  ) {
    if (vote != 'like' && vote != 'dislike' && vote != 'neutral') {
      return null;
    }
    final evidence = _evidenceBox.get(evidenceId);
    if (evidence == null) return null;

    final currentVote = evidence.getUserVote(userEmail);
    if (currentVote == vote) {
      _changeVoteCount(evidence, vote, -1);
      _replaceUserVote(evidence, userEmail, null);
    } else {
      if (currentVote == 'like' ||
          currentVote == 'dislike' ||
          currentVote == 'neutral') {
        _changeVoteCount(evidence, currentVote!, -1);
      }
      _changeVoteCount(evidence, vote, 1);
      _replaceUserVote(evidence, userEmail, vote);
    }
    return evidence;
  }

  Future<void> _toggleAndSave(
    String evidenceId,
    String userEmail,
    String vote,
    String Function(EvidenceModel evidence) successLog,
  ) async {
    try {
      final evidence = mutateUserToggle(evidenceId, userEmail, vote);
      if (evidence == null) {
        print('❌ Delil bulunamadı: $evidenceId');
        return;
      }
      await _saveEvidence(evidence);
      print(successLog(evidence));
    } catch (e) {
      print('❌ Oy güncellenirken hata: $e');
      rethrow;
    }
  }

  // Delile like ekle/kaldır
  Future<void> toggleLike(String evidenceId, String userEmail) {
    return _toggleAndSave(
      evidenceId,
      userEmail,
      'like',
      (evidence) =>
          '✅ Like güncellendi - Delil: ${evidence.title}, Likes: ${evidence.likeCount}',
    );
  }

  // Delile dislike ekle/kaldır
  Future<void> toggleDislike(String evidenceId, String userEmail) {
    return _toggleAndSave(
      evidenceId,
      userEmail,
      'dislike',
      (evidence) =>
          '✅ Dislike güncellendi - Delil: ${evidence.title}, Dislikes: ${evidence.dislikeCount}',
    );
  }

  /// Nötr oy ekle/kaldır (toggle)
  Future<void> toggleNeutral(String evidenceId, String userEmail) {
    return _toggleAndSave(
      evidenceId,
      userEmail,
      'neutral',
      (evidence) =>
          '✅ Nötr oy güncellendi - Delil: ${evidence.title}, Nötr: ${evidence.neutralCount}',
    );
  }

  /// Kullanıcı oyunu doğrudan ayarla: `like` | `dislike` | `neutral`
  Future<void> setUserVote(
    String evidenceId,
    String userEmail,
    String vote,
  ) async {
    if (vote != 'like' && vote != 'dislike' && vote != 'neutral') {
      return;
    }
    try {
      final evidence = _evidenceBox.get(evidenceId);
      if (evidence == null) return;

      final currentVote = evidence.getUserVote(userEmail);
      if (currentVote == vote) return;

      if (currentVote == 'like') {
        evidence.likeCount = (evidence.likeCount - 1).clamp(0, 999999);
      } else if (currentVote == 'dislike') {
        evidence.dislikeCount = (evidence.dislikeCount - 1).clamp(0, 999999);
      } else if (currentVote == 'neutral') {
        evidence.neutralCount = (evidence.neutralCount - 1).clamp(0, 999999);
      }

      if (vote == 'like') {
        evidence.likeCount++;
      } else if (vote == 'dislike') {
        evidence.dislikeCount++;
      } else {
        evidence.neutralCount++;
      }
      _replaceUserVote(evidence, userEmail, vote);

      await _saveEvidence(evidence);
    } catch (e) {
      print('❌ Delil oyu ayarlanırken hata: $e');
      rethrow;
    }
  }

  /// Hüküm finalize olduktan sonra kullanıcının delil oyunu zorunlu yöne çeker.
  ///
  /// - `isPositive == true` ise tüm delillerde kullanıcı oyu "like" olur.
  /// - `isPositive == false` ise tüm delillerde kullanıcı oyu "dislike" olur.
  /// - Kullanıcının mevcut oyu hedef yöndeyse değiştirilmez.
  Future<void> applyForcedVoteForUser(
    String davaId,
    String userEmail, {
    required bool isPositive,
  }) async {
    try {
      final String trimmedDavaId = davaId.trim();
      final String trimmedUserEmail = userEmail.trim();
      if (trimmedDavaId.isEmpty || trimmedUserEmail.isEmpty) {
        return;
      }

      final String targetVote = isPositive ? 'like' : 'dislike';
      final evidences = getEvidenceByDavaId(trimmedDavaId);
      if (evidences.isEmpty) {
        return;
      }

      for (final evidence in evidences) {
        final currentVote = evidence.getUserVote(trimmedUserEmail);
        if (currentVote == targetVote) {
          continue;
        }

        if (currentVote == 'like') {
          evidence.likeCount = (evidence.likeCount - 1).clamp(0, 999999);
        } else if (currentVote == 'dislike') {
          evidence.dislikeCount = (evidence.dislikeCount - 1).clamp(0, 999999);
        } else if (currentVote == 'neutral') {
          evidence.neutralCount = (evidence.neutralCount - 1).clamp(0, 999999);
        }

        if (targetVote == 'like') {
          evidence.likeCount++;
        } else {
          evidence.dislikeCount++;
        }
        _replaceUserVote(evidence, trimmedUserEmail, targetVote);

        await _saveEvidence(evidence);
      }
    } catch (e) {
      print('❌ Zorunlu delil oyu uygulanırken hata: $e');
    }
  }

  /// Dava süresi dolduğunda oy vermeyen kullanıcıları varsayılan "beğen" olarak işaretle.
  ///
  /// - Sadece bu dava delilleri güncellenir.
  /// - Kullanıcının delilde mevcut bir oyu varsa (like, dislike veya neutral) dokunulmaz.
  Future<void> applyDefaultLikesForUsers(
    String davaId,
    List<String> userEmails,
  ) async {
    try {
      if (davaId.trim().isEmpty || userEmails.isEmpty) {
        return;
      }

      final normalizedEmails = userEmails
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      if (normalizedEmails.isEmpty) {
        return;
      }

      final evidences = getEvidenceByDavaId(davaId);
      if (evidences.isEmpty) {
        return;
      }

      for (final evidence in evidences) {
        bool changed = false;

        for (final email in normalizedEmails) {
          final currentVote = evidence.getUserVote(email);
          if (currentVote == null || currentVote.isEmpty) {
            evidence.likeCount++;
            _replaceUserVote(evidence, email, 'like');
            changed = true;
          }
        }

        if (changed) {
          await _saveEvidence(evidence);
        }
      }
    } catch (e) {
      print('❌ Varsayılan delil beğenileri uygulanırken hata: $e');
    }
  }

  // Delil güncelle
  Future<void> updateEvidence(EvidenceModel evidence) async {
    try {
      await _evidenceBox.put(evidence.id, evidence);
      print('✅ Delil güncellendi: ${evidence.title}');
    } catch (e) {
      print('❌ Delil güncellenirken hata: $e');
      rethrow;
    }
  }

  // Delil getir (ID ile)
  EvidenceModel? getEvidenceById(String evidenceId) {
    try {
      return _evidenceBox.get(evidenceId);
    } catch (e) {
      print('❌ Delil getirilirken hata: $e');
      return null;
    }
  }

  // Box'ı kapat
  Future<void> close() async {
    await _evidenceBox.close();
  }
}
