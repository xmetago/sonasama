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

  // Delil tipine göre sayıları getir
  Map<String, int> getEvidenceCountsByDavaId(String davaId) {
    try {
      final evidences = getEvidenceByDavaId(davaId);
      return {
        'image': evidences.where((e) => e.type == 'image').length,
        'video': evidences.where((e) => e.type == 'video').length,
        'text': evidences.where((e) => e.type == 'text').length,
        'link': evidences.where((e) => e.type == 'link').length,
      };
    } catch (e) {
      print('❌ Delil sayıları getirilirken hata: $e');
      return {'image': 0, 'video': 0, 'text': 0, 'link': 0};
    }
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

  // Delile like ekle/kaldır
  Future<void> toggleLike(String evidenceId, String userEmail) async {
    try {
      final evidence = _evidenceBox.get(evidenceId);
      if (evidence == null) {
        print('❌ Delil bulunamadı: $evidenceId');
        return;
      }

      final currentVote = evidence.getUserVote(userEmail);
      
      if (currentVote == 'like') {
        // Like'ı kaldır
        evidence.likedBy.remove(userEmail);
        evidence.likeCount = (evidence.likeCount - 1).clamp(0, 999999);
      } else {
        // Önce dislike varsa kaldır
        if (currentVote == 'dislike') {
          evidence.dislikeCount = (evidence.dislikeCount - 1).clamp(0, 999999);
        }
        // Like ekle
        evidence.likedBy[userEmail] = 'like';
        evidence.likeCount++;
      }

      await evidence.save();
      print('✅ Like güncellendi - Delil: ${evidence.title}, Likes: ${evidence.likeCount}');
    } catch (e) {
      print('❌ Like eklenirken hata: $e');
      rethrow;
    }
  }

  // Delile dislike ekle/kaldır
  Future<void> toggleDislike(String evidenceId, String userEmail) async {
    try {
      final evidence = _evidenceBox.get(evidenceId);
      if (evidence == null) {
        print('❌ Delil bulunamadı: $evidenceId');
        return;
      }

      final currentVote = evidence.getUserVote(userEmail);
      
      if (currentVote == 'dislike') {
        // Dislike'ı kaldır
        evidence.likedBy.remove(userEmail);
        evidence.dislikeCount = (evidence.dislikeCount - 1).clamp(0, 999999);
      } else {
        // Önce like varsa kaldır
        if (currentVote == 'like') {
          evidence.likeCount = (evidence.likeCount - 1).clamp(0, 999999);
        }
        // Dislike ekle
        evidence.likedBy[userEmail] = 'dislike';
        evidence.dislikeCount++;
      }

      await evidence.save();
      print('✅ Dislike güncellendi - Delil: ${evidence.title}, Dislikes: ${evidence.dislikeCount}');
    } catch (e) {
      print('❌ Dislike eklenirken hata: $e');
      rethrow;
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
