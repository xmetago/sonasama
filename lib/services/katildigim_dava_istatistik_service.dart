import '../models/hukum_sentiment.dart';
import 'dava_hukum_eligibility_service.dart';
import 'hive_database_service.dart';

/// Katıldığım davalar sayfasındaki dört özet sayaç.
class KatildigimDavaIstatistikleri {
  const KatildigimDavaIstatistikleri({
    required this.katildigim,
    required this.hakliOldugum,
    required this.haksizOldugum,
    required this.banaAcilan,
  });

  const KatildigimDavaIstatistikleri.zero()
      : katildigim = 0,
        hakliOldugum = 0,
        haksizOldugum = 0,
        banaAcilan = 0;

  final int katildigim;
  final int hakliOldugum;
  final int haksizOldugum;
  final int banaAcilan;
}

/// Katıldığım / haklı / haksız / bana açılan sayılarını Hive verisinden üretir.
class KatildigimDavaIstatistikService {
  const KatildigimDavaIstatistikService();

  Future<KatildigimDavaIstatistikleri> compute(String userEmail) async {
    final email = userEmail.trim();
    if (email.isEmpty) {
      return const KatildigimDavaIstatistikleri.zero();
    }

    final kayitlar = await HiveDatabaseService.getSekizRolKatilimKayitlari(email);
    var hakli = 0;
    var haksiz = 0;

    for (final kayit in kayitlar) {
      final sonuc = await _kullaniciHakliMi(kayit);
      if (sonuc == true) {
        hakli++;
      } else if (sonuc == false) {
        haksiz++;
      }
    }

    final banaAcilan = HiveDatabaseService.countBanaAcilanDavalar(email);

    return KatildigimDavaIstatistikleri(
      katildigim: kayitlar.length,
      hakliOldugum: hakli,
      haksizOldugum: haksiz,
      banaAcilan: banaAcilan,
    );
  }

  /// Yargıç veya temyiz kararı varsa olumlu/olumsuz; yoksa null (sayılmaz).
  Future<bool?> _kullaniciHakliMi(Map<String, dynamic> kayit) async {
    final davaId = (kayit['davaId'] ?? kayit['id'] ?? '').toString();
    if (davaId.isEmpty) return null;

    final mevkii =
        (kayit['mevkii'] ?? kayit['userRole'] ?? '').toString().trim();
    if (!_isDavaciOrDavaliTarafRolu(mevkii)) {
      return null;
    }

    final olumluOlumsuz = await _resolveKararOlumluOlumsuz(davaId);
    if (olumluOlumsuz == null) return null;

    final davaciHakli = olumluOlumsuz.olumlu >= olumluOlumsuz.olumsuz;
    final davaciTarafi = _isDavaciTarafRolu(mevkii);
    if (davaciTarafi) {
      return davaciHakli;
    }
    return !davaciHakli;
  }

  Future<({int olumlu, int olumsuz})?> _resolveKararOlumluOlumsuz(
    String davaId,
  ) async {
    await DavaHukumEligibilityService.ensureAppealJudgeFallback(davaId);

    final opened = HiveDatabaseService.getOpenedDavaById(davaId);
    final temyizeGitti = opened?['isAppealable'] == true;
    final temyizVar =
        await DavaHukumEligibilityService.hasTemyizHukumFinalized(davaId);

    if (temyizeGitti || temyizVar) {
      final temyiz = await HiveDatabaseService.getHukumByDavaIdAndRole(
        davaId,
        'Temyiz Hakimi Kararı',
        davaAdi: opened?['adi']?.toString(),
      );
      final sayim = _olumluOlumsuzFromHukum(temyiz);
      if (sayim != null) return sayim;
    }

    final yargicVar =
        await DavaHukumEligibilityService.hasYargicFinalized(davaId);
    if (!yargicVar) return null;

    final yargic = await HiveDatabaseService.getHukumByDavaIdAndRole(
      davaId,
      'Yargıç Kararı',
      davaAdi: opened?['adi']?.toString(),
    );
    return _olumluOlumsuzFromHukum(yargic);
  }

  ({int olumlu, int olumsuz})? _olumluOlumsuzFromHukum(
    Map<String, dynamic>? hukum,
  ) {
    if (hukum == null) return null;
    final text = (hukum['hukumText'] ?? '').toString().trim();
    if (text.isEmpty) return null;
    final finalized = hukum['isFinalized'] == true;
    if (!finalized) return null;

    final sentiment =
        hukumSentimentFromStorage(hukum['hukumSentiment']?.toString());
    if (sentiment == HukumSentiment.positive) {
      return (olumlu: 1, olumsuz: 0);
    }
    if (sentiment == HukumSentiment.negative) {
      return (olumlu: 0, olumsuz: 1);
    }
    return null;
  }

  bool _isDavaciOrDavaliTarafRolu(String mevkii) {
    return _isDavaciTarafRolu(mevkii) || _isDavaliTarafRolu(mevkii);
  }

  bool _isDavaciTarafRolu(String mevkii) {
    final c = _compactRole(mevkii);
    return c.contains('davaci');
  }

  bool _isDavaliTarafRolu(String mevkii) {
    final c = _compactRole(mevkii);
    return c.contains('davali');
  }

  static String _compactRole(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u');
  }
}
