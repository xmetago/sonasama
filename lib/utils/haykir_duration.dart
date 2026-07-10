/// Haykır kampanyasının toplam süresi ve kalan süre hesapları.
class HaykirDuration {
  HaykirDuration._();

  /// Haykır, yayınlandıktan sonra bu kadar gün aktif kalır.
  static const int totalDays = 19;

  static const Duration total = Duration(days: totalDays);

  static bool isExpired(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return false;
    try {
      final created = DateTime.parse(createdAt);
      return DateTime.now().difference(created) >= total;
    } catch (_) {
      return false;
    }
  }

  /// 0.0 (süre doldu) — 1.0 (yeni başladı)
  static double remainingProgress(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 1.0;
    try {
      final created = DateTime.parse(createdAt);
      final elapsed = DateTime.now().difference(created);
      if (elapsed >= total) return 0.0;
      return (1.0 - (elapsed.inMilliseconds / total.inMilliseconds))
          .clamp(0.0, 1.0);
    } catch (_) {
      return 1.0;
    }
  }

  static String formatRemaining(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return '$totalDays gün 0 saat';
    }
    try {
      final created = DateTime.parse(createdAt);
      final remaining = total - DateTime.now().difference(created);

      if (remaining.isNegative || remaining == Duration.zero) {
        return 'Süre doldu';
      }

      final days = remaining.inDays;
      final hours = remaining.inHours % 24;
      final minutes = remaining.inMinutes % 60;

      if (days > 0) {
        return '$days gün $hours saat';
      }
      if (hours > 0) {
        return '$hours saat $minutes dk';
      }
      return '$minutes dk';
    } catch (_) {
      return '$totalDays gün 0 saat';
    }
  }
}
