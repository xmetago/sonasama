import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/seyir_tokens.dart';
import 'evidence_service.dart';
import 'hive_database_service.dart';

/// Dava yaşam döngüsü durumları (depolama / API stringleri).
abstract class DavaLifecycleStatuses {
  static const String awaitingRole = 'AwaitingRole';
  static const String roleAssigned = 'RoleAssigned';
  static const String finalJudgement = 'FinalJudgement';
  static const String appealProcess = 'AppealProcess';
  static const String archived = 'Archived';
}

/// Zamanlayıcı ve süre sonu işlemleri için yardımcı servis.
///
/// Ana dava döngüsü 168 saat (7 gün):
/// - 0–120 saat: gönüllü rol seçimi (AwaitingRole)
/// - 120–144 saat: boş rollere zorunlu atama dönemi (RoleAssigned)
/// - 144–168 saat: yargıç karar dönemi (FinalJudgement)
/// - 168+72 saat: isteğe bağlı temyiz penceresi (AppealProcess)
/// - 10. gün sonu: arşiv (isArchived), silme yerine pasifleştirme.
class DavaTimerService {
  static final EvidenceService _evidenceService = EvidenceService();
  /// İlk 5 gün: manuel / gönüllü rol seçimi.
  static const Duration voluntaryRoleWindow = Duration(hours: 120);

  /// 120–144 saat: otomatik atama dönemi.
  static const Duration autoAssignPhaseWindow = Duration(hours: 24);

  /// 144–168 saat: yargıç karar dönemi.
  static const Duration judgeDecisionPhaseWindow = Duration(hours: 24);

  /// Toplam ana süreç (7 gün).
  static const Duration mainTrialWindow = Duration(hours: 168);

  /// Ana süreç bittikten sonra temyiz talebi + temyiz hakimi kararı için üst sınır (72 saat).
  static const Duration appealOptionalWindow = Duration(hours: 72);

  /// Temyiz hakimi atandıktan sonra karar penceresi.
  static const Duration appealJudgeDecisionWindow = Duration(hours: 72);

  /// Arşiv: açılış + 10 gün (aktif listelerden düşürme).
  static const int archiveAfterDaysFromOpen = 10;

  /// Gelen davalar listesinde gösterilen “gönüllü dönem” üst sınırı (eski 72 saat yerine).
  static const Duration incomingAcceptanceWindow = voluntaryRoleWindow;

  /// Kabul edilen davalar için hüküm / süreç takibi (7 gün ana döngü ile uyumlu).
  static const Duration acceptedHukumWindow = mainTrialWindow;

  /// Açılan dava map’inden başlangıç zamanı.
  static DateTime? parseOpenedAt(Map<String, dynamic> dava) {
    return _parseDate(dava['openedAt']) ??
        _parseDate(dava['createdAt']);
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Gelen dava kartı: mevcut segment için geri sayım.
  /// Renk [seyirIncomingPhaseToken] ile temadan okunur.
  static DavaIncomingCountdownSegment? buildIncomingListCountdown({
    required DateTime openedAt,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final elapsed = n.difference(openedAt);
    if (elapsed.isNegative) {
      return DavaIncomingCountdownSegment(
        segmentStart: openedAt,
        segmentEnd: openedAt.add(voluntaryRoleWindow),
        storageStatus: DavaLifecycleStatuses.awaitingRole,
        phaseLabel: 'Mevki seçimi',
      );
    }

    final t120 = voluntaryRoleWindow;
    final t144 = Duration(hours: 144);
    final t168 = mainTrialWindow;
    final t240 = t168 + appealOptionalWindow;

    if (elapsed < t120) {
      return DavaIncomingCountdownSegment(
        segmentStart: openedAt,
        segmentEnd: openedAt.add(t120),
        storageStatus: DavaLifecycleStatuses.awaitingRole,
        phaseLabel: 'Mevki seçimi',
      );
    }
    if (elapsed < t144) {
      return DavaIncomingCountdownSegment(
        segmentStart: openedAt.add(t120),
        segmentEnd: openedAt.add(t144),
        storageStatus: DavaLifecycleStatuses.roleAssigned,
        phaseLabel: 'Otomatik atama / rol tamamlama',
      );
    }
    if (elapsed < t168) {
      return DavaIncomingCountdownSegment(
        segmentStart: openedAt.add(t144),
        segmentEnd: openedAt.add(t168),
        storageStatus: DavaLifecycleStatuses.finalJudgement,
        phaseLabel: 'Yargıç karar dönemi',
      );
    }
    if (elapsed < t240) {
      return DavaIncomingCountdownSegment(
        segmentStart: openedAt.add(t168),
        segmentEnd: openedAt.add(t240),
        storageStatus: DavaLifecycleStatuses.appealProcess,
        phaseLabel: 'Temyiz süreci (isteğe bağlı)',
      );
    }
    return null;
  }

  /// Arşiv zamanı geldi mi? (açılış + 10 gün)
  static bool shouldArchiveByPolicy(DateTime openedAt, DateTime now) {
    return now.difference(openedAt).inDays >= archiveAfterDaysFromOpen;
  }

  /// Kabul edilen davalarda süre aşımına uğrayan kullanıcıları döndürür.
  ///
  /// Dönen listedeki her kayıt şu alanları içerir:
  /// - `mevki`: Kullanıcının görev/mevki bilgisi.
  /// - `displayName`: Kullanıcının görünen adı.
  /// - `userEmail`: Kullanıcının e-posta adresi.
  /// - `acceptedAt`: Kabul tarihi.
  /// - `expiredAt`: Süre aşımının gerçekleştiği tarih.
  static Future<List<Map<String, dynamic>>> getExpiredAcceptedParticipants({
    required String davaId,
    DateTime? referenceTime,
  }) async {
    if (davaId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final now = referenceTime ?? DateTime.now();
    final participants = await HiveDatabaseService.getDavaParticipants(
      davaId,
      normalizeExpired: false,
    );

    if (participants.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final hukumlerByRole =
        await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);

    final List<Map<String, dynamic>> expiredList = [];

    for (final participant in participants) {
      final status = participant['status']?.toString();
      if (status != 'accepted') {
        continue;
      }

      final mevki = _extractMevki(participant);
      if (mevki.isEmpty) {
        continue;
      }

      // Eğer ilgili mevki için hüküm verilmişse süre aşımı oluşmaz.
      if (hukumlerByRole.containsKey(mevki)) {
        continue;
      }

      final acceptedAt = _parseAcceptedAt(participant);
      if (acceptedAt == null) {
        continue;
      }

      final deadline = acceptedAt.add(acceptedHukumWindow);
      if (!now.isAfter(deadline)) {
        continue;
      }

      final displayName = _resolveDisplayName(participant);
      final email = participant['userEmail']?.toString() ?? '';

      expiredList.add({
        'mevki': mevki,
        'displayName': displayName,
        'userEmail': email,
        'acceptedAt': acceptedAt,
        'expiredAt': deadline,
      });
    }

    // Süre dolduğunda oy vermeyen 8-Hüküm kullanıcılarını delillerde varsayılan "beğen" kabul et.
    await _applyDefaultEvidenceLikesForExpiredParticipants(
      davaId: davaId,
      expiredParticipants: expiredList,
    );

    return expiredList;
  }

  static Future<void> _applyDefaultEvidenceLikesForExpiredParticipants({
    required String davaId,
    required List<Map<String, dynamic>> expiredParticipants,
  }) async {
    try {
      if (davaId.trim().isEmpty || expiredParticipants.isEmpty) {
        return;
      }

      final List<String> userEmails = expiredParticipants
          .map((p) => p['userEmail']?.toString().trim() ?? '')
          .where((email) => email.isNotEmpty)
          .toSet()
          .toList();

      if (userEmails.isEmpty) {
        return;
      }

      await _evidenceService.initialize();
      await _evidenceService.applyDefaultLikesForUsers(davaId, userEmails);
    } catch (e) {
      print('❌ Süresi dolanlar için varsayılan delil beğenisi uygulanamadı: $e');
    }
  }

  /// Süre aşımına uğrayan kullanıcılar için metinleri üretir.
  static Future<List<String>> buildExpiredAcceptedMessages({
    required String davaId,
    required String davaAdi,
    DateTime? referenceTime,
  }) async {
    final normalizedDavaAdi =
        davaAdi.trim().isEmpty ? 'Dava Adı Belirtilmemiş' : davaAdi.trim();
    final expired = await getExpiredAcceptedParticipants(
      davaId: davaId,
      referenceTime: referenceTime,
    );

    if (expired.isEmpty) {
      return <String>[];
    }

    return expired.map((participant) {
      final mevki = participant['mevki']?.toString() ?? '';
      final displayName = participant['displayName']?.toString() ?? '';
      return '"$mevki" "$displayName" vicdanı problemleri sebebi ile '
          '"$normalizedDavaAdi" davasında HÜKÜM verememiş bulunmaktadır.';
    }).toList();
  }

  static String _resolveDisplayName(Map<String, dynamic> participant) {
    final directName = participant['displayName']?.toString();
    if (directName != null && directName.trim().isNotEmpty) {
      return directName.trim();
    }

    final email = participant['userEmail']?.toString();
    if (email == null || email.trim().isEmpty) {
      return 'Bilinmeyen Yargıç';
    }

    final registration =
        HiveDatabaseService.getRegistrationByEmail(email.trim());
    if (registration?.judgeName != null &&
        registration!.judgeName.trim().isNotEmpty) {
      return registration.judgeName.trim();
    }

    return email.split('@').first;
  }

  static String _extractMevki(Map<String, dynamic> participant) {
    final mevki = participant['mevkii']?.toString();
    if (mevki != null && mevki.trim().isNotEmpty) {
      return mevki.trim();
    }

    final userRole = participant['userRole']?.toString();
    if (userRole != null && userRole.trim().isNotEmpty) {
      return userRole.trim();
    }

    return '';
  }

  static DateTime? _parseAcceptedAt(Map<String, dynamic> participant) {
    final candidates = <String?>[
      participant['acceptedAt']?.toString(),
      participant['statusUpdatedAt']?.toString(),
      participant['assignedAt']?.toString(),
    ];

    for (final candidate in candidates) {
      if (candidate == null || candidate.trim().isEmpty) {
        continue;
      }
      final parsed = DateTime.tryParse(candidate.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }
}

/// Gelen dava kartı geri sayım segmenti.
class DavaIncomingCountdownSegment {
  const DavaIncomingCountdownSegment({
    required this.segmentStart,
    required this.segmentEnd,
    required this.storageStatus,
    required this.phaseLabel,
  });

  final DateTime segmentStart;
  final DateTime segmentEnd;
  final String storageStatus;
  final String phaseLabel;

  Duration get totalDuration => segmentEnd.difference(segmentStart);
}

/// Fazın Seyir rengi: marka, uyarı, red, temyiz moru.
///
/// Servis Material renk tutmaz; açık ve koyu tema [context] üzerinden okunur.
Color seyirIncomingPhaseToken(BuildContext context, String storageStatus) {
  final tokens = AppTokens.of(context);
  switch (storageStatus) {
    case DavaLifecycleStatuses.roleAssigned:
      return tokens.warning;
    case DavaLifecycleStatuses.finalJudgement:
      return tokens.reject;
    case DavaLifecycleStatuses.appealProcess:
      return SeyirTokens.sectionAppeal;
    case DavaLifecycleStatuses.awaitingRole:
    default:
      return tokens.brand;
  }
}

/// Faz etiketi ve sayaç metni için temaya göre okunaklı renk.
Color seyirIncomingPhaseColor(BuildContext context, String storageStatus) {
  return SeyirPalette.of(context).foreground(
    seyirIncomingPhaseToken(context, storageStatus),
  );
}

/// 8-Hüküm sayacının o anki fazı: 144. saat, 168. saat veya temyiz.
class HukumPhaseClock {
  const HukumPhaseClock({
    required this.label,
    required this.start,
    required this.total,
    required this.expired,
    required this.storageStatus,
  });

  final String label;
  final DateTime start;
  final Duration total;
  final bool expired;
  final String storageStatus;
}

/// Aynı sayaç yerinde 144 / 168 / temyiz fazını anlatır.
HukumPhaseClock hukumPhaseClock({
  required DateTime openedAt,
  required DateTime now,
  DateTime? appealDeadline,
}) {
  final Duration elapsed = now.difference(openedAt);
  const Duration t144 = Duration(hours: 144);
  if (elapsed < t144) {
    return HukumPhaseClock(
      label: '144. saate kalan',
      start: openedAt,
      total: t144,
      expired: false,
      storageStatus: elapsed < DavaTimerService.voluntaryRoleWindow
          ? DavaLifecycleStatuses.awaitingRole
          : DavaLifecycleStatuses.roleAssigned,
    );
  }
  if (elapsed < DavaTimerService.mainTrialWindow) {
    return HukumPhaseClock(
      label: '168. saate kalan',
      start: openedAt,
      total: DavaTimerService.mainTrialWindow,
      expired: false,
      storageStatus: DavaLifecycleStatuses.finalJudgement,
    );
  }
  if (appealDeadline != null && now.isBefore(appealDeadline)) {
    return HukumPhaseClock(
      label: 'Temyiz',
      start: appealDeadline.subtract(DavaTimerService.appealJudgeDecisionWindow),
      total: DavaTimerService.appealJudgeDecisionWindow,
      expired: false,
      storageStatus: DavaLifecycleStatuses.appealProcess,
    );
  }
  final DateTime temyizEnd = openedAt.add(
    DavaTimerService.mainTrialWindow + DavaTimerService.appealOptionalWindow,
  );
  if (now.isBefore(temyizEnd)) {
    return HukumPhaseClock(
      label: 'Temyiz',
      start: openedAt.add(DavaTimerService.mainTrialWindow),
      total: DavaTimerService.appealOptionalWindow,
      expired: false,
      storageStatus: DavaLifecycleStatuses.appealProcess,
    );
  }
  return HukumPhaseClock(
    label: 'Süre doldu',
    start: openedAt,
    total: DavaTimerService.mainTrialWindow,
    expired: true,
    storageStatus: DavaLifecycleStatuses.archived,
  );
}
