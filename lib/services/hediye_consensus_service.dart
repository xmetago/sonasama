import '../models/evidence_comment_model.dart';
import 'ceza_consensus_service.dart';
import 'hive_database_service.dart';

/// 19 günlük hediye oylama ve nihai hediye çözümlemesi (ceza mantığı ile paralel).
class HediyeConsensusService {
  static const int hediyeVotingDays = CezaConsensusService.cezaVotingDays;

  static const List<String> _judgeRolePriority = <String>[
    'Temyiz hakimi',
    'Yargıç',
  ];

  static Future<bool> isVotingPeriodOpen(String davaId) =>
      CezaConsensusService.isVotingPeriodOpen(davaId);

  /// Rol → hediye satırı (yalnızca dolu olanlar).
  static Map<String, String> buildRoleHediyeMap({
    required List<Map<String, dynamic>> participants,
    required Map<String, String> hediyeByEmailLower,
    required List<String> roleValues,
  }) {
    return CezaConsensusService.buildRoleCezaMap(
      participants: participants,
      cezaByEmailLower: hediyeByEmailLower,
      roleValues: roleValues,
      roleMatcher: CezaConsensusService.mevkiiMatchesEvidenceRole,
    );
  }

  static Map<String, int> countVotesByRole(Map<String, String> votesByEmail) =>
      CezaConsensusService.countVotesByRole(votesByEmail);

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
    required Map<String, String> roleHediyeMap,
    required List<Map<String, dynamic>> participants,
  }) {
    for (final String role in _judgeRolePriority) {
      if (!roleHediyeMap.containsKey(role)) {
        continue;
      }
      bool assigned = false;
      for (final Map<String, dynamic> row in participants) {
        final String mevki = (row['mevkii']?.toString() ?? '').trim();
        if (mevki.isNotEmpty &&
            CezaConsensusService.mevkiiMatchesEvidenceRole(mevki, role)) {
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

  static HediyeEffectiveResult resolveEffectiveHediye({
    required Map<String, String> roleHediyeMap,
    required Map<String, String> votesByEmail,
    required bool votingPeriodClosed,
    required List<Map<String, dynamic>> participants,
  }) {
    final Map<String, int> voteCounts = countVotesByRole(votesByEmail);
    final String? votedRole = _winningRoleFromVotes(voteCounts);
    final String? judgeRole = _defaultJudgeRole(
      roleHediyeMap: roleHediyeMap,
      participants: participants,
    );

    String? sourceRole;
    HediyeEffectiveSource source = HediyeEffectiveSource.none;

    if (votedRole != null && roleHediyeMap.containsKey(votedRole)) {
      sourceRole = votedRole;
      source = HediyeEffectiveSource.halkOyu;
    } else if (!votingPeriodClosed && judgeRole != null) {
      sourceRole = judgeRole;
      source = judgeRole == 'Temyiz hakimi'
          ? HediyeEffectiveSource.temyizHakimi
          : HediyeEffectiveSource.yargic;
    } else if (votingPeriodClosed && judgeRole != null && votedRole == null) {
      sourceRole = judgeRole;
      source = judgeRole == 'Temyiz hakimi'
          ? HediyeEffectiveSource.temyizHakimi
          : HediyeEffectiveSource.yargic;
    }

    final String? text =
        sourceRole != null ? roleHediyeMap[sourceRole] : null;

    return HediyeEffectiveResult(
      hediyeText: text,
      sourceRole: sourceRole,
      source: source,
      voteCountsByRole: voteCounts,
      votingPeriodClosed: votingPeriodClosed,
      judgeFallbackRole: judgeRole,
    );
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
      if (mevki.isNotEmpty &&
          CezaConsensusService.mevkiiMatchesEvidenceRole(mevki, roleValue)) {
        final String email =
            (row['userEmail']?.toString() ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          return email;
        }
      }
    }
    return null;
  }

  static Future<Map<String, String>> _mergedHediyeMapForDava(
    String davaId,
    String? davaAdi,
  ) async {
    Map<String, String> hediyeByEmail =
        await HiveDatabaseService.getMasrafGiftLineMapForDavaId(davaId);
    final String ad = davaAdi?.trim() ?? '';
    if (ad.isNotEmpty) {
      final String altId = 'dava_${ad.hashCode}';
      if (altId != davaId) {
        final Map<String, String> altMap =
            await HiveDatabaseService.getMasrafGiftLineMapForDavaId(altId);
        for (final MapEntry<String, String> e in altMap.entries) {
          hediyeByEmail.putIfAbsent(e.key, () => e.value);
        }
      }
    }
    return hediyeByEmail;
  }

  static Future<HediyeDavaLoadResult> loadEffectiveHediyeForDava({
    required String davaId,
    String? davaAdi,
  }) async {
    if (davaId.trim().isEmpty) {
      return const HediyeDavaLoadResult(
        primaryDavaId: '',
        effective: HediyeEffectiveResult(
          hediyeText: null,
          sourceRole: null,
          source: HediyeEffectiveSource.none,
          voteCountsByRole: {},
          votingPeriodClosed: false,
        ),
        hediyeSourceEmail: null,
      );
    }

    String primaryDavaId = davaId;
    final String ad = davaAdi?.trim() ?? '';
    if (ad.isNotEmpty) {
      final String altId = 'dava_${ad.hashCode}';
      final Map<String, String> altOnly =
          await HiveDatabaseService.getMasrafGiftLineMapForDavaId(altId);
      final Map<String, String> mainOnly =
          await HiveDatabaseService.getMasrafGiftLineMapForDavaId(davaId);
      if (mainOnly.isEmpty && altOnly.isNotEmpty) {
        primaryDavaId = altId;
      }
    }

    final List<Map<String, dynamic>> participants =
        await HiveDatabaseService.getDavaParticipants(primaryDavaId);
    final Map<String, String> hediyeByEmail =
        await _mergedHediyeMapForDava(primaryDavaId, davaAdi);
    final Map<String, String> votesByEmail =
        await HiveDatabaseService.getHediyeOyMapForDavaId(primaryDavaId);
    final bool votingOpen = await isVotingPeriodOpen(primaryDavaId);
    final List<String> roleValues =
        EvidenceCommentRole.allRoles.map((r) => r.value).toList();
    final Map<String, String> roleHediyeMap = buildRoleHediyeMap(
      participants: participants,
      hediyeByEmailLower: hediyeByEmail,
      roleValues: roleValues,
    );
    final HediyeEffectiveResult effective = resolveEffectiveHediye(
      roleHediyeMap: roleHediyeMap,
      votesByEmail: votesByEmail,
      votingPeriodClosed: !votingOpen,
      participants: participants,
    );

    String? hediyeEmail = _emailForRole(participants, effective.sourceRole);
    hediyeEmail ??= _emailForRole(participants, effective.judgeFallbackRole);

    return HediyeDavaLoadResult(
      primaryDavaId: primaryDavaId,
      effective: effective,
      hediyeSourceEmail: hediyeEmail,
    );
  }

  /// Onay butonu için kaynak rolün tüm masraf/hediye listesi.
  static Future<List<String>?> loadHediyeListForDava({
    required HediyeDavaLoadResult loadResult,
    required String davaId,
    String? davaAdi,
  }) async {
    final String? email = loadResult.hediyeSourceEmail;
    if (email == null || email.isEmpty) {
      return null;
    }
    List<String>? list = await HiveDatabaseService.getMasrafExpenses(
      davaId: loadResult.primaryDavaId,
      userEmail: email,
    );
    if ((list == null || list.isEmpty) &&
        davaAdi != null &&
        davaAdi.trim().isNotEmpty &&
        loadResult.primaryDavaId != davaId) {
      list = await HiveDatabaseService.getMasrafExpenses(
        davaId: davaId,
        userEmail: email,
      );
    }
    if ((list == null || list.isEmpty) &&
        davaAdi != null &&
        davaAdi.trim().isNotEmpty) {
      final String altId = 'dava_${davaAdi.hashCode}';
      if (altId != loadResult.primaryDavaId && altId != davaId) {
        list = await HiveDatabaseService.getMasrafExpenses(
          davaId: altId,
          userEmail: email,
        );
      }
    }
    return list;
  }
}

class HediyeDavaLoadResult {
  final String primaryDavaId;
  final HediyeEffectiveResult effective;
  final String? hediyeSourceEmail;

  const HediyeDavaLoadResult({
    required this.primaryDavaId,
    required this.effective,
    required this.hediyeSourceEmail,
  });
}

enum HediyeEffectiveSource {
  none,
  halkOyu,
  temyizHakimi,
  yargic,
}

class HediyeEffectiveResult {
  final String? hediyeText;
  final String? sourceRole;
  final HediyeEffectiveSource source;
  final Map<String, int> voteCountsByRole;
  final bool votingPeriodClosed;
  final String? judgeFallbackRole;

  const HediyeEffectiveResult({
    required this.hediyeText,
    required this.sourceRole,
    required this.source,
    required this.voteCountsByRole,
    required this.votingPeriodClosed,
    this.judgeFallbackRole,
  });

  String sourceLabel() {
    switch (source) {
      case HediyeEffectiveSource.halkOyu:
        return 'Halk oyu (çoğunluk)';
      case HediyeEffectiveSource.temyizHakimi:
        return 'Temyiz hakimi (geçici, 19. güne kadar)';
      case HediyeEffectiveSource.yargic:
        return 'Yargıç (geçici, 19. güne kadar)';
      case HediyeEffectiveSource.none:
        return '';
    }
  }
}
