import '../models/hukum_sentiment.dart';
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

  /// Türkçe rol karşılaştırması için tek katlama.
  ///
  /// Noktalı/noktasız I-i ve ş, ğ, ç, ö, ü (büyük/küçük) ASCII karşılığına iner.
  /// Unicode varsayılan küçük harfin eklediği birleşik nokta da düşer; böylece
  /// `Yargıç` → `yargic` olur.
  static String foldTurkish(String input) {
    final String source = input.replaceAll('\u0307', '');
    final StringBuffer out = StringBuffer();
    for (final int rune in source.runes) {
      switch (rune) {
        case 0x49: // I
        case 0x69: // i
        case 0x130: // İ
        case 0x131: // ı
          out.write('i');
        case 0x53: // S
        case 0x73: // s
        case 0x15E: // Ş
        case 0x15F: // ş
          out.write('s');
        case 0x47: // G
        case 0x67: // g
        case 0x11E: // Ğ
        case 0x11F: // ğ
          out.write('g');
        case 0x43: // C
        case 0x63: // c
        case 0xC7: // Ç
        case 0xE7: // ç
          out.write('c');
        case 0x4F: // O
        case 0x6F: // o
        case 0xD6: // Ö
        case 0xF6: // ö
          out.write('o');
        case 0x55: // U
        case 0x75: // u
        case 0xDC: // Ü
        case 0xFC: // ü
          out.write('u');
        default:
          out.write(String.fromCharCode(rune).toLowerCase());
      }
    }
    return out.toString();
  }

  static String _compactKey(String s) => foldTurkish(s)
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

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

  static HukumSentiment? _sentimentOf(Map<String, dynamic>? hukum) {
    if (hukum == null) return null;
    return hukumSentimentFromStorage(hukum['hukumSentiment']?.toString());
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

    final byRole =
        await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);
    final HukumSentiment? yargic =
        _sentimentOf(_pickHukum(byRole, yargicAliases));

    await HiveDatabaseService.updateOpenedDava(davaId, {
      'appealJudgeFallbackApplied': true,
      'appealJudgeFallbackAt': DateTime.now().toIso8601String(),
      'appealJudgeAssignmentPending': false,
      if (yargic != null) 'appealJudgeFallbackSentiment': yargic.storageValue,
    });
  }

  /// Süre dolunca yazılan yansıma. Temyiz kaydı yoksa yargıç yönüdür; ek oy değildir.
  static HukumSentiment? mirroredAppealSentiment(Map<String, dynamic>? opened) {
    if (opened == null || opened['appealJudgeFallbackApplied'] != true) {
      return null;
    }
    return hukumSentimentFromStorage(
      opened['appealJudgeFallbackSentiment']?.toString(),
    );
  }

  /// Nihai yön: gerçek temyiz, yoksa yansıyan yargıç yönü, o da yoksa yargıç.
  static HukumSentiment? appealOrYargicDirection({
    required String? davaId,
    HukumSentiment? temyiz,
    HukumSentiment? yargic,
  }) {
    if (temyiz != null) return temyiz;
    final String id = davaId?.trim() ?? '';
    if (id.isNotEmpty) {
      final HukumSentiment? mirrored = mirroredAppealSentiment(
        HiveDatabaseService.getOpenedDavaById(id),
      );
      if (mirrored != null) return mirrored;
    }
    return yargic;
  }

  static bool roleLabelIsTemyiz(String davaGorev) {
    final String t = foldTurkish(davaGorev);
    return t.contains('temyiz') && t.contains('hakim');
  }

  static bool roleLabelIsYargic(String davaGorev) {
    final String t = foldTurkish(davaGorev);
    return t.contains('yargic');
  }

  /// 8-Hüküm düzenleme kilidi. Açılış tarihi yoksa süre kuralları atlanmaz.
  static HukumRoleEditLock evaluateRoleEditLock({
    required String gorev,
    required DateTime? openedAt,
    required DateTime now,
    required bool appealWindowActive,
    required bool sixPanelFinalized,
  }) {
    if (openedAt == null) {
      return const HukumRoleEditLock.locked(
        'Dava açılış tarihi bulunamadı. Süre doğrulanamadığı için düzenleme kilitli.',
      );
    }

    final bool mainEnded = isMainTrialEnded(openedAt, now);
    final bool appealEditingAllowed = appealWindowActive && mainEnded;
    final bool isTemyiz = roleLabelIsTemyiz(gorev);
    final bool isYargic = roleLabelIsYargic(gorev);

    if (appealEditingAllowed) {
      if (!isTemyiz) {
        return const HukumRoleEditLock.locked(
          'Temyiz süreci aktif: yalnızca Temyiz Hakimi hüküm düzenleyebilir.',
        );
      }
      return const HukumRoleEditLock.unlocked();
    }

    if (isTemyiz) {
      return const HukumRoleEditLock.locked(
        'Temyiz hükmü; 7 gün sonrası temyiz talebinden sonra 72 saatlik süre içinde açılır.',
      );
    }

    if (isYargic) {
      final bool past144 =
          now.difference(openedAt) >= const Duration(hours: 144);
      if (!past144 && !sixPanelFinalized) {
        return const HukumRoleEditLock.locked(
          'Yargıç: Altı rol (jüri, avukatlar, şahitler) hükmünü tamamlayana veya 144. saat dolana kadar bekleyin.',
        );
      }
    } else if (mainEnded) {
      return const HukumRoleEditLock.locked(
        'Ana dava süresi (168 saat) tamamlandı; hüküm metni artık güncellenemez.',
      );
    }

    return const HukumRoleEditLock.unlocked();
  }
}

/// Rol düzenleme kilidinin sonucu.
class HukumRoleEditLock {
  const HukumRoleEditLock.unlocked()
      : locked = false,
        reason = null;

  const HukumRoleEditLock.locked(this.reason) : locked = true;

  final bool locked;
  final String? reason;
}
