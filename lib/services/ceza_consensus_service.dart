import '../models/evidence_comment_model.dart';
import 'hive_database_service.dart';

/// 19 günlük ceza oylama ve nihai ceza çözümlemesi.
class CezaConsensusService {
  static const int cezaVotingDays = 19;

  static const List<String> _judgeRolePriority = <String>[
    'Temyiz hakimi',
    'Yargıç',
  ];

  /// Dava kabul tarihinden bu yana geçen gün (yoksa null).
  static Future<int?> daysSinceDavaAccepted(String davaId) async {
    final DateTime? acceptedAt = await HiveDatabaseService.getDavaAcceptedAt(davaId);
    if (acceptedAt == null) {
      return null;
    }
    return DateTime.now().difference(acceptedAt).inDays;
  }

  static Future<bool> isVotingPeriodOpen(String davaId) async {
    final int? days = await daysSinceDavaAccepted(davaId);
    if (days == null) {
      return true;
    }
    return days < cezaVotingDays;
  }

  static Future<bool> isVotingPeriodClosed(String davaId) async {
    final int? days = await daysSinceDavaAccepted(davaId);
    if (days == null) {
      return false;
    }
    return days >= cezaVotingDays;
  }

  /// Rol → ceza metni (yalnızca dolu olanlar).
  static Map<String, String> buildRoleCezaMap({
    required List<Map<String, dynamic>> participants,
    required Map<String, String> cezaByEmailLower,
    required List<String> roleValues,
    required bool Function(String mevkii, String roleValue) roleMatcher,
  }) {
    final Map<String, String> out = <String, String>{};
    for (final String roleValue in roleValues) {
      Map<String, dynamic>? p;
      for (final Map<String, dynamic> row in participants) {
        final String mevki = (row['mevkii']?.toString() ?? '').trim();
        if (mevki.isEmpty) {
          continue;
        }
        if (roleMatcher(mevki, roleValue)) {
          p = row;
          break;
        }
      }
      if (p == null) {
        continue;
      }
      final String email =
          (p['userEmail']?.toString() ?? '').trim().toLowerCase();
      if (email.isEmpty) {
        continue;
      }
      final String? ceza = cezaByEmailLower[email];
      if (ceza != null && ceza.trim().isNotEmpty) {
        out[roleValue] = ceza.trim();
      }
    }
    return out;
  }

  static Map<String, int> countVotesByRole(Map<String, String> votesByEmail) {
    final Map<String, int> counts = <String, int>{};
    for (final String role in votesByEmail.values) {
      final String r = role.trim();
      if (r.isEmpty) {
        continue;
      }
      counts[r] = (counts[r] ?? 0) + 1;
    }
    return counts;
  }

  static String? _winningRoleFromVotes(Map<String, int> counts) {
    if (counts.isEmpty) {
      return null;
    }
    String? winner;
    int max = 0;
    for (final MapEntry<String, int> e in counts.entries) {
      if (e.value > max) {
        max = e.value;
        winner = e.key;
      }
    }
    return max > 0 ? winner : null;
  }

  static String? _defaultJudgeRole({
    required Map<String, String> roleCezaMap,
    required List<Map<String, dynamic>> participants,
    required bool Function(String mevkii, String roleValue) roleMatcher,
  }) {
    for (final String role in _judgeRolePriority) {
      if (!roleCezaMap.containsKey(role)) {
        continue;
      }
      bool assigned = false;
      for (final Map<String, dynamic> row in participants) {
        final String mevki = (row['mevkii']?.toString() ?? '').trim();
        if (mevki.isNotEmpty && roleMatcher(mevki, role)) {
          assigned = true;
          break;
        }
      }
      if (assigned) {
        return role;
      }
    }
    return null;
  }

  /// Nihai / geçerli ceza: halk oyu çoğunluğu; oylama yoksa Temyiz → Yargıç.
  static CezaEffectiveResult resolveEffectiveCeza({
    required Map<String, String> roleCezaMap,
    required Map<String, String> votesByEmail,
    required bool votingPeriodClosed,
    required List<Map<String, dynamic>> participants,
    required bool Function(String mevkii, String roleValue) roleMatcher,
  }) {
    final Map<String, int> voteCounts = countVotesByRole(votesByEmail);
    final String? votedRole = _winningRoleFromVotes(voteCounts);
    final String? judgeRole = _defaultJudgeRole(
      roleCezaMap: roleCezaMap,
      participants: participants,
      roleMatcher: roleMatcher,
    );

    String? sourceRole;
    CezaEffectiveSource source = CezaEffectiveSource.none;

    if (votedRole != null && roleCezaMap.containsKey(votedRole)) {
      sourceRole = votedRole;
      source = CezaEffectiveSource.halkOyu;
    } else if (!votingPeriodClosed && judgeRole != null) {
      sourceRole = judgeRole;
      source = judgeRole == 'Temyiz hakimi'
          ? CezaEffectiveSource.temyizHakimi
          : CezaEffectiveSource.yargic;
    } else if (votingPeriodClosed && judgeRole != null && votedRole == null) {
      sourceRole = judgeRole;
      source = judgeRole == 'Temyiz hakimi'
          ? CezaEffectiveSource.temyizHakimi
          : CezaEffectiveSource.yargic;
    }

    final String? text =
        sourceRole != null ? roleCezaMap[sourceRole] : null;

    return CezaEffectiveResult(
      cezaText: text,
      sourceRole: sourceRole,
      source: source,
      voteCountsByRole: voteCounts,
      votingPeriodClosed: votingPeriodClosed,
      judgeFallbackRole: judgeRole,
    );
  }

  static String _stripMevkiiKarariSuffix(String raw) {
    final String t = raw.trim();
    if (t.endsWith(' Kararı')) {
      return t.substring(0, t.length - 7).trim();
    }
    return t;
  }

  /// Katılımcı mevkii ile [EvidenceCommentRole] değerini eşleştirir.
  static bool mevkiiMatchesEvidenceRole(String mevkiiRaw, String roleValue) {
    final String a = _stripMevkiiKarariSuffix(mevkiiRaw).toLowerCase();
    final String b = roleValue.trim().toLowerCase();
    if (a == b) {
      return true;
    }
    final String collapsedA = a.replaceAll(RegExp(r'\s+'), '');
    final String collapsedB = b.replaceAll(RegExp(r'\s+'), '');
    return collapsedA == collapsedB;
  }

  static String? _emailForRole(
    List<Map<String, dynamic>> participants,
    String? roleValue,
  ) {
    if (roleValue == null || roleValue.trim().isEmpty) {
      return null;
    }
    for (final Map<String, dynamic> row in participants) {
      final String mevki = (row['mevkii']?.toString() ?? '').trim();
      if (mevki.isNotEmpty && mevkiiMatchesEvidenceRole(mevki, roleValue)) {
        final String email = (row['userEmail']?.toString() ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          return email;
        }
      }
    }
    return null;
  }

  static Future<Map<String, String>> _mergedCezaMapForDava(
    String davaId,
    String? davaAdi,
  ) async {
    Map<String, String> cezaByEmail =
        await HiveDatabaseService.getCezaMapForDavaId(davaId);
    final String ad = davaAdi?.trim() ?? '';
    if (ad.isNotEmpty) {
      final String altId = 'dava_${ad.hashCode}';
      if (altId != davaId) {
        final Map<String, String> altMap =
            await HiveDatabaseService.getCezaMapForDavaId(altId);
        for (final MapEntry<String, String> e in altMap.entries) {
          cezaByEmail.putIfAbsent(e.key, () => e.value);
        }
      }
    }
    return cezaByEmail;
  }

  /// Seyir defteri ve dava kartları için geçerli ceza + masraf kaynağı.
  static Future<CezaDavaLoadResult> loadEffectiveCezaForDava({
    required String davaId,
    String? davaAdi,
  }) async {
    if (davaId.trim().isEmpty) {
      return const CezaDavaLoadResult(
        primaryDavaId: '',
        effective: CezaEffectiveResult(
          cezaText: null,
          sourceRole: null,
          source: CezaEffectiveSource.none,
          voteCountsByRole: {},
          votingPeriodClosed: false,
        ),
        masrafSourceEmail: null,
      );
    }

    String primaryDavaId = davaId;
    final String ad = davaAdi?.trim() ?? '';
    if (ad.isNotEmpty) {
      final String altId = 'dava_${ad.hashCode}';
      final Map<String, String> altOnly =
          await HiveDatabaseService.getCezaMapForDavaId(altId);
      final Map<String, String> mainOnly =
          await HiveDatabaseService.getCezaMapForDavaId(davaId);
      if (mainOnly.isEmpty && altOnly.isNotEmpty) {
        primaryDavaId = altId;
      }
    }

    final List<Map<String, dynamic>> participants =
        await HiveDatabaseService.getDavaParticipants(primaryDavaId);
    final Map<String, String> cezaByEmail =
        await _mergedCezaMapForDava(primaryDavaId, davaAdi);
    final Map<String, String> votesByEmail =
        await HiveDatabaseService.getCezaOyMapForDavaId(primaryDavaId);
    final bool votingOpen = await isVotingPeriodOpen(primaryDavaId);
    final List<String> roleValues =
        EvidenceCommentRole.allRoles.map((r) => r.value).toList();
    final Map<String, String> roleCezaMap = buildRoleCezaMap(
      participants: participants,
      cezaByEmailLower: cezaByEmail,
      roleValues: roleValues,
      roleMatcher: mevkiiMatchesEvidenceRole,
    );
    final CezaEffectiveResult effective = resolveEffectiveCeza(
      roleCezaMap: roleCezaMap,
      votesByEmail: votesByEmail,
      votingPeriodClosed: !votingOpen,
      participants: participants,
      roleMatcher: mevkiiMatchesEvidenceRole,
    );

    String? masrafEmail = _emailForRole(participants, effective.sourceRole);
    masrafEmail ??= _emailForRole(participants, effective.judgeFallbackRole);

    return CezaDavaLoadResult(
      primaryDavaId: primaryDavaId,
      effective: effective,
      masrafSourceEmail: masrafEmail,
    );
  }

  static Future<List<String>?> loadMasraflarForDava({
    required CezaDavaLoadResult loadResult,
    required String davaId,
    String? davaAdi,
  }) async {
    final String? email = loadResult.masrafSourceEmail;
    if (email == null || email.isEmpty) {
      return null;
    }
    List<String>? masraflar = await HiveDatabaseService.getMasrafExpenses(
      davaId: loadResult.primaryDavaId,
      userEmail: email,
    );
    if ((masraflar == null || masraflar.isEmpty) &&
        davaAdi != null &&
        davaAdi.trim().isNotEmpty &&
        loadResult.primaryDavaId != davaId) {
      masraflar = await HiveDatabaseService.getMasrafExpenses(
        davaId: davaId,
        userEmail: email,
      );
    }
    if ((masraflar == null || masraflar.isEmpty) &&
        davaAdi != null &&
        davaAdi.trim().isNotEmpty) {
      final String altId = 'dava_${davaAdi.hashCode}';
      if (altId != loadResult.primaryDavaId && altId != davaId) {
        masraflar = await HiveDatabaseService.getMasrafExpenses(
          davaId: altId,
          userEmail: email,
        );
      }
    }
    return masraflar;
  }
}

/// Dava kartı / onay butonu için yükleme sonucu.
class CezaDavaLoadResult {
  final String primaryDavaId;
  final CezaEffectiveResult effective;
  final String? masrafSourceEmail;

  const CezaDavaLoadResult({
    required this.primaryDavaId,
    required this.effective,
    required this.masrafSourceEmail,
  });
}

enum CezaEffectiveSource {
  none,
  halkOyu,
  temyizHakimi,
  yargic,
}

class CezaEffectiveResult {
  final String? cezaText;
  final String? sourceRole;
  final CezaEffectiveSource source;
  final Map<String, int> voteCountsByRole;
  final bool votingPeriodClosed;
  final String? judgeFallbackRole;

  const CezaEffectiveResult({
    required this.cezaText,
    required this.sourceRole,
    required this.source,
    required this.voteCountsByRole,
    required this.votingPeriodClosed,
    this.judgeFallbackRole,
  });

  String sourceLabel() {
    switch (source) {
      case CezaEffectiveSource.halkOyu:
        return 'Halk oyu (çoğunluk)';
      case CezaEffectiveSource.temyizHakimi:
        return 'Temyiz hakimi (geçici, 19. güne kadar)';
      case CezaEffectiveSource.yargic:
        return 'Yargıç (geçici, 19. güne kadar)';
      case CezaEffectiveSource.none:
        return '';
    }
  }
}
