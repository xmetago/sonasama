import 'package:flutter/material.dart';

import '../models/friend_category_model.dart';
import '../models/friendship_model.dart';
import '../models/registration_model.dart';
import '../models/user_gamified_score_model.dart';
import '../services/friend_category_service.dart';
import '../services/hive_database_service.dart';
import '../services/itibar_endeksi_service.dart';
import '../utils/proximity_category_rules.dart';

/// Kullanıcıların oyunlaştırılmış puan kartını hesaplayan servis katmanı.
class UserGamifiedScoreService {
  /// Oyun seviyelerinin puan eşiklerini tanımlar.
  static const List<_LevelDefinition> _levelDefinitions = [
    _LevelDefinition(level: 1, minScore: 0, title: 'Çaylak Hakem'),
    _LevelDefinition(level: 2, minScore: 300, title: 'Stratejist'),
    _LevelDefinition(level: 3, minScore: 700, title: 'Taktisyen'),
    _LevelDefinition(level: 4, minScore: 1100, title: 'Usta Hakim'),
    _LevelDefinition(level: 5, minScore: 1600, title: 'Efsanevi Lider'),
    _LevelDefinition(level: 6, minScore: 2200, title: 'Galaktik Yargıç'),
  ];

  /// Verilen kullanıcı için oyunlaştırılmış skor verisini üretir.
  static Future<UserGamifiedScoreModel> buildScore({
    required RegistrationModel targetUser,
  }) async {
    await FriendCategoryService.initialize();

    // ✅ Her kullanıcı için özelleştirilmiş veri hesaplama
    print('📊 Puan kartı hesaplanıyor: ${targetUser.judgeName} (${targetUser.email})');

    final itibar = await ItibarEndeksiService.compute(targetUser);

    final allFriendships = HiveDatabaseService.getAllFriendships();
    final acceptedFriendships = _countFriendships(
      allFriendships,
      targetUser.id,
      FriendshipStatus.accepted,
    );
    final pendingIncoming = _countFriendshipsForRecipient(
      allFriendships,
      targetUser.id,
      FriendshipStatus.pending,
    );
    final pendingOutgoing = _countFriendshipsForRequester(
      allFriendships,
      targetUser.id,
      FriendshipStatus.pending,
    );
    final followingCount = _countFriendshipsForRequester(
      allFriendships,
      targetUser.id,
      FriendshipStatus.following,
    );
    final followerCount = _countFriendshipsForRecipient(
      allFriendships,
      targetUser.id,
      FriendshipStatus.following,
    );

    final ownCategoryRecords =
        FriendCategoryService.listByOwner(targetUser.id);
    final ownCategoryDistribution = _groupCategories(ownCategoryRecords);

    final legacyCategories =
        HiveDatabaseService.getFriendCategories(targetUser.email);

    final incomingCases =
        HiveDatabaseService.getIncomingDavalar(targetUser.email);

    // ✅ Debug: Her kullanıcı için özelleştirilmiş veriler
    print('✅ ${targetUser.judgeName} için özelleştirilmiş veriler:');
    print('   - Kabul edilen arkadaşlıklar: $acceptedFriendships');
    print('   - Bekleyen gelen istekler: $pendingIncoming');
    print('   - Bekleyen giden istekler: $pendingOutgoing');
    print('   - Takipçi sayısı: $followerCount');
    print('   - Takip edilen sayısı: $followingCount');
    print('   - Kategori kayıtları: ${ownCategoryRecords.length}');
    print('   - Legacy kategoriler: ${legacyCategories.length}');
    print('   - Gelen davalar: ${incomingCases.length}');

    final totalScore = (itibar.itibarEndeksi * 541)
        .round()
        .clamp(0, 10279);

    print(
      '   - İtibar Endeksi: ${itibar.itibarEndeksi.toStringAsFixed(2)} '
      '(Sosyal ${itibar.sosyalLig}, Dava ${itibar.davaEnerjisi}, '
      'Hediye ${itibar.hediyeSadakati}, Levh ${itibar.levhMahfuz}, '
      'Diren ${itibar.direnEndeksi})',
    );

    final levelInfo = _resolveLevel(totalScore);
    print('   - Seviye: ${levelInfo.level} (${levelInfo.title})');
    final nextLevel = _nextLevel(levelInfo.level);
    final nextLevelThreshold = nextLevel?.minScore ?? levelInfo.minScore;
    final progressToNext = nextLevel == null
        ? 1.0
        : _calculateProgress(
            totalScore,
            levelInfo.minScore,
            nextLevel.minScore,
          );

    final breakdownItems = [
      ScoreBreakdownItem(
        title: 'İtibar Endeksi',
        description:
            'Beş metriğin aritmetik ortalaması. 0, 3, 6, 9 ve 12 aylık trend için dokunun.',
        points: itibar.itibarEndeksi.round(),
        preciseValue: itibar.itibarEndeksi,
        metricId: 'itibar',
        icon: Icons.insights_outlined,
        color: Colors.deepPurpleAccent,
      ),
      ScoreBreakdownItem(
        title: 'Sosyal Lig',
        description:
            '${itibar.sosyalLigHam} kişi sizi Grup-19 seçti. Puan = kişi sayısı / 19 '
            '(19 kişi = 1, 38 kişi = 2).',
        points: itibar.sosyalLig,
        metricId: 'sosyal',
        icon: Icons.groups,
        color: Colors.orangeAccent,
      ),
      ScoreBreakdownItem(
        title: 'Dava Enerjisi',
        description: 'Kazanılan dava +1, kaybedilen dava −1.',
        points: itibar.davaEnerjisi,
        metricId: 'dava',
        icon: Icons.gavel,
        color: Colors.blueAccent,
      ),
      ScoreBreakdownItem(
        title: 'Masraf/Hediye Sadakati',
        description:
            'Cezai hediyeyi yerine getiren +1, hediyeden kaçınan −19.',
        points: itibar.hediyeSadakati,
        metricId: 'hediye',
        icon: Icons.card_giftcard,
        color: Colors.lightGreen,
      ),
      ScoreBreakdownItem(
        title: 'Levh-i Mahfûz Defteri',
        description:
            'Admin +0 alanına basarak puanı artırır. İleride ahlaki yaşam ölçütüne bağlanır.',
        points: itibar.levhMahfuz,
        metricId: 'levh',
        icon: Icons.menu_book_outlined,
        color: Colors.pinkAccent,
      ),
      ScoreBreakdownItem(
        title: 'Diren Endeksi',
        description:
            'Başka bir üye, sizin yazdığınız diren metnini seçerse +1.',
        points: itibar.direnEndeksi,
        metricId: 'diren',
        icon: Icons.campaign_outlined,
        color: Colors.cyanAccent,
      ),
    ];

    final badges = _resolveBadges(
      acceptedFriendships: acceptedFriendships,
      followerCount: followerCount,
      pendingIncoming: pendingIncoming,
      incomingCases: incomingCases.length,
    );

    final caseHighlights = incomingCases.take(4).map((caseMap) {
      final title = caseMap['davaAdi']?.toString() ?? caseMap['adi']?.toString() ?? 'Bilinmeyen Dava';
      final description = caseMap['davaKonusu']?.toString() ?? 'Konusu belirtilmemiş';
      final openedAtStr = caseMap['openedAt']?.toString();
      DateTime? openedAt;
      if (openedAtStr != null) {
        try {
          openedAt = DateTime.parse(openedAtStr);
        } catch (_) {
          openedAt = null;
        }
      }
      return ScoreCaseHighlight(
        title: title,
        description: description,
        date: openedAt,
      );
    }).toList();

    final interactionMetrics = <String, int>{
      'accepted': acceptedFriendships,
      'pending_incoming': pendingIncoming,
      'pending_outgoing': pendingOutgoing,
      'followers': followerCount,
      'following': followingCount,
      'incoming_cases': incomingCases.length,
    };

    final combinedCategoryDistribution = <String, int>{
      ...ownCategoryDistribution,
    };
    legacyCategories.forEach((_, value) {
      final normalized = _normalizeCategoryName(value);
      combinedCategoryDistribution[normalized] =
          (combinedCategoryDistribution[normalized] ?? 0) + 1;
    });

    return UserGamifiedScoreModel(
      targetUser: targetUser,
      totalScore: totalScore,
      level: levelInfo.level,
      levelTitle: levelInfo.title,
      levelProgress: progressToNext,
      nextLevelThreshold: nextLevelThreshold,
      breakdownItems: breakdownItems,
      earnedBadges: badges,
      categoryDistribution: combinedCategoryDistribution,
      interactionMetrics: interactionMetrics,
      caseHighlights: caseHighlights,
      itibarEndeksi: itibar.itibarEndeksi,
      trendPoints: itibar.trend
          .map(
            (point) => ItibarTrendPoint(
              monthsBack: point.monthsBack,
              label: point.label,
              average: point.average,
            ),
          )
          .toList(),
    );
  }

  /// Seviyeyi skor üzerinden çözümler.
  static _LevelDefinition _resolveLevel(int score) {
    _LevelDefinition current = _levelDefinitions.first;
    for (final level in _levelDefinitions) {
      if (score >= level.minScore) {
        current = level;
      } else {
        break;
      }
    }
    return current;
  }

  /// Sonraki seviye tanımını döndürür.
  static _LevelDefinition? _nextLevel(int currentLevel) {
    final index =
        _levelDefinitions.indexWhere((element) => element.level == currentLevel);
    if (index == -1) return null;
    if (index + 1 >= _levelDefinitions.length) return null;
    return _levelDefinitions[index + 1];
  }

  /// Skor ilerleme yüzdesini hesaplar.
  static double _calculateProgress(int score, int min, int nextMin) {
    if (nextMin <= min) {
      return 1.0;
    }
    final clamped = score.clamp(min, nextMin);
    final progress = (clamped - min) / (nextMin - min);
    return progress.clamp(0.0, 1.0);
  }

  /// Kategorileri normalize eder. Kaldırılan Herkes, Takipçi sayılır.
  static String _normalizeCategoryName(String category) {
    return ProximityCategoryRules.normalize(category) ??
        ProximityCategoryRules.takipci;
  }

  /// Arkadaşlık sayısını hesaplar.
  static int _countFriendships(
    List<FriendshipModel> friendships,
    String userId,
    FriendshipStatus status,
  ) {
    return friendships
        .where((f) =>
            (f.requesterId == userId || f.recipientId == userId) &&
            f.status == status)
        .length;
  }

  /// İstek gönderen olarak sayar.
  static int _countFriendshipsForRequester(
    List<FriendshipModel> friendships,
    String userId,
    FriendshipStatus status,
  ) {
    return friendships
        .where((f) => f.requesterId == userId && f.status == status)
        .length;
  }

  /// İstek alan olarak sayar.
  static int _countFriendshipsForRecipient(
    List<FriendshipModel> friendships,
    String userId,
    FriendshipStatus status,
  ) {
    return friendships
        .where((f) => f.recipientId == userId && f.status == status)
        .length;
  }

  /// Kategori kayıtlarını gruplayıp miktarlarını döndürür.
  static Map<String, int> _groupCategories(
    List<FriendCategoryModel> records,
  ) {
    final map = <String, int>{};
    for (final record in records) {
      final normalized = _normalizeCategoryName(record.category);
      map[normalized] = (map[normalized] ?? 0) + 1;
    }
    return map;
  }

  /// Kazanılan rozetleri belirler.
  static List<ScoreBadgeModel> _resolveBadges({
    required int acceptedFriendships,
    required int followerCount,
    required int pendingIncoming,
    required int incomingCases,
  }) {
    final badges = <ScoreBadgeModel>[];
    if (acceptedFriendships >= 10) {
      badges.add(
        ScoreBadgeModel(
          title: 'Ekip Lideri',
          description: 'En az 10 kabul edilmiş arkadaşlık',
          icon: Icons.emoji_events,
          color: Colors.amberAccent,
        ),
      );
    }
    if (followerCount >= 5) {
      badges.add(
        ScoreBadgeModel(
          title: 'Trend Belirleyici',
          description: 'En az 5 takipçi',
          icon: Icons.trending_up,
          color: Colors.lightBlueAccent,
        ),
      );
    }
    if (pendingIncoming >= 3) {
      badges.add(
        ScoreBadgeModel(
          title: 'Talep Çekici',
          description: '3+ bekleyen davet',
          icon: Icons.mail,
          color: Colors.deepPurpleAccent,
        ),
      );
    }
    if (incomingCases >= 4) {
      badges.add(
        ScoreBadgeModel(
          title: 'Dava Muhafızı',
          description: '4 veya daha fazla aktif dava',
          icon: Icons.gavel,
          color: Colors.redAccent,
        ),
      );
    }
    if (badges.isEmpty) {
      badges.add(
        ScoreBadgeModel(
          title: 'Yükselen Yıldız',
          description: 'İlk başarılar yolda',
          icon: Icons.star_border,
          color: Colors.grey,
        ),
      );
    }
    return badges;
  }
}

/// Seviye tanımını saklayan yardımcı model.
class _LevelDefinition {
  /// Seviye değeri.
  final int level;

  /// Minimum puan.
  final int minScore;

  /// Seviyeye ait başlık.
  final String title;

  /// Varsayılan kurucu.
  const _LevelDefinition({
    required this.level,
    required this.minScore,
    required this.title,
  });
}

