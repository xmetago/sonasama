import '../utils/comment_utils.dart';
import 'hive_database_service.dart';

/// Yorum bilgisi veri transfer nesnesi.
class TrendComment {
  /// Varsayılan kurucu.
  const TrendComment({
    required this.id,
    required this.author,
    required this.message,
    required this.timestamp,
    required this.isAnonymous,
  });

  /// Yorum kimliği.
  final String id;

  /// Gönderen kullanıcı adı.
  final String author;

  /// Yorum metni.
  final String message;

  /// Oluşturulma zamanı.
  final DateTime timestamp;

  /// Gizli tanık mı?
  final bool isAnonymous;

  /// Ham map'ten TrendComment oluşturur.
  factory TrendComment.fromMap(Map<String, dynamic> map) {
    return TrendComment(
      id: map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      author: (map['userName'] ?? map['author'] ?? 'Bilinmeyen').toString(),
      message: (map['yorum'] ?? map['message'] ?? '').toString(),
      timestamp:
          DateTime.tryParse(map['tarih']?.toString() ?? '') ?? DateTime.now(),
      isAnonymous: (map['isGizliTanik'] ?? false) as bool,
    );
  }
}

/// Trend kartlarının etkileşim durumunu temsil eder.
class TrendEngagementSnapshot {
  /// Varsayılan kurucu.
  const TrendEngagementSnapshot({
    required this.supportCount,
    required this.condemnCount,
    required this.commentCount,
    required this.userSupported,
    required this.userCondemned,
    required this.comments,
  });

  /// Toplam destek sayısı.
  final int supportCount;

  /// Toplam kınama sayısı.
  final int condemnCount;

  /// Toplam yorum sayısı.
  final int commentCount;

  /// Kullanıcı destekledi mi?
  final bool userSupported;

  /// Kullanıcı kınadı mı?
  final bool userCondemned;

  /// En güncel yorum listesi.
  final List<TrendComment> comments;
}

/// Trend kart etkileşim servis katmanı.
class TrendEngagementService {
  /// Varsayılan kurucu.
  const TrendEngagementService();

  /// Dava bazlı etkileşim verilerini yükler.
  Future<TrendEngagementSnapshot> load({
    required String caseId,
    String? userEmail,
  }) async {
    final stats = HiveDatabaseService.getDavaActionStats(caseId);
    final userAction = (userEmail == null || userEmail.isEmpty)
        ? <String, dynamic>{'like': false, 'dislike': false}
        : HiveDatabaseService.getUserDavaAction(caseId, userEmail);
    final rawComments = HiveDatabaseService.getAllDavaComments(caseId);

    final comments =
        rawComments.map((map) => TrendComment.fromMap(map)).toList();

    return TrendEngagementSnapshot(
      supportCount: stats['totalLikes'] as int? ?? 0,
      condemnCount: stats['totalDislikes'] as int? ?? 0,
      commentCount: stats['totalComments'] as int? ??
          CommentUtils.countAllComments(rawComments),
      userSupported: userAction['like'] as bool? ?? false,
      userCondemned: userAction['dislike'] as bool? ?? false,
      comments: comments,
    );
  }

  /// Destek ya da kınama aksiyonunu değiştirir.
  Future<TrendEngagementSnapshot> toggleReaction({
    required String caseId,
    required String userEmail,
    required bool isSupport,
  }) async {
    if (userEmail.isEmpty) {
      throw ArgumentError('userEmail boş olamaz');
    }
    await HiveDatabaseService.toggleDavaLike(caseId, userEmail, isSupport);
    return load(caseId: caseId, userEmail: userEmail);
  }

  /// Yeni yorum ekler.
  Future<TrendEngagementSnapshot> addComment({
    required String caseId,
    required String userEmail,
    required String message,
    bool isAnonymous = false,
  }) async {
    if (userEmail.isEmpty) {
      throw ArgumentError('userEmail boş olamaz');
    }
    if (message.trim().isEmpty) {
      throw ArgumentError('message boş olamaz');
    }
    final success = await HiveDatabaseService.addDavaComment(
      caseId,
      userEmail,
      yorumMetni: message.trim(),
      isGizliTanik: isAnonymous,
    );
    if (!success) {
      throw StateError('Yorum eklenemedi');
    }
    return load(caseId: caseId, userEmail: userEmail);
  }
}

