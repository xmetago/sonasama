import 'dart:math';

import 'dava_timer_service.dart';
import 'hive_database_service.dart';

/// Temyiz talebi sonrası temyiz hakimini **karşı tarafın** takipçileri arasından atar.
/// Davacı temyiz ederse → davalının takipçileri; davalı temyiz ederse → davacının takipçileri.
class DavaAppealJudgeAssignService {
  DavaAppealJudgeAssignService._();

  static const String appealJudgeRole = 'Temyiz hakimi';

  /// Davacı/davalı alanından e-posta çözümler.
  static String? resolvePartyEmail(String partyValue) {
    final pv = partyValue.trim();
    if (pv.isEmpty) return null;
    if (pv.contains('@')) {
      final reg = HiveDatabaseService.getRegistrationByEmail(pv);
      return (reg?.email ?? pv).trim();
    }
    final reg = HiveDatabaseService.getRegistrationByJudgeName(pv);
    return reg?.email.trim();
  }

  /// Kişisel listedeki takipçilerden rastgele bir e-posta seçer.
  static String? pickRandomFollowerEmail({
    required String ownerEmail,
    required Set<String> excludedEmails,
  }) {
    final categories = HiveDatabaseService.getFriendCategories(ownerEmail);
    final followerEmails = categories.entries
        .where((entry) {
          final categoryLower = entry.value.toLowerCase();
          return categoryLower.contains('takipçi') ||
              categoryLower.contains('takipci') ||
              categoryLower.contains('follower') ||
              categoryLower == 'takipçi' ||
              categoryLower == 'takipçiler';
        })
        .map((e) => e.key.trim().toLowerCase())
        .where((email) => email.isNotEmpty && !excludedEmails.contains(email))
        .toList();

    if (followerEmails.isEmpty) return null;
    followerEmails.shuffle(Random());
    return followerEmails.first;
  }

  static Future<DavaAppealJudgeAssignResult> assignFromAppealRequest({
    required String davaId,
    required String requestedByEmail,
    required String party, // 'davaci' | 'davali'
  }) async {
    if (davaId.trim().isEmpty) {
      return DavaAppealJudgeAssignResult.failed('Dava kimliği bulunamadı.');
    }

    final opened = HiveDatabaseService.getOpenedDavaById(davaId);
    if (opened == null) {
      return DavaAppealJudgeAssignResult.failed('Açılmış dava kaydı bulunamadı.');
    }

    final davaciRaw = (opened['davaci'] ?? '').toString();
    final davaliRaw = (opened['davali'] ?? '').toString();
    final davaciEmail = resolvePartyEmail(davaciRaw);
    final davaliEmail = resolvePartyEmail(davaliRaw);

    // Zıt taraf: davacı temyiz → davalının takipçileri; davalı temyiz → davacının takipçileri.
    final String? followerPoolOwnerEmail = party == 'davaci'
        ? davaliEmail
        : party == 'davali'
            ? davaciEmail
            : null;

    if (followerPoolOwnerEmail == null || followerPoolOwnerEmail.isEmpty) {
      final poolSideLabel = party == 'davaci' ? 'Davalı' : 'Davacı';
      return DavaAppealJudgeAssignResult.failed(
        'Temyiz hakimi için $poolSideLabel tarafının e-posta bilgisi bulunamadı.',
      );
    }

    final participants =
        await HiveDatabaseService.getDavaParticipants(davaId, normalizeExpired: false);
    final excluded = <String>{
      requestedByEmail.trim().toLowerCase(),
      if (davaciEmail != null) davaciEmail.toLowerCase(),
      if (davaliEmail != null) davaliEmail.toLowerCase(),
      for (final p in participants)
        (p['userEmail']?.toString() ?? '').trim().toLowerCase(),
    }..removeWhere((e) => e.isEmpty);

    final assigneeEmail = pickRandomFollowerEmail(
      ownerEmail: followerPoolOwnerEmail,
      excludedEmails: excluded,
    );

    final now = DateTime.now();
    await HiveDatabaseService.updateOpenedDava(davaId, {
      'isAppealable': true,
      'appealRequestedAt': now.toIso8601String(),
      'appealRequestedBy': requestedByEmail,
      'appealRequestedParty': party,
      'lifecycleStatus': DavaLifecycleStatuses.appealProcess,
      'lifecycleStatusAt': now.toIso8601String(),
      if (assigneeEmail != null) ...{
        'appealJudgeAssigneeEmail': assigneeEmail,
        'appealJudgeAssignedAt': now.toIso8601String(),
        'appealJudgeAssignmentPending': true,
      } else ...{
        'appealJudgeAssigneeEmail': null,
        'appealJudgeAssignedAt': null,
        'appealJudgeAssignmentPending': false,
        'appealJudgeUnassignedReason': 'no_followers',
      },
    });

    if (assigneeEmail == null) {
      return DavaAppealJudgeAssignResult.noFollowers();
    }

    final assigneeReg = HiveDatabaseService.getRegistrationByEmail(assigneeEmail);
    final davaAdi =
        (opened['adi'] ?? opened['davaAdi'] ?? '').toString().trim();
    final kategori =
        (opened['kategori'] ?? opened['davaKategori'] ?? '').toString();
    final openedAtStr = opened['openedAt']?.toString();
    final openedAt = openedAtStr != null && openedAtStr.isNotEmpty
        ? DateTime.tryParse(openedAtStr)
        : null;

    final incomingDava = <String, dynamic>{
      'id': davaId,
      'davaId': davaId,
      'adi': davaAdi,
      'davaAdi': davaAdi,
      'davaKonusu': (opened['davaKonusu'] ?? davaAdi).toString(),
      'kategori': kategori,
      'davaKategori': kategori,
      'davaci': davaciRaw,
      'davali': davaliRaw,
      'mevkii': appealJudgeRole,
      'userRole': appealJudgeRole,
      'isAppealJudgeAssignment': true,
      'appealRequestedParty': party,
      'appealRequestedBy': requestedByEmail,
      'appealRequestedAt': now.toIso8601String(),
      'assignedAt': now.toIso8601String(),
      'lifecycleStatus': DavaLifecycleStatuses.appealProcess,
      'createdAt': (openedAt ?? now).toIso8601String(),
      'kalanSure': '.../.../.....',
      'profilResmi': 'lib/icons/03_davala_ana_icon.png',
    };

    HiveDatabaseService.addIncomingDava(assigneeEmail, incomingDava);

    await HiveDatabaseService.upsertDavaParticipant(davaId, {
      'userEmail': assigneeEmail,
      'displayName': assigneeReg?.judgeName ??
          assigneeEmail.split('@').first,
      'status': 'pending',
      'statusUpdatedAt': now.toIso8601String(),
      'assignedAt': now.toIso8601String(),
      'mevkii': appealJudgeRole,
      'userRole': appealJudgeRole,
      'isAppealJudgeAssignment': true,
      'appealAssignedByParty': party,
    });

    return DavaAppealJudgeAssignResult.assigned(
      assigneeEmail: assigneeEmail,
      assigneeDisplayName:
          assigneeReg?.judgeName ?? assigneeEmail.split('@').first,
    );
  }

  static bool isAppealJudgeRole(String? mevkii) {
    final t = (mevkii ?? '').toLowerCase().replaceAll('ı', 'i');
    return t.contains('temyiz') && t.contains('hakim');
  }
}

class DavaAppealJudgeAssignResult {
  const DavaAppealJudgeAssignResult._({
    required this.success,
    this.assigneeEmail,
    this.assigneeDisplayName,
    this.noFollowers = false,
    this.message,
  });

  final bool success;
  final String? assigneeEmail;
  final String? assigneeDisplayName;
  final bool noFollowers;
  final String? message;

  factory DavaAppealJudgeAssignResult.assigned({
    required String assigneeEmail,
    required String assigneeDisplayName,
  }) =>
      DavaAppealJudgeAssignResult._(
        success: true,
        assigneeEmail: assigneeEmail,
        assigneeDisplayName: assigneeDisplayName,
      );

  factory DavaAppealJudgeAssignResult.noFollowers() =>
      const DavaAppealJudgeAssignResult._(
        success: true,
        noFollowers: true,
        message:
            'Temyiz talebi kaydedildi; takipçi bulunamadığı için hakim atanmadı. Dava mevcut haliyle sonuçlanır.',
      );

  factory DavaAppealJudgeAssignResult.failed(String message) =>
      DavaAppealJudgeAssignResult._(
        success: false,
        message: message,
      );
}
