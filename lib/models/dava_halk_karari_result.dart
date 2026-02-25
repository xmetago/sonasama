/// Dava için halkın verdiği desteği/kınamayı özetleyen veri transfer modeli.
class DavaHalkKarariResult {
  final String davaId;
  final int totalSupport;
  final int totalCondemn;
  final bool isWindowExpired;
  final bool canShowVerdict;
  final bool? isSuccessful;
  final DateTime? acceptedAt;
  final DateTime? hukumTarihi;
  final String? hukumAciklamasi;
  final int daysElapsed;
  final int daysRemaining;
  final int requiredDays;
  final double progress;
  final bool hasPersistedHukum;

  const DavaHalkKarariResult({
    required this.davaId,
    required this.totalSupport,
    required this.totalCondemn,
    required this.isWindowExpired,
    required this.canShowVerdict,
    required this.isSuccessful,
    required this.acceptedAt,
    required this.hukumTarihi,
    required this.hukumAciklamasi,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.requiredDays,
    required this.progress,
    required this.hasPersistedHukum,
  });

  /// Varsayılan boş durum.
  factory DavaHalkKarariResult.empty(String davaId, {int requiredDays = 76}) {
    return DavaHalkKarariResult(
      davaId: davaId,
      totalSupport: 0,
      totalCondemn: 0,
      isWindowExpired: false,
      canShowVerdict: false,
      isSuccessful: null,
      acceptedAt: null,
      hukumTarihi: null,
      hukumAciklamasi: null,
      daysElapsed: 0,
      daysRemaining: requiredDays,
      requiredDays: requiredDays,
      progress: 0,
      hasPersistedHukum: false,
    );
  }

  /// Halk kararı gösterilebilir durumda mı?
  bool get hasFinalVerdict => canShowVerdict && isSuccessful != null;

  /// Toplam destekteki fark.
  int get supportDelta => totalSupport - totalCondemn;

  /// Destek/kınama yüzdesi (0-1 arası).
  double get supportRatio {
    final total = totalSupport + totalCondemn;
    if (total == 0) {
      return 0;
    }
    return totalSupport / total;
  }

  DavaHalkKarariResult copyWith({
    String? davaId,
    int? totalSupport,
    int? totalCondemn,
    bool? isWindowExpired,
    bool? canShowVerdict,
    bool? hasPersistedHukum,
    bool? isSuccessful,
    DateTime? acceptedAt,
    DateTime? hukumTarihi,
    String? hukumAciklamasi,
    int? daysElapsed,
    int? daysRemaining,
    int? requiredDays,
    double? progress,
  }) {
    return DavaHalkKarariResult(
      davaId: davaId ?? this.davaId,
      totalSupport: totalSupport ?? this.totalSupport,
      totalCondemn: totalCondemn ?? this.totalCondemn,
      isWindowExpired: isWindowExpired ?? this.isWindowExpired,
      canShowVerdict: canShowVerdict ?? this.canShowVerdict,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      hukumTarihi: hukumTarihi ?? this.hukumTarihi,
      hukumAciklamasi: hukumAciklamasi ?? this.hukumAciklamasi,
      daysElapsed: daysElapsed ?? this.daysElapsed,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      requiredDays: requiredDays ?? this.requiredDays,
      progress: progress ?? this.progress,
      hasPersistedHukum: hasPersistedHukum ?? this.hasPersistedHukum,
    );
  }
}

