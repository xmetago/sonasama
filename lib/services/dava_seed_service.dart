import 'dava_timer_service.dart';
import 'hive_database_service.dart';

/// Geliştirme ve demo amaçlı veri tohumlama yardımcıları.
class DavaSeedService {
  /// Kabul edilen ve süre aşımına uğramış örnek bir dava oluşturur.
  ///
  /// Dönen veri:
  /// - `davaId`
  /// - `davaAdi`
  /// - `acceptedAt`
  static Future<Map<String, dynamic>> seedExpiredAcceptedDava({
    required String userEmail,
    required String judgeName,
    required String mevki,
    String? davaId,
    String? davaAdi,
    String davaci = 'Nasrullah Keskin',
    String davali = 'Örnek Davalı',
    String kategori = 'Genel',
    DateTime? openedAt,
    DateTime? acceptedAt,
  }) async {
    final now = DateTime.now();
    final resolvedDavaId =
        davaId ?? 'dava_expired_${now.millisecondsSinceEpoch}';
    final resolvedDavaAdi =
        (davaAdi ?? 'Vicdani Problemler Davası').trim().isEmpty
            ? 'Vicdani Problemler Davası'
            : (davaAdi ?? 'Vicdani Problemler Davası').trim();

    final resolvedAcceptedAt = acceptedAt ??
        now.subtract(
          DavaTimerService.acceptedHukumWindow + const Duration(hours: 4),
        );
    final resolvedOpenedAt = openedAt ??
        resolvedAcceptedAt.subtract(const Duration(hours: 24));

    final openedDavaRecord = {
      'id': resolvedDavaId,
      'davaAdi': resolvedDavaAdi,
      'adi': resolvedDavaAdi,
      'davaci': davaci,
      'davali': davali,
      'davaKonusu': resolvedDavaAdi,
      'kategori': kategori,
      'davaKategori': kategori,
      'openedAt': resolvedOpenedAt.toIso8601String(),
      'createdAt': resolvedOpenedAt.toIso8601String(),
    };

    HiveDatabaseService.saveOpenedDava(openedDavaRecord);

    final acceptedDavaRecord = {
      'id': 'accepted_${resolvedDavaId}_${now.millisecondsSinceEpoch}',
      'davaId': resolvedDavaId,
      'adi': resolvedDavaAdi,
      'davaAdi': resolvedDavaAdi,
      'davaKonusu': resolvedDavaAdi,
      'davaci': davaci,
      'davali': davali,
      'userEmail': userEmail,
      'userRole': mevki,
      'mevkii': mevki,
      'kalanSure': resolvedAcceptedAt
          .add(DavaTimerService.acceptedHukumWindow)
          .toIso8601String(),
      'profilResmi': 'lib/icons/03_davala_ana_icon.png',
      'status': 'accepted',
      'acceptedAt': resolvedAcceptedAt.toIso8601String(),
      'createdAt': resolvedOpenedAt.toIso8601String(),
      'isActive': true,
    };

    await HiveDatabaseService.saveAcceptedDava(acceptedDavaRecord);

    await HiveDatabaseService.markDavaParticipantStatus(
      davaId: resolvedDavaId,
      userEmail: userEmail,
      status: 'accepted',
      statusAt: resolvedAcceptedAt,
      extra: {
        'displayName': judgeName,
        'mevkii': mevki,
        'userRole': mevki,
        'acceptedAt': resolvedAcceptedAt.toIso8601String(),
      },
      reason: 'seed_expired_demo',
    );

    return {
      'davaId': resolvedDavaId,
      'davaAdi': resolvedDavaAdi,
      'acceptedAt': resolvedAcceptedAt,
    };
  }
}

