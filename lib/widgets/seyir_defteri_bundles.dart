part of 'ilgililerin_seyir_defteri_widgeti.dart';

class _EngagementCellConfig {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final bool showCount;
  final bool alwaysShowCount;

  const _EngagementCellConfig({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.showCount = true,
    this.alwaysShowCount = false,
  });
}

class _DelillerHakkindaBundle {
  final List<EvidenceModel> evidences;
  final List<EvidenceCommentModel> comments;

  const _DelillerHakkindaBundle({
    required this.evidences,
    required this.comments,
  });
}

class _UygunCezalarBundle {
  final List<Map<String, dynamic>> participants;
  final Map<String, String> cezaByEmailLower;
  final Map<String, String> votesByEmail;
  final Map<String, String> roleCezaMap;
  final CezaEffectiveResult effective;
  final bool votingOpen;

  const _UygunCezalarBundle({
    required this.participants,
    required this.cezaByEmailLower,
    required this.votesByEmail,
    required this.roleCezaMap,
    required this.effective,
    required this.votingOpen,
  });
}

class _HediyelerBundle {
  final List<Map<String, dynamic>> participants;
  final Map<String, String> hediyeSatirByEmailLower;
  final Map<String, String> votesByEmail;
  final Map<String, String> roleHediyeMap;
  final HediyeEffectiveResult effective;
  final bool votingOpen;

  const _HediyelerBundle({
    required this.participants,
    required this.hediyeSatirByEmailLower,
    required this.votesByEmail,
    required this.roleHediyeMap,
    required this.effective,
    required this.votingOpen,
  });
}