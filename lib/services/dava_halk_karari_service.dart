import '../models/dava_halk_karari_result.dart';
import 'dava_hukum_service.dart';
import 'hive_database_service.dart';

/// Davanın halk desteği penceresine (hüküm süresi) dair yardımcı servis.
class DavaHalkKarariService {
  /// Halk kararını hesaplar ve varsa kalıcı veriyi döner.
  static Future<DavaHalkKarariResult> evaluate({
    required String davaId,
    DateTime? acceptedAt,
    int requiredDays = DavaHukumService.hukumSuresiGun,
  }) async {
    if (davaId.isEmpty) {
      return DavaHalkKarariResult.empty(davaId, requiredDays: requiredDays);
    }

    final DateTime? resolvedAcceptedAt =
        await _resolveAcceptedAt(davaId, acceptedAt);
    final Map<String, dynamic> stats =
        HiveDatabaseService.getDavaActionStats(davaId);

    final int totalLikes = stats['totalLikes'] is int
        ? stats['totalLikes'] as int
        : int.tryParse('${stats['totalLikes']}') ?? 0;
    final int totalDislikes = stats['totalDislikes'] is int
        ? stats['totalDislikes'] as int
        : int.tryParse('${stats['totalDislikes']}') ?? 0;

    final bool isWindowExpired =
        DavaHukumService.isHukumSuresiDoldu(resolvedAcceptedAt);

    Map<String, dynamic>? hukumVerisi =
        DavaHukumService.getDavaHukumVerisi(davaId);
    if (hukumVerisi == null && isWindowExpired) {
      hukumVerisi = await DavaHukumService.calculateAndSaveHukum(davaId);
    }

    final Map<String, dynamic>? persistedHukum = hukumVerisi;
    final bool hasPersistedHukum = persistedHukum != null;
    final bool showVerdict = isWindowExpired || hasPersistedHukum;

    bool? isSuccessful;
    if (persistedHukum != null) {
      isSuccessful = (persistedHukum['hukumSonucu'] == 'basarili');
    } else if (isWindowExpired) {
      isSuccessful = totalLikes >= totalDislikes;
    } else {
      isSuccessful = null;
    }

    final int daysElapsed = _calculateDaysElapsed(resolvedAcceptedAt);
    final int daysRemaining =
        _calculateDaysRemaining(resolvedAcceptedAt, requiredDays);
    final double progress =
        _calculateProgress(daysElapsed: daysElapsed, requiredDays: requiredDays);

    return DavaHalkKarariResult(
      davaId: davaId,
      totalSupport: totalLikes,
      totalCondemn: totalDislikes,
      isWindowExpired: isWindowExpired,
      canShowVerdict: showVerdict,
      isSuccessful: isSuccessful,
      acceptedAt: resolvedAcceptedAt,
      hukumTarihi: _parseDateTime(hukumVerisi?['hukumTarihi']),
      hukumAciklamasi: hukumVerisi?['hukumAciklamasi'] as String?,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      requiredDays: requiredDays,
      progress: progress,
      hasPersistedHukum: hasPersistedHukum,
    );
  }

  static Future<DateTime?> _resolveAcceptedAt(
    String davaId,
    DateTime? provided,
  ) async {
    if (provided != null) {
      return provided;
    }

    final Map<String, dynamic>? opened =
        HiveDatabaseService.getOpenedDavaById(davaId);
    final String? openedAcceptedAt =
        opened?['acceptedAt']?.toString() ?? opened?['openedAt']?.toString();
    if (openedAcceptedAt != null && openedAcceptedAt.isNotEmpty) {
      return DateTime.tryParse(openedAcceptedAt);
    }

    final Map<String, dynamic>? accepted =
        await HiveDatabaseService.getAcceptedDavaById(davaId);
    final String? acceptedAtStr = accepted?['acceptedAt']?.toString();
    if (acceptedAtStr != null && acceptedAtStr.isNotEmpty) {
      return DateTime.tryParse(acceptedAtStr);
    }

    return null;
  }

  static int _calculateDaysElapsed(DateTime? acceptedAt) {
    if (acceptedAt == null) {
      return 0;
    }
    final int raw = DateTime.now().difference(acceptedAt).inDays;
    return raw < 0 ? 0 : raw;
  }

  static int _calculateDaysRemaining(DateTime? acceptedAt, int requiredDays) {
    if (acceptedAt == null) {
      return requiredDays;
    }
    final int remaining = requiredDays - _calculateDaysElapsed(acceptedAt);
    return remaining > 0 ? remaining : 0;
  }

  static double _calculateProgress({
    required int daysElapsed,
    required int requiredDays,
  }) {
    if (requiredDays == 0) {
      return 1;
    }
    final double ratio = daysElapsed / requiredDays;
    if (ratio < 0) {
      return 0;
    }
    return ratio > 1 ? 1 : ratio;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    final String normalized = value.toString();
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized);
  }
}

