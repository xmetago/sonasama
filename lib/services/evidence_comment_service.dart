import 'package:hive/hive.dart';
import '../models/evidence_comment_model.dart';

/// Delil yorumları için servis sınıfı
/// Her delil için 8 farklı rolden yorum alabilir
/// Her rol için tek bir yorum yazılabilir
class EvidenceCommentService {
  static const String _boxName = 'evidence_comments_box';
  late Box<EvidenceCommentModel> _commentBox;

  // Singleton pattern
  static final EvidenceCommentService _instance = EvidenceCommentService._internal();
  factory EvidenceCommentService() => _instance;
  EvidenceCommentService._internal();

  // Hive box'ını başlat
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _commentBox = await Hive.openBox<EvidenceCommentModel>(_boxName);
    } else {
      _commentBox = Hive.box<EvidenceCommentModel>(_boxName);
    }
  }

  /// Yorum ekleme veya güncelleme
  /// Her rol için tek bir yorum yazılabilir
  Future<Map<String, dynamic>> addOrUpdateComment({
    required String evidenceId,
    required String davaId,
    required String userRole,
    required String userEmail,
    required String commentText,
    String criticism = 'neutral',
  }) async {
    try {
      await initialize();
      
      // Benzersiz ID oluştur
      final commentId = EvidenceCommentModel.generateCommentId(
        evidenceId,
        userRole,
        userEmail,
      );

      // Mevcut yorumu kontrol et
      final existingComment = _commentBox.get(commentId);
      
      final now = DateTime.now();
      
      EvidenceCommentModel comment;
      
      if (existingComment != null) {
        // Yorumu güncelle
        comment = existingComment.copyWith(
          commentText: commentText,
          criticism: criticism,
          updatedAt: now,
        );
        print('🔄 Yorum güncelleniyor: $commentId');
      } else {
        // Yeni yorum oluştur
        comment = EvidenceCommentModel(
          id: commentId,
          evidenceId: evidenceId,
          davaId: davaId,
          userRole: userRole,
          userEmail: userEmail,
          commentText: commentText,
          criticism: criticism,
          createdAt: now,
          updatedAt: now,
        );
        print('✅ Yeni yorum ekleniyor: $commentId');
      }

      // Veritabanına kaydet
      await _commentBox.put(commentId, comment);
      
      print('✅ Veritabanına kaydediliyor: ${comment.userRole} yorumu');
      print('✅ Kalıcı olarak saklanıyor');
      print('✅ Uygulama yeniden başlatıldığında korunuyor');
      
      return {
        'success': true,
        'comment': comment,
        'message': existingComment != null ? 'Yorum güncellendi' : 'Yorum eklendi',
      };
    } catch (e) {
      print('❌ Yorum eklenirken hata: $e');
      return {
        'success': false,
        'error': 'Yorum eklenirken hata oluştu: $e',
      };
    }
  }

  /// Delil ID'sine göre tüm yorumları getir
  List<EvidenceCommentModel> getCommentsByEvidenceId(String evidenceId) {
    try {
      return _commentBox.values
          .where((comment) => comment.evidenceId == evidenceId)
          .toList();
    } catch (e) {
      print('❌ Yorumlar getirilirken hata: $e');
      return [];
    }
  }

  /// Dava ID'sine göre tüm yorumları getir
  List<EvidenceCommentModel> getCommentsByDavaId(String davaId) {
    try {
      return _commentBox.values
          .where((comment) => comment.davaId == davaId)
          .toList();
    } catch (e) {
      print('❌ Yorumlar getirilirken hata: $e');
      return [];
    }
  }

  /// Belirli bir delil ve rol için yorum getir
  EvidenceCommentModel? getCommentByEvidenceAndRole(
    String evidenceId,
    String userRole,
    String userEmail,
  ) {
    try {
      final commentId = EvidenceCommentModel.generateCommentId(
        evidenceId,
        userRole,
        userEmail,
      );
      return _commentBox.get(commentId);
    } catch (e) {
      print('❌ Yorum getirilirken hata: $e');
      return null;
    }
  }

  /// Kullanıcının belirli bir delil için yorumu var mı?
  bool hasUserCommented(String evidenceId, String userRole, String userEmail) {
    try {
      final commentId = EvidenceCommentModel.generateCommentId(
        evidenceId,
        userRole,
        userEmail,
      );
      return _commentBox.containsKey(commentId);
    } catch (e) {
      print('❌ Yorum kontrolü yapılırken hata: $e');
      return false;
    }
  }

  /// Yorum silme
  Future<bool> deleteComment(String commentId) async {
    try {
      await _commentBox.delete(commentId);
      print('✅ Yorum silindi: $commentId');
      return true;
    } catch (e) {
      print('❌ Yorum silinirken hata: $e');
      return false;
    }
  }

  /// Delil için rol bazında yorum sayılarını getir
  Map<String, int> getCommentCountsByRole(String evidenceId) {
    try {
      final comments = getCommentsByEvidenceId(evidenceId);
      final Map<String, int> counts = {};
      
      for (var role in EvidenceCommentRole.allRoles) {
        counts[role.value] = comments
            .where((c) => c.userRole == role.value)
            .length;
      }
      
      return counts;
    } catch (e) {
      print('❌ Yorum sayıları getirilirken hata: $e');
      return {};
    }
  }

  /// Tüm yorumları getir
  List<EvidenceCommentModel> getAllComments() {
    try {
      return _commentBox.values.toList();
    } catch (e) {
      print('❌ Tüm yorumlar getirilirken hata: $e');
      return [];
    }
  }

  /// Box'ı kapat
  Future<void> close() async {
    await _commentBox.close();
  }
}

