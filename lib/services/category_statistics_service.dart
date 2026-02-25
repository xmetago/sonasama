import '../models/category_model.dart';
import 'hive_database_service.dart';
import 'statistics_analytics_service.dart';

/// Kategorilere dair gelişmiş istatistikleri oluşturan servis.
class CategoryStatisticsService {
  /// Varsayılan kurucu.
  const CategoryStatisticsService();

  /// Davalar ve kayıtlı kategoriler üzerinden kategori bazlı özet üretir.
  CategoryStatisticsResult build({
    required List<CaseInsight> caseInsights,
  }) {
    final categories = HiveDatabaseService.getActiveCategories();
    if (categories.isEmpty) {
      return const CategoryStatisticsResult.empty();
    }

    final Map<String, _CategoryAccumulator> aggregates = {
      for (final category in categories)
        category.name: _CategoryAccumulator(
          category: category,
        ),
    };

    for (final insight in caseInsights) {
      final accumulator = aggregates.putIfAbsent(
        insight.category,
        () => _CategoryAccumulator(
          category: CategoryModel(
            id: insight.category,
            name: insight.category,
            subCategories: const [],
            isActive: true,
            totalDavalar: 0,
            createdAt: insight.createdAt,
            orderIndex: aggregates.length,
          ),
        ),
      );
      accumulator.caseCount++;
      accumulator.totalSupport += insight.supportCount;
      accumulator.totalOppose += insight.opposeCount;
      if ((insight.hashtag ?? '').isNotEmpty &&
          accumulator.sampleHashtags.length < 3) {
        accumulator.sampleHashtags.add(insight.hashtag!);
      }
    }

    final breakdowns = aggregates.values
        .map(
          (item) => CategoryBreakdown(
            categoryName: item.category.name,
            caseCount: item.caseCount,
            totalSupport: item.totalSupport,
            totalOppose: item.totalOppose,
            subCategoryCount: item.category.subCategories.length,
            sampleHashtags: List<String>.from(item.sampleHashtags),
          ),
        )
        .toList()
      ..sort((a, b) => b.caseCount.compareTo(a.caseCount));

    final coveredCategories =
        breakdowns.where((item) => item.caseCount > 0).length;
    final uncovered = breakdowns.where((item) => item.caseCount == 0).toList();

    return CategoryStatisticsResult(
      totalCategories: breakdowns.length,
      coveredCategories: coveredCategories,
      coverageRatio: coveredCategories / breakdowns.length,
      topCategories: breakdowns.take(6).toList(),
      uncoveredCategories: uncovered,
    );
  }
}

/// Kategori istatistiklerinin DTO'su.
class CategoryStatisticsResult {
  /// Boş sonuç.
  const CategoryStatisticsResult.empty()
      : totalCategories = 0,
        coveredCategories = 0,
        coverageRatio = 0,
        topCategories = const [],
        uncoveredCategories = const [];

  /// Varsayılan kurucu.
  const CategoryStatisticsResult({
    required this.totalCategories,
    required this.coveredCategories,
    required this.coverageRatio,
    required this.topCategories,
    required this.uncoveredCategories,
  });

  /// Toplam kategori sayısı.
  final int totalCategories;

  /// En az bir dava içeren kategori sayısı.
  final int coveredCategories;

  /// Kapsama oranı (0-1).
  final double coverageRatio;

  /// En çok dava barındıran ilk kategoriler.
  final List<CategoryBreakdown> topCategories;

  /// Henüz dava içermeyen kategoriler.
  final List<CategoryBreakdown> uncoveredCategories;

  /// Henüz kapsanmayan kategori var mı?
  bool get hasGaps => uncoveredCategories.isNotEmpty;
}

/// Kategori bazlı özet satırı.
class CategoryBreakdown {
  /// Varsayılan kurucu.
  const CategoryBreakdown({
    required this.categoryName,
    required this.caseCount,
    required this.totalSupport,
    required this.totalOppose,
    required this.subCategoryCount,
    required this.sampleHashtags,
  });

  /// Kategori adı.
  final String categoryName;

  /// Dava adedi.
  final int caseCount;

  /// Toplam destek sayısı.
  final int totalSupport;

  /// Toplam kınama sayısı.
  final int totalOppose;

  /// Alt kategori sayısı.
  final int subCategoryCount;

  /// Örnek hashtag listesi.
  final List<String> sampleHashtags;

  /// Destek/kınama farkını verir.
  int get netScore => totalSupport - totalOppose;
}

class _CategoryAccumulator {
  _CategoryAccumulator({required this.category});

  final CategoryModel category;
  int caseCount = 0;
  int totalSupport = 0;
  int totalOppose = 0;
  final List<String> sampleHashtags = <String>[];
}

