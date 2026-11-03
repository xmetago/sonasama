/// Yakınlık kategorilerinin 19 tabanlı limitleri ve etiketleri.
class ProximityCategoryRules {
  ProximityCategoryRules._();

  static const int cooldownDays = 19;
  static const Duration changeCooldown = Duration(days: cooldownDays);

  static const String grup19 = 'Grup-19';
  static const String arkadas = 'Arkadaş';
  static const String takipci = 'Takipçi';

  static const List<String> displayCategories = [grup19, arkadas, takipci];

  static const int grup19Limit = 19;
  static const int arkadasLimit = 114; // 19 × 6
  static const int takipciLimit = -1; // sınırsız

  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.toLowerCase();
    if (lower.contains('grup')) return grup19;
    if (lower.contains('ark')) return arkadas;
    if (lower.contains('takip')) return takipci;
    if (lower.contains('herkes')) return takipci;
    return takipci;
  }

  static int limitFor(String category) {
    switch (normalize(category)) {
      case grup19:
        return grup19Limit;
      case arkadas:
        return arkadasLimit;
      case takipci:
        return takipciLimit;
      default:
        return 0;
    }
  }

  static bool isUnlimited(String category) => limitFor(category) < 0;

  static DateTime lastChangeAt({
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    return updatedAt ?? createdAt;
  }

  static Duration? remainingCooldown({
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? now,
  }) {
    final last = lastChangeAt(createdAt: createdAt, updatedAt: updatedAt);
    final elapsed = (now ?? DateTime.now()).difference(last);
    if (elapsed >= changeCooldown) return null;
    return changeCooldown - elapsed;
  }

  static int remainingDays(Duration remaining) {
    final days = remaining.inDays;
    if (days <= 0 && remaining.inSeconds > 0) return 1;
    return days;
  }
}

/// Yakınlık kategorisi atama sonucu.
class ProximityAssignResult {
  final bool success;
  final String message;
  final int? remainingDays;

  const ProximityAssignResult({
    required this.success,
    required this.message,
    this.remainingDays,
  });
}
