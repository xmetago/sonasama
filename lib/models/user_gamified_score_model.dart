import 'package:flutter/material.dart';
import 'registration_model.dart';

/// Kullanıcıların oyunlaştırılmış puan kartı için temel veri modelini temsil eder.
class UserGamifiedScoreModel {
  /// Skoru hesaplanan kişi.
  final RegistrationModel targetUser;

  /// Toplam puan.
  final int totalScore;

  /// Seviyeyi ifade eden sayısal değer.
  final int level;

  /// Seviyeyi anlamlandıran başlık.
  final String levelTitle;

  /// Bir sonraki seviyeye ilerleme yüzdesi (0-1 arası).
  final double levelProgress;

  /// Bir sonraki seviyeye ulaşmak için gereken toplam puan.
  final int nextLevelThreshold;

  /// Skoru oluşturan alt kalemlerin listesi.
  final List<ScoreBreakdownItem> breakdownItems;

  /// Kazanılan rozetlerin listesi.
  final List<ScoreBadgeModel> earnedBadges;

  /// Kullanıcının kategori bazlı dağılımını tutar.
  final Map<String, int> categoryDistribution;

  /// Arkadaşlık/etkileşim metriklerini saklar.
  final Map<String, int> interactionMetrics;

  /// Davalara ilişkin önemli olayları listeler.
  final List<ScoreCaseHighlight> caseHighlights;

  /// Varsayılan kurucu.
  UserGamifiedScoreModel({
    required this.targetUser,
    required this.totalScore,
    required this.level,
    required this.levelTitle,
    required this.levelProgress,
    required this.nextLevelThreshold,
    required this.breakdownItems,
    required this.earnedBadges,
    required this.categoryDistribution,
    required this.interactionMetrics,
    required this.caseHighlights,
  });
}

/// Puan kartında gösterilen alt kalemleri temsil eder.
class ScoreBreakdownItem {
  /// Kalemin başlığı.
  final String title;

  /// Kalemin kısa açıklaması.
  final String description;

  /// Bu kalemin puana katkısı.
  final int points;

  /// Kalemi görselde temsil eden ikon.
  final IconData icon;

  /// Kalem rengi.
  final Color color;

  /// Varsayılan kurucu.
  ScoreBreakdownItem({
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    required this.color,
  });
}

/// Kullanıcının kazandığı rozet bilgilerini saklar.
class ScoreBadgeModel {
  /// Rozetin adı.
  final String title;

  /// Kısa açıklama.
  final String description;

  /// Rozeti temsil eden ikon.
  final IconData icon;

  /// Rozet rengi.
  final Color color;

  /// Varsayılan kurucu.
  ScoreBadgeModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Davalara ilişkin öne çıkan detayları temsil eder.
class ScoreCaseHighlight {
  /// Davanın başlığı.
  final String title;

  /// Davayla ilgili açıklama.
  final String description;

  /// Davanın açılma veya atanma tarihi.
  final DateTime? date;

  /// Varsayılan kurucu.
  ScoreCaseHighlight({
    required this.title,
    required this.description,
    required this.date,
  });
}

