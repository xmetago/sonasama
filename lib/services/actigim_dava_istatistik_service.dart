import '../models/hukum_sentiment.dart';
import 'dava_hukum_eligibility_service.dart';
import 'hive_database_service.dart';

/// Açtığım davalar sayfasındaki dört özet sayaç.
class ActigimDavaIstatistikleri {
  const ActigimDavaIstatistikleri({
    required this.actigim,
    required this.hakliOldugum,
    required this.haksizOldugum,
    required this.banaAcilan,
  });

  const ActigimDavaIstatistikleri.zero()
      : actigim = 0,
        hakliOldugum = 0,
        haksizOldugum = 0,
        banaAcilan = 0;

  final int actigim;
  final int hakliOldugum;
  final int haksizOldugum;
  final int banaAcilan;
}

/// Davacı olarak açtığım / haklı / haksız / bana açılan sayılarını üretir.
class ActigimDavaIstatistikService {
  const ActigimDavaIstatistikService();

  Future<ActigimDavaIstatistikleri> compute(String userEmail) async {
    final email = userEmail.trim();
    if (email.isEmpty) {
      return const ActigimDavaIstatistikleri.zero();
    }

    final davalar = listActigimDavalarForUser(email);
    var hakli = 0;
    var haksiz = 0;

    for (final dava in davalar) {
      final sonuc = await _davaciHakliMi(dava);
      if (sonuc == true) {
        hakli++;
      } else if (sonuc == false) {
        haksiz++;
      }
    }

    final banaAcilan = HiveDatabaseService.countBanaAcilanDavalar(email);

    return ActigimDavaIstatistikleri(
      actigim: davalar.length,
      hakliOldugum: hakli,
      haksizOldugum: haksiz,
      banaAcilan: banaAcilan,
    );
  }

  /// Açtığım davalar listesi: açılan + kayıtlı, davacı eşleşmesiyle filtrelenir.
  static List<Map<String, dynamic>> listActigimDavalarForUser(String userEmail) {
    final normalizedEmail = userEmail.trim().toLowerCase();
    final opened = HiveDatabaseService.getOpenedDavalar();
    final saved = HiveDatabaseService.getSavedDavalar();
    final all = <Map<String, dynamic>>[...opened, ...saved];

    final filtered = normalizedEmail.isEmpty
        ? all
        : all
            .where(
              (Map<String, dynamic> dava) =>
                  isUserPlaintiffInDava(dava, normalizedEmail),
            )
            .toList();

    filtered.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime? aDate = DateTime.tryParse(
        (a['openedAt'] ?? a['createdAt'] ?? '').toString(),
      );
      final DateTime? bDate = DateTime.tryParse(
        (b['openedAt'] ?? b['createdAt'] ?? '').toString(),
      );
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  static bool isUserPlaintiffInDava(
    Map<String, dynamic> dava,
    String normalizedEmail,
  ) {
    final opener =
        (dava['userEmail'] ?? '').toString().trim().toLowerCase();
    if (opener.isNotEmpty && opener == normalizedEmail) {
      return true;
    }

    final davaciEmail =
        (dava['davaciEmail'] ?? '').toString().trim().toLowerCase();
    if (davaciEmail.isNotEmpty && davaciEmail == normalizedEmail) {
      return true;
    }

    final davaciRaw = (dava['davaci'] ?? '').toString().trim();
    if (davaciRaw.isEmpty) return false;

    final davaciLower = davaciRaw.toLowerCase();
    if (davaciLower == normalizedEmail) return true;
    if (davaciRaw.contains('@') && davaciLower == normalizedEmail) {
      return true;
    }

    final user = HiveDatabaseService.getRegistrationByEmail(normalizedEmail);
    if (user != null &&
        user.judgeName.trim().toLowerCase() == davaciLower) {
      return true;
    }

    return false;
  }

  /// Yargıç veya temyiz kararı varsa davacı haklı mı; yoksa null (sayılmaz).
  Future<bool?> _davaciHakliMi(Map<String, dynamic> dava) async {
    final davaId = (dava['id'] ?? dava['davaId'] ?? '').toString();
    if (davaId.isEmpty) return null;

    final olumluOlumsuz = await _resolveKararOlumluOlumsuz(davaId);
    if (olumluOlumsuz == null) return null;

    return olumluOlumsuz.olumlu >= olumluOlumsuz.olumsuz;
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
}
