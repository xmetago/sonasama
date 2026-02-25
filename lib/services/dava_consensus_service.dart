import 'dart:async';

import '../models/hukum_sentiment.dart';
import 'hive_database_service.dart';

/// Davalarda olumlu/olumsuz hüküm çoğunluğunu hesaplayan servis.
class DavaConsensusService {
  /// Nihai karar penceresi: 7 gün (168 saat).
  static const Duration consensusWindow = Duration(days: 7);

  /// Belirtilen dava için mevcut hüküm dağılımını ve çoğunluk sonucunu döndürür.
  static Future<DavaConsensusEvaluation> evaluateConsensus({
    required String davaId,
    DateTime? openedAt,
    DateTime? referenceTime,
  }) async {
    if (davaId.isEmpty) {
      return const DavaConsensusEvaluation.empty();
    }

    final DateTime now = referenceTime ?? DateTime.now();
    final List<Map<String, dynamic>> hukumler =
        await HiveDatabaseService.getHukumlerByDavaId(davaId);

    int positiveCount = 0;
    int negativeCount = 0;

    for (final Map<String, dynamic> hukum in hukumler) {
      final HukumSentiment? sentiment =
          hukumSentimentFromStorage(hukum['hukumSentiment']?.toString());
      if (sentiment == null) {
        continue;
      }
      if (sentiment == HukumSentiment.positive) {
        positiveCount++;
      } else {
        negativeCount++;
      }
    }

    final DateTime? resolvedOpenedAt = await _resolveOpenedAt(
      davaId: davaId,
      providedOpenedAt: openedAt,
      hukumler: hukumler,
    );

    bool isFinal = false;
    Duration? remainingDuration;
    if (resolvedOpenedAt != null) {
      final Duration diff = now.difference(resolvedOpenedAt);
      if (diff >= consensusWindow) {
        isFinal = true;
      } else {
        remainingDuration = consensusWindow - diff;
      }
    }

    final DavaConsensusVerdict verdict =
        negativeCount > positiveCount ? DavaConsensusVerdict.haksiz : DavaConsensusVerdict.hakli;

    return DavaConsensusEvaluation(
      positiveCount: positiveCount,
      negativeCount: negativeCount,
      verdict: verdict,
      isFinal: isFinal,
      openedAt: resolvedOpenedAt,
      evaluationTime: now,
      remainingDuration: remainingDuration,
    );
  }

  static Future<DateTime?> _resolveOpenedAt({
    required String davaId,
    required DateTime? providedOpenedAt,
    required List<Map<String, dynamic>> hukumler,
  }) async {
    if (providedOpenedAt != null) {
      return providedOpenedAt;
    }

    DateTime? candidate;

    // Önce açılan davalar kutusunda ara.
    final List<Map<String, dynamic>> openedDavalar =
        HiveDatabaseService.getOpenedDavalar();
    for (final Map<String, dynamic> dava in openedDavalar) {
      if ((dava['id'] ?? '').toString() == davaId) {
        candidate = _parseDate(dava['openedAt']) ??
            _parseDate(dava['createdAt']) ??
            candidate;
        if (candidate != null) {
          return candidate;
        }
      }
    }

    // Hüküm kayıtlarının oluşturulma tarihine bak.
    for (final Map<String, dynamic> hukum in hukumler) {
      final DateTime? createdAt = _parseDate(hukum['createdAt']);
      if (createdAt != null) {
        candidate = _minDate(candidate, createdAt);
      }
    }
    if (candidate != null) {
      return candidate;
    }

    // Katılımcı atamalarından tarih yakalamaya çalış.
    final List<Map<String, dynamic>> participants =
        await HiveDatabaseService.getDavaParticipants(
      davaId,
      normalizeExpired: false,
    );
    for (final Map<String, dynamic> participant in participants) {
      final DateTime? assignedAt = _parseDate(participant['assignedAt']);
      if (assignedAt != null) {
        candidate = _minDate(candidate, assignedAt);
      }
      final DateTime? statusUpdatedAt =
          _parseDate(participant['statusUpdatedAt']);
      if (statusUpdatedAt != null) {
        candidate = _minDate(candidate, statusUpdatedAt);
      }
    }

    return candidate;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final String stringValue = value.toString();
    if (stringValue.isEmpty) return null;
    return DateTime.tryParse(stringValue);
  }

  static DateTime? _minDate(DateTime? current, DateTime other) {
    if (current == null) return other;
    return other.isBefore(current) ? other : current;
  }
}

/// Davacı için ortaya çıkan çoğunluk kararını temsil eder.
class DavaConsensusEvaluation {
  const DavaConsensusEvaluation({
    required this.positiveCount,
    required this.negativeCount,
    required this.verdict,
    required this.isFinal,
    required this.openedAt,
    required this.evaluationTime,
    this.remainingDuration,
  });

  const DavaConsensusEvaluation.empty()
      : positiveCount = 0,
        negativeCount = 0,
        verdict = DavaConsensusVerdict.hakli,
        isFinal = false,
        openedAt = null,
        evaluationTime = null,
        remainingDuration = null;

  final int positiveCount;
  final int negativeCount;
  final DavaConsensusVerdict verdict;
  final bool isFinal;
  final DateTime? openedAt;
  final DateTime? evaluationTime;
  final Duration? remainingDuration;

  int get totalVotes => positiveCount + negativeCount;

  String get verdictLabel => verdict.displayLabel;

  /// Konsensus oluşması için kalan süre metni (henüz dolmadıysa).
  String? get remainingLabel {
    if (remainingDuration == null) {
      return null;
    }
    return _formatDuration(remainingDuration!);
  }

  static String _formatDuration(Duration duration) {
    final int totalMinutes = duration.inMinutes;
    final int days = totalMinutes ~/ (24 * 60);
    final int hours = (totalMinutes % (24 * 60)) ~/ 60;
    final int minutes = totalMinutes % 60;

    final List<String> parts = <String>[];
    if (days > 0) {
      parts.add('$days gün');
    }
    if (hours > 0) {
      parts.add('$hours saat');
    }
    if (minutes > 0 && parts.length < 2) {
      parts.add('$minutes dakika');
    }
    return parts.isEmpty ? 'az sonra' : parts.join(' ');
  }
}

/// Çoğunluk sonucuna göre davacının durumunu belirten enum.
enum DavaConsensusVerdict { hakli, haksiz }

extension DavaConsensusVerdictX on DavaConsensusVerdict {
  String get displayLabel => switch (this) {
        DavaConsensusVerdict.hakli => 'HAKLI',
        DavaConsensusVerdict.haksiz => 'HAKSIZ',
      };
}

