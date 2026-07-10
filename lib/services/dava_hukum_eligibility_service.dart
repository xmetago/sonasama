import 'hive_database_service.dart';
import 'dava_timer_service.dart';

/// Altı pano rolü + yargıç erken hüküm + temyiz penceresi kuralları.
class DavaHukumEligibilityService {
  DavaHukumEligibilityService._();

  /// Yargıç / Temyiz dışı altı rol (jüri, avukatlar, şahitler) — hükmü tamamlanınca yargıç beklemeden karar verebilir.
  static const List<List<String>> sixPanelRoleAliases = [
    ['1. Jüri Kararı', '1.Jüri Kararı', '1. Juri Kararı'],
    ['2. Jüri Kararı', '2.Jüri Kararı', '2. Juri Kararı'],
    ['Davacı Avukatı Kararı', 'Davacı avukatı Kararı'],
    ['Davalı Avukatı Kararı', 'Davalı avukatı Kararı'],
    ['Davacı Şahidi Kararı', 'Davacı Şahidi Kararı'],
    ['Davalı Şahidi Kararı', 'Davalı Şahidi Kararı'],
  ];

  static const List<String> yargicAliases = [
    'Yargıç Kararı',
    'Yargic Kararı',
  ];

  static const List<String> temyizHukumAliases = [
    'Temyiz Hakimi Kararı',
    'Temyiz hakimi Kararı',
  ];

  static String _compactKey(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), '').replaceAll('ı', 'i');

  static Map<String, dynamic>? _pickHukum(
    Map<String, Map<String, dynamic>> byRole,
    List<String> aliases,
  ) {
    for (final alias in aliases) {
      if (byRole.containsKey(alias)) {
        return byRole[alias];
      }
    }
    final target = aliases.map(_compactKey).toSet();
    for (final e in byRole.entries) {
      if (target.contains(_compactKey(e.key))) {
        return e.value;
      }
    }
    return null;
  }

  static bool _hukumKaydiTamam(Map<String, dynamic>? h) {
    if (h == null) return false;
    final text = (h['hukumText'] ?? '').toString().trim();
    if (text.isEmpty) return false;
    final fin = h['isFinalized'] == true;
    final sent = (h['hukumSentiment'] ?? '').toString().trim();
    return fin && sent.isNotEmpty;
  }

  /// Altı pano rolünün tamamı nihai hüküm vermiş mi?
  static Future<bool> hasSixPanelFinalized(String davaId) async {
    if (davaId.isEmpty) return false;
    final byRole =
        await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);
    for (final aliases in sixPanelRoleAliases) {
      if (!_hukumKaydiTamam(_pickHukum(byRole, aliases))) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> hasYargicFinalized(String davaId) async {
    if (davaId.isEmpty) return false;
    final byRole =
        await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);
    return _hukumKaydiTamam(_pickHukum(byRole, yargicAliases));
  }

  static Future<bool> hasTemyizHukumFinalized(String davaId) async {
    if (davaId.isEmpty) return false;
    final byRole =
        await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);
    return _hukumKaydiTamam(_pickHukum(byRole, temyizHukumAliases));
  }

  /// Yargıç, 144. saat dolmadan hüküm verebilir mi? (6 rol tamam)
  static Future<bool> canYargicRuleEarly(String davaId) async {
    return hasSixPanelFinalized(davaId);
  }

  /// Temyiz talebinden sonra 72 saatlik aktif pencere.
  static bool isAppealJudgeWindowActive(Map<String, dynamic>? opened) {
    if (opened == null || opened['isAppealable'] != true) return false;
    final at =
        DateTime.tryParse(opened['appealRequestedAt']?.toString() ?? '');
    if (at == null) return false;
    final end = at.add(DavaTimerService.appealJudgeDecisionWindow);
    return DateTime.now().isBefore(end);
  }

  /// 168 saat ana süreç bitti mi?
  static bool isMainTrialEnded(DateTime? openedAt, DateTime now) {
    if (openedAt == null) return false;
    return now.difference(openedAt) >= DavaTimerService.mainTrialWindow;
  }

  /// Temyiz süresi doldu; hüküm yoksa yargıç ile aynı yönde sayılır (çifte oy yok).
  static Future<void> ensureAppealJudgeFallback(String davaId) async {
    if (davaId.isEmpty) return;
    final opened = HiveDatabaseService.getOpenedDavaById(davaId);
    if (opened == null || opened['isAppealable'] != true) return;
    if (opened['appealJudgeFallbackApplied'] == true) return;

    final requestedAt =
        DateTime.tryParse(opened['appealRequestedAt']?.toString() ?? '');
    if (requestedAt == null) return;

    final deadline =
        requestedAt.add(DavaTimerService.appealJudgeDecisionWindow);
    if (!DateTime.now().isAfter(deadline)) return;

    if (await hasTemyizHukumFinalized(davaId)) return;

    await HiveDatabaseService.updateOpenedDava(davaId, {
      'appealJudgeFallbackApplied': true,
      'appealJudgeFallbackAt': DateTime.now().toIso8601String(),
      'appealJudgeAssignmentPending': false,
    });
  }

  static bool roleLabelIsTemyiz(String davaGorev) {
    final t = davaGorev.toLowerCase();
    return t.contains('temyiz') && t.contains('hakim');
  }

  static bool roleLabelIsYargic(String davaGorev) {
    final t = davaGorev.toLowerCase().replaceAll('ı', 'i');
    return t.contains('yargic') || t.contains('yargıç');
  }
}
