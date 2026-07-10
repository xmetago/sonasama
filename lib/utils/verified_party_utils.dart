import '../services/hive_database_service.dart';
import '../services/verified_users_service.dart';

/// Davacı/davalı görünen ad veya e-postayı yargıç adına çevirir.
class VerifiedPartyUtils {
  static String resolveToJudgeName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.contains('@')) {
      if (trimmed == 'Gizli Yargıç') return '';
      return trimmed;
    }
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(trimmed);
      return user?.judgeName ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool canUserOpenCaseAgainst({
    required String openerPartyDisplay,
    required String defendantPartyDisplay,
  }) {
    return VerifiedUsersService.canOpenCaseAgainst(
      openerJudgeName: resolveToJudgeName(openerPartyDisplay),
      defendantJudgeName: resolveToJudgeName(defendantPartyDisplay),
    );
  }
}
