import 'statistics_analytics_service.dart';

/// Trend davalar ve haykırışlar için toparlanmış veri nesnesi.
class TrendingInsights {
  /// Varsayılan kurucu.
  const TrendingInsights({
    required this.trendDavalar,
    required this.trendHaykirislar,
    required this.generatedAt,
  });

  /// Destek sayısına göre sıralı trend davalar listesi.
  final List<CaseInsight> trendDavalar;

  /// Destek sayısına göre sıralı trend haykırışlar listesi.
  final List<CaseInsight> trendHaykirislar;

  /// Verinin üretildiği an.
  final DateTime generatedAt;

  /// En az bir liste dolu mu?
  bool get hasAnyData =>
      trendDavalar.isNotEmpty || trendHaykirislar.isNotEmpty;
}

/// Trend verilerini oluşturan servis.
class TrendingInsightsService {
  /// Varsayılan kurucu.
  const TrendingInsightsService(
      {StatisticsAnalyticsService? analyticsService})
      : _analyticsService =
            analyticsService ?? const StatisticsAnalyticsService();

  final StatisticsAnalyticsService _analyticsService;

  /// Hive kaynaklı istatistikleri okuyup trend listeleri üretir.
  Future<TrendingInsights> load({String? userEmail}) async {
    final analytics = await _analyticsService.load(userEmail: userEmail);

    /// Destek ve yorum sayılarına göre listeyi sıralar.
    List<CaseInsight> sortBySupport(List<CaseInsight> items) {
      final copy = [...items];
      copy.sort((a, b) {
        final support = b.supportCount.compareTo(a.supportCount);
        if (support != 0) return support;
        return b.commentCount.compareTo(a.commentCount);
      });
      return copy;
    }

    final List<CaseInsight> davalar = sortBySupport(
      analytics.mostSupported
          .where(
            (caseInsight) =>
                caseInsight.source == CaseSource.opened ||
                caseInsight.source == CaseSource.accepted,
          )
          .toList(),
    );

    final haykirCandidates = sortBySupport(
      analytics.mostSupported
          .where((caseInsight) => caseInsight.source == CaseSource.saved)
          .toList(),
    );

    final fallbackHaykirList = haykirCandidates.isNotEmpty
        ? haykirCandidates
        : sortBySupport(analytics.alphabetical);

    return TrendingInsights(
      trendDavalar: davalar,
      trendHaykirislar: fallbackHaykirList,
      generatedAt: DateTime.now(),
    );
  }
}

