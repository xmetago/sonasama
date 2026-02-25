import 'dart:async';

import 'package:flutter/foundation.dart';

import 'hive_database_service.dart';

/// Dava istatistiklerini oluşturan servis.
class StatisticsAnalyticsService {
  /// Varsayılan kurucu.
  const StatisticsAnalyticsService();

  /// Hive verilerini okuyup özet ve liste bazlı içgörüler üretir.
  Future<StatisticsAnalyticsResult> load({String? userEmail}) async {
    final opened = HiveDatabaseService.getOpenedDavalar();
    final saved = HiveDatabaseService.getSavedDavalar();
    final accepted = userEmail == null || userEmail.isEmpty
        ? <Map<String, dynamic>>[]
        : await HiveDatabaseService.getAcceptedDavalar(userEmail);

    final List<CaseInsight> insights = [
      ...opened.map((raw) => _mapToInsight(raw, source: CaseSource.opened)),
      ...saved.map((raw) => _mapToInsight(raw, source: CaseSource.saved)),
      ...accepted.map(
        (raw) => _mapToInsight(
          raw,
          source: CaseSource.accepted,
          defaultOwnerEmail: userEmail,
        ),
      ),
    ].whereType<CaseInsight>().toList();

    if (insights.isEmpty) {
      return StatisticsAnalyticsResult.empty();
    }

    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final todaysOpened =
        insights.where((c) => isSameDay(c.openedAt, now)).toList();
    final todaysFinished = insights
        .where((c) => c.resultAt != null && isSameDay(c.resultAt!, now))
        .toList();

    List<CaseInsight> sortBySupportDesc(List<CaseInsight> list) {
      final copy = [...list];
      copy.sort((a, b) {
        final support = b.supportCount.compareTo(a.supportCount);
        if (support != 0) return support;
        return b.commentCount.compareTo(a.commentCount);
      });
      return copy;
    }

    List<CaseInsight> sortByCondemnDesc(List<CaseInsight> list) {
      final copy = [...list];
      copy.sort((a, b) {
        final oppose = b.opposeCount.compareTo(a.opposeCount);
        if (oppose != 0) return oppose;
        return b.supportCount.compareTo(a.supportCount);
      });
      return copy;
    }

    final alphabetical = [...insights]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final summary = StatisticsSummary(
      totalCases: insights.length,
      categoryCount: insights.map((c) => c.category).toSet().length,
      todaysOpened: todaysOpened.length,
      todaysFinished: todaysFinished.length,
      supportRecord:
          insights.fold<int>(0, (max, c) => c.supportCount > max ? c.supportCount : max),
      condemnRecord:
          insights.fold<int>(0, (max, c) => c.opposeCount > max ? c.opposeCount : max),
    );

    return StatisticsAnalyticsResult(
      summary: summary,
      mostSupported: sortBySupportDesc(insights),
      mostCondemned: sortByCondemnDesc(insights),
      todaysOpened: sortBySupportDesc(todaysOpened),
      todaysFinished: sortByCondemnDesc(todaysFinished),
      alphabetical: alphabetical,
    );
  }

  CaseInsight? _mapToInsight(
    Map<String, dynamic> raw, {
    required CaseSource source,
    String? defaultOwnerEmail,
  }) {
    final idCandidate =
        (raw['id'] ?? raw['davaId'] ?? raw['uniqueId'])?.toString() ?? '';
    if (idCandidate.isEmpty) {
      return null;
    }

    final stats = HiveDatabaseService.getDavaActionStats(idCandidate);
    final openedAt =
        _parseDate(raw['openedAt']) ?? _parseDate(raw['createdAt']) ?? DateTime.now();
    final resultAt = _parseDate(
      raw['acceptedAt'] ??
          raw['completedAt'] ??
          raw['resultAt'] ??
          raw['updatedAt'],
    );

    final title =
        (raw['davaAdi'] ?? raw['adi'] ?? raw['title'] ?? 'İsimsiz Dava').toString();
    final hashtagValue = _buildTitleHashtag(title);

    return CaseInsight(
      id: idCandidate,
      title: title,
      category: (raw['kategori'] ?? raw['davaKategori'] ?? 'Genel').toString(),
      subCategory: raw['altKategori']?.toString() ?? raw['subKategori']?.toString(),
      hashtag: hashtagValue,
      supportCount: _asInt(stats['totalLikes']),
      opposeCount: _asInt(stats['totalDislikes']),
      commentCount: _asInt(stats['totalComments']),
      openedAt: openedAt,
      resultAt: resultAt,
      createdAt: _parseDate(raw['createdAt']) ?? openedAt,
      ownerEmail:
          (raw['userEmail'] ?? raw['authorEmail'] ?? defaultOwnerEmail ?? '')
              .toString(),
      source: source,
    );
  }

  /// Dava başlığının ilk 19 kelimesinden otomatik hashtag üretir.
  String _buildTitleHashtag(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return '#Dava';
    }
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(19)
        .toList();
    if (words.isEmpty) {
      return '#Dava';
    }
    final collapsed = words.join();
    return '#$collapsed';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final stringValue = value.toString();
    if (stringValue.isEmpty) return null;
    try {
      return DateTime.parse(stringValue);
    } catch (_) {
      return null;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

/// Verinin geldiği kaynak.
enum CaseSource { opened, saved, accepted }

/// Analiz sonucunun veri transfer nesnesi.
class StatisticsAnalyticsResult {
  /// Boş sonuç kurucu.
  StatisticsAnalyticsResult.empty()
      : summary = const StatisticsSummary.zero(),
        mostSupported = const [],
        mostCondemned = const [],
        todaysOpened = const [],
        todaysFinished = const [],
        alphabetical = const [];

  /// Varsayılan kurucu.
  const StatisticsAnalyticsResult({
    required this.summary,
    required this.mostSupported,
    required this.mostCondemned,
    required this.todaysOpened,
    required this.todaysFinished,
    required this.alphabetical,
  });

  /// Özet metrikler.
  final StatisticsSummary summary;

  /// En çok destek alan davalar.
  final List<CaseInsight> mostSupported;

  /// En çok kınanan davalar.
  final List<CaseInsight> mostCondemned;

  /// Bugün açılan davalar.
  final List<CaseInsight> todaysOpened;

  /// Bugün sonuçlanan davalar.
  final List<CaseInsight> todaysFinished;

  /// Alfabetik liste.
  final List<CaseInsight> alphabetical;
}

/// Kartlarda gösterilen 1 satırlık özetler.
@immutable
class StatisticsSummary {
  /// Sıfır veri için yardımcı kurucu.
  const StatisticsSummary.zero()
      : totalCases = 0,
        categoryCount = 0,
        todaysOpened = 0,
        todaysFinished = 0,
        supportRecord = 0,
        condemnRecord = 0;

  /// Varsayılan kurucu.
  const StatisticsSummary({
    required this.totalCases,
    required this.categoryCount,
    required this.todaysOpened,
    required this.todaysFinished,
    required this.supportRecord,
    required this.condemnRecord,
  });

  /// Toplam dava adedi.
  final int totalCases;

  /// Kategori çeşidi.
  final int categoryCount;

  /// Bugün açılan dava sayısı.
  final int todaysOpened;

  /// Bugün sonuçlanan dava sayısı.
  final int todaysFinished;

  /// En yüksek destek sayısı.
  final int supportRecord;

  /// En yüksek kınama sayısı.
  final int condemnRecord;
}

/// Liste elemanı.
@immutable
class CaseInsight {
  /// Varsayılan kurucu.
  const CaseInsight({
    required this.id,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.hashtag,
    required this.supportCount,
    required this.opposeCount,
    required this.commentCount,
    required this.openedAt,
    required this.resultAt,
    required this.createdAt,
    required this.ownerEmail,
    required this.source,
  });

  /// Kayıt ID'si.
  final String id;

  /// Başlık.
  final String title;

  /// Kategori.
  final String category;

  /// Alt kategori.
  final String? subCategory;

  /// Hashtag.
  final String? hashtag;

  /// Destek sayısı.
  final int supportCount;

  /// Kınama sayısı.
  final int opposeCount;

  /// Yorum sayısı.
  final int commentCount;

  /// Açılış zamanı.
  final DateTime openedAt;

  /// Tahmini sonuç zamanı.
  final DateTime? resultAt;

  /// Oluşturulma zamanı.
  final DateTime createdAt;

  /// Davanın sahibi.
  final String ownerEmail;

  /// Veri kaynağı.
  final CaseSource source;

  /// Sonuç saatini dakika cinsinden verir.
  int? get finishMinuteOfDay {
    if (resultAt == null) return null;
    return resultAt!.hour * 60 + resultAt!.minute;
  }

  /// Basit arama eşleşmesi.
  bool matchesQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    return [
      title,
      category,
      subCategory ?? '',
      hashtag ?? '',
    ].any((value) => value.toLowerCase().contains(trimmed));
  }
}

/// Hızlı filtre enum'u.
enum StatisticsQuickFilter {
  /// En çok desteklenen.
  mostSupported,

  /// En çok kınanan.
  mostCondemned,

  /// Bugün açılanlar.
  todaysOpened,

  /// Bugün sonuçlananlar.
  todaysFinished,

  /// Alfabetik sıra.
  alphabetical,
}

// ========== HAYKIR İSTATİSTİKLERİ ==========

/// HAYKIR istatistiklerini oluşturan servis.
class HaykirStatisticsAnalyticsService {
  /// Varsayılan kurucu.
  const HaykirStatisticsAnalyticsService();

  /// Hive verilerini okuyup özet ve liste bazlı içgörüler üretir.
  Future<HaykirStatisticsAnalyticsResult> load({String? userEmail}) async {
    final allHaykirislar = HiveDatabaseService.getAllActiveHaykirislar();

    final List<HaykirInsight> insights = allHaykirislar
        .map((raw) => _mapToHaykirInsight(raw))
        .whereType<HaykirInsight>()
        .toList();

    if (insights.isEmpty) {
      return HaykirStatisticsAnalyticsResult.empty();
    }

    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final todaysOpened =
        insights.where((h) => isSameDay(h.createdAt, now)).toList();

    List<HaykirInsight> sortByLikeDesc(List<HaykirInsight> list) {
      final copy = [...list];
      copy.sort((a, b) {
        final like = b.likeCount.compareTo(a.likeCount);
        if (like != 0) return like;
        return b.commentCount.compareTo(a.commentCount);
      });
      return copy;
    }

    List<HaykirInsight> sortByKinaDesc(List<HaykirInsight> list) {
      final copy = [...list];
      copy.sort((a, b) {
        final kina = b.kinaCount.compareTo(a.kinaCount);
        if (kina != 0) return kina;
        return b.likeCount.compareTo(a.likeCount);
      });
      return copy;
    }

    final alphabetical = [...insights]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final summary = HaykirStatisticsSummary(
      totalHaykirislar: insights.length,
      todaysOpened: todaysOpened.length,
      likeRecord: insights.fold<int>(
          0, (max, h) => h.likeCount > max ? h.likeCount : max),
      kinaRecord: insights.fold<int>(
          0, (max, h) => h.kinaCount > max ? h.kinaCount : max),
    );

    return HaykirStatisticsAnalyticsResult(
      summary: summary,
      mostLiked: sortByLikeDesc(insights),
      mostKina: sortByKinaDesc(insights),
      todaysOpened: sortByLikeDesc(todaysOpened),
      alphabetical: alphabetical,
    );
  }

  HaykirInsight? _mapToHaykirInsight(Map<String, dynamic> raw) {
    final idCandidate = (raw['id'] ?? raw['haykirId'])?.toString() ?? '';
    if (idCandidate.isEmpty) {
      return null;
    }

    final stats = HiveDatabaseService.getHaykirInteractionStats(idCandidate);
    final createdAt = _parseDate(raw['createdAt']) ?? DateTime.now();

    final title = (raw['adi'] ?? raw['title'] ?? 'İsimsiz Haykırış').toString();
    final slogan = raw['slogan']?.toString() ?? '';
    final direme = raw['direme']?.toString() ?? 'Genel';
    final hashtagValue = _buildHaykirHashtag(title, slogan);

    return HaykirInsight(
      id: idCandidate,
      title: title,
      slogan: slogan,
      direme: direme,
      hashtag: hashtagValue,
      likeCount: _asInt(stats['likeCount']),
      kinaCount: _asInt(stats['kinaCount']),
      commentCount: _asInt(stats['commentCount']),
      retweetCount: _asInt(stats['retweetCount']),
      shareCount: _asInt(stats['shareCount']),
      createdAt: createdAt,
      ownerEmail: (raw['userEmail'] ?? '').toString(),
    );
  }

  /// HAYKIR başlığı ve sloganından otomatik hashtag üretir.
  String _buildHaykirHashtag(String title, String slogan) {
    final titleTrimmed = title.trim();
    final sloganTrimmed = slogan.trim();
    
    if (titleTrimmed.isEmpty && sloganTrimmed.isEmpty) {
      return '#Haykir';
    }
    
    final combined = '$titleTrimmed $sloganTrimmed';
    final words = combined
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(19)
        .toList();
    
    if (words.isEmpty) {
      return '#Haykir';
    }
    
    final collapsed = words.join();
    return '#$collapsed';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final stringValue = value.toString();
    if (stringValue.isEmpty) return null;
    try {
      return DateTime.parse(stringValue);
    } catch (_) {
      return null;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

/// HAYKIR analiz sonucunun veri transfer nesnesi.
class HaykirStatisticsAnalyticsResult {
  /// Boş sonuç kurucu.
  HaykirStatisticsAnalyticsResult.empty()
      : summary = const HaykirStatisticsSummary.zero(),
        mostLiked = const [],
        mostKina = const [],
        todaysOpened = const [],
        alphabetical = const [];

  /// Varsayılan kurucu.
  const HaykirStatisticsAnalyticsResult({
    required this.summary,
    required this.mostLiked,
    required this.mostKina,
    required this.todaysOpened,
    required this.alphabetical,
  });

  /// Özet metrikler.
  final HaykirStatisticsSummary summary;

  /// En çok beğenilen haykırışlar.
  final List<HaykirInsight> mostLiked;

  /// En çok kına alan haykırışlar.
  final List<HaykirInsight> mostKina;

  /// Bugün açılan haykırışlar.
  final List<HaykirInsight> todaysOpened;

  /// Alfabetik liste.
  final List<HaykirInsight> alphabetical;
}

/// HAYKIR kartlarda gösterilen 1 satırlık özetler.
@immutable
class HaykirStatisticsSummary {
  /// Sıfır veri için yardımcı kurucu.
  const HaykirStatisticsSummary.zero()
      : totalHaykirislar = 0,
        todaysOpened = 0,
        likeRecord = 0,
        kinaRecord = 0;

  /// Varsayılan kurucu.
  const HaykirStatisticsSummary({
    required this.totalHaykirislar,
    required this.todaysOpened,
    required this.likeRecord,
    required this.kinaRecord,
  });

  /// Toplam haykırış adedi.
  final int totalHaykirislar;

  /// Bugün açılan haykırış sayısı.
  final int todaysOpened;

  /// En yüksek beğeni sayısı.
  final int likeRecord;

  /// En yüksek kına sayısı.
  final int kinaRecord;
}

/// HAYKIR liste elemanı.
@immutable
class HaykirInsight {
  /// Varsayılan kurucu.
  const HaykirInsight({
    required this.id,
    required this.title,
    required this.slogan,
    required this.direme,
    required this.hashtag,
    required this.likeCount,
    required this.kinaCount,
    required this.commentCount,
    required this.retweetCount,
    required this.shareCount,
    required this.createdAt,
    required this.ownerEmail,
  });

  /// Kayıt ID'si.
  final String id;

  /// Başlık (adi).
  final String title;

  /// Slogan.
  final String slogan;

  /// Direme (kategori).
  final String direme;

  /// Hashtag.
  final String? hashtag;

  /// Beğeni sayısı.
  final int likeCount;

  /// Kına sayısı.
  final int kinaCount;

  /// Yorum sayısı.
  final int commentCount;

  /// Retweet sayısı.
  final int retweetCount;

  /// Paylaşım sayısı.
  final int shareCount;

  /// Oluşturulma zamanı.
  final DateTime createdAt;

  /// Haykırışın sahibi.
  final String ownerEmail;

  /// Basit arama eşleşmesi.
  bool matchesQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    return [
      title,
      slogan,
      direme,
      hashtag ?? '',
    ].any((value) => value.toLowerCase().contains(trimmed));
  }
}

