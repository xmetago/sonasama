import 'package:flutter/material.dart';

import '../models/friend_category_model.dart';
import '../models/friendship_model.dart';
import '../models/registration_model.dart';
import '../models/user_gamified_score_model.dart';
import '../services/friend_category_service.dart';
import '../services/hive_database_service.dart';
import '../services/user_session_service.dart';

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

    final viewer = UserSessionService.getCurrentUser();
    final viewerCategory = viewer == null
        ? null
        : FriendCategoryService.getByOwnerAndTarget(viewer.id, targetUser.id);

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

    final viewerCategoryScore = _scoreForViewerCategory(viewerCategory);
    final acceptedScore = acceptedFriendships * 60;
    final pendingScore = (pendingIncoming + pendingOutgoing) * 18;
    final socialReachScore =
        (followerCount * 35) + (followingCount * 22);
    final strategistScore = ownCategoryRecords.length * 12;
    final legacyScore = legacyCategories.length * 6;
    final justiceActivityScore = incomingCases.length * 28;

    final totalScore = viewerCategoryScore +
        acceptedScore +
        pendingScore +
        socialReachScore +
        strategistScore +
        legacyScore +
        justiceActivityScore;

    // ✅ Debug: Toplam puan detayları
    print('   - Toplam puan: $totalScore (Kategori: $viewerCategoryScore, Arkadaşlık: $acceptedScore, Bekleyen: $pendingScore, Sosyal: $socialReachScore, Strateji: $strategistScore, Legacy: $legacyScore, Dava: $justiceActivityScore)');

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
        title: 'Kategori Aurasi',
        description:
            viewerCategory == null ? 'Henüz kategorizasyon yapılmadı' : _viewerCategoryLabel(viewerCategory.category),
        points: viewerCategoryScore,
        icon: Icons.shield,
        color: Colors.deepPurpleAccent,
      ),
      ScoreBreakdownItem(
        title: 'Sosyal Lig',
        description: 'Kabul edilen arkadaşlıklar',
        points: acceptedScore,
        icon: Icons.groups,
        color: Colors.orangeAccent,
      ),
      ScoreBreakdownItem(
        title: 'Yeni İttifaklar',
        description: 'Bekleyen istekler',
        points: pendingScore,
        icon: Icons.hourglass_top,
        color: Colors.blueAccent,
      ),
      ScoreBreakdownItem(
        title: 'Etkileşim Dalgası',
        description: 'Takipçiler ve takip edilenler',
        points: socialReachScore,
        icon: Icons.waves,
        color: Colors.lightGreen,
      ),
      ScoreBreakdownItem(
        title: 'Strateji Defteri',
        description: 'Kategorize ettiği kişiler',
        points: strategistScore + legacyScore,
        icon: Icons.auto_awesome,
        color: Colors.pinkAccent,
      ),
      ScoreBreakdownItem(
        title: 'Dava Enerjisi',
        description: 'Atanan aktif davalar',
        points: justiceActivityScore,
        icon: Icons.balance,
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

  /// İzleyenin atadığı kategoriye göre skor hesaplar.
  static int _scoreForViewerCategory(FriendCategoryModel? viewerCategory) {
    if (viewerCategory == null) return 80;
    final normalized = _normalizeCategoryName(viewerCategory.category);
    switch (normalized) {
      case 'Grup-19':
        return 320;
      case 'Arkadaş':
        return 220;
      case 'Takipçi':
        return 150;
      case 'Herkes':
        return 110;
      default:
        return 90;
    }
  }

  /// İzleyici kategorisi için okunabilir etiket üretir.
  static String _viewerCategoryLabel(String rawCategory) {
    final normalized = _normalizeCategoryName(rawCategory);
    switch (normalized) {
      case 'Grup-19':
        return 'Grup-19 elit kadrosunda';
      case 'Arkadaş':
        return 'Arkadaş halkasında';
      case 'Takipçi':
        return 'Takip listesinde';
      case 'Herkes':
        return 'Genel erişim listesinde';
      default:
        return '$normalized kategorisinde';
    }
  }

  /// Kategorileri normalize eder.
  static String _normalizeCategoryName(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('grup')) return 'Grup-19';
    if (lower.contains('ark')) return 'Arkadaş';
    if (lower.contains('takip')) return 'Takipçi';
    return 'Herkes';
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

