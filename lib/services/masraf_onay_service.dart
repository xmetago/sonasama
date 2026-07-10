import 'dart:async';

import 'package:hive/hive.dart';

import 'hive_database_service.dart';
import 'user_star_balance_store.dart';

/// "Masrafları Onayla" + "Whobooma'a Ödensin" + 19 günlük Masraf/Uyar
/// akışlarının tek noktadan yönetildiği servis.
///
/// Tüm karar mantığı KURAL SETİ ile birebir aynıdır:
///
/// | Durum | Davacı | Davalı Üye? | Buton              | Basan  | Yıldız etkisi                                  |
/// |-------|--------|-------------|--------------------|--------|------------------------------------------------|
/// | 1     | Haklı  | Evet        | Masrafları Onayla  | Davalı | Davacı +Yeşil · Davalı −Sarı, −Yeşil           |
/// | 2     | Haklı  | Hayır       | Whobooma'a Ödensin | Davacı | Davacı +Yeşil · Davalı yok (üye değil)         |
/// | 3     | Haksız | Evet        | Masrafları Onayla  | Davacı | Davacı −Sarı, −Yeşil · Davalı +Yeşil           |
/// | 4     | Haksız | Hayır       | Masrafları Onayla  | Davacı | Davacı −Sarı, −Yeşil · Davalı yok (üye değil)  |
///
/// Sayfa görünürlüğü (KURAL SETİ — Bölüm 5):
///
/// | Durum | Açtığım (Davacı) sayfası           | Katıldığım (Davalı) sayfası   |
/// |-------|-------------------------------------|--------------------------------|
/// | 1     | MASRAF/UYAR                         | Masrafları Onayla              |
/// | 2     | WHOBOOMA'A ÖDENSİN                  | (Davalı üye değil)             |
/// | 3     | Masrafları Onayla                   | MASRAF/UYAR                    |
/// | 4     | Masrafları Onayla                   | (Davalı üye değil)             |
class MasrafOnayService {
  MasrafOnayService._();

  /// "Masrafları Onayla" işleminin kalıcı durum kutusu.
  static const String _boxName = 'masraf_onay_box_v1';
  static Box<dynamic>? _box;

  /// Bir tarafın masraf onaylaması karşılığı düşen sarı yıldız (sabit).
  static const int yellowStarCost = 1;

  /// Bir tarafın masraf onaylaması karşılığı düşen / kazanılan yeşil yıldız.
  static const int greenStarDelta = 1;

  /// 19 günlük masraf uyarı cooldown'u.
  static const Duration uyariCooldown = Duration(days: 19);

  // ───────────────── Hive kurulumu ─────────────────

  static Future<Box<dynamic>> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<dynamic>(_boxName);
    } else {
      _box = Hive.box<dynamic>(_boxName);
    }
    return _box!;
  }

  static String _stateKey(String davaId) => 'state:$davaId';
  static String _uyariKey(String davaId) => 'uyari:$davaId';

  // ───────────────── Üyelik kontrolü ─────────────────

  /// Davacı her zaman üye kabul edilir (KURAL 0).
  static bool isDavaciUye(String davaciJudgeName) => true;

  /// Davalının sistemde kaydı varsa üyedir.
  static bool isDavaliUye(String davaliJudgeName) {
    if (davaliJudgeName.trim().isEmpty) return false;
    final reg = HiveDatabaseService.getRegistrationByJudgeName(davaliJudgeName);
    return reg != null;
  }

  /// Davalının kayıtlı e-posta adresini döndürür (üye değilse null).
  static String? davaliEmail(String davaliJudgeName) {
    final reg = HiveDatabaseService.getRegistrationByJudgeName(davaliJudgeName);
    return reg?.email;
  }

  /// Davacının kayıtlı e-posta adresini döndürür.
  static String? davaciEmail(String davaciJudgeName) {
    final reg = HiveDatabaseService.getRegistrationByJudgeName(davaciJudgeName);
    return reg?.email;
  }

  // ───────────────── Karar matrisi ─────────────────

  /// KURAL SETİ Section 3'teki tabloyu birebir uygulayan tek kapı.
  static MasrafOnayDecision decide({
    required bool davaciHakli,
    required String davaciJudgeName,
    required String davaliJudgeName,
  }) {
    final bool davaliUye = isDavaliUye(davaliJudgeName);

    // Haksız taraf = davacı haklıysa davalı, değilse davacı.
    final MasrafTaraf haksizTaraf =
        davaciHakli ? MasrafTaraf.davali : MasrafTaraf.davaci;

    final bool haksizUye = haksizTaraf == MasrafTaraf.davaci
        ? true // Davacı her zaman üyedir.
        : davaliUye;

    // Durum numarasını belirle.
    final MasrafDurum durum;
    if (davaciHakli && davaliUye) {
      durum = MasrafDurum.durum1;
    } else if (davaciHakli && !davaliUye) {
      durum = MasrafDurum.durum2;
    } else if (!davaciHakli && davaliUye) {
      durum = MasrafDurum.durum3;
    } else {
      durum = MasrafDurum.durum4;
    }

    // Hangi buton gösterilir?
    final MasrafButtonType buttonType = durum == MasrafDurum.durum2
        ? MasrafButtonType.whoboomaOdensin
        : MasrafButtonType.masraflarOnayla;

    // Butona kim basar?
    // - Durum 1: Haksız (Davalı, üye)
    // - Durum 2: Haklı (Davacı) — Whobooma butonu
    // - Durum 3: Haksız (Davacı, üye)
    // - Durum 4: Haksız (Davacı, üye)
    final MasrafTaraf basanTaraf;
    switch (durum) {
      case MasrafDurum.durum1:
        basanTaraf = MasrafTaraf.davali;
        break;
      case MasrafDurum.durum2:
        basanTaraf = MasrafTaraf.davaci;
        break;
      case MasrafDurum.durum3:
      case MasrafDurum.durum4:
        basanTaraf = MasrafTaraf.davaci;
        break;
    }

    return MasrafOnayDecision(
      durum: durum,
      davaciHakli: davaciHakli,
      davaliUye: davaliUye,
      haksizTaraf: haksizTaraf,
      haksizUye: haksizUye,
      buttonType: buttonType,
      basanTaraf: basanTaraf,
      davaciJudgeName: davaciJudgeName,
      davaliJudgeName: davaliJudgeName,
    );
  }

  // ───────────────── Onay durumu (idempotent) ─────────────────

  static Future<bool> isMasrafOnaylandi(String davaId) async {
    final box = await _ensureBox();
    final data = box.get(_stateKey(davaId));
    if (data is Map) {
      return data['onaylandi'] == true;
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getMasrafState(String davaId) async {
    final box = await _ensureBox();
    final data = box.get(_stateKey(davaId));
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> _persistState(
    String davaId,
    Map<String, dynamic> state,
  ) async {
    final box = await _ensureBox();
    await box.put(_stateKey(davaId), state);
  }

  // ───────────────── Asıl onay işlemi ─────────────────

  /// "Masrafları Onayla" butonuna basılırsa çağrılır.
  ///
  /// KURAL 1'e göre yıldız transferi yapar.
  /// Eğer haksız tarafın sarı yıldızı yetersizse [InsufficientYellowStarException]
  /// fırlatır — UI tarafının satın alma dialog'u açması beklenir.
  static Future<MasrafOnayResult> onaylaMasraf({
    required String davaId,
    required MasrafOnayDecision decision,
  }) async {
    if (decision.buttonType != MasrafButtonType.masraflarOnayla) {
      throw StateError(
        'onaylaMasraf yalnızca "Masrafları Onayla" butonu için çağrılır.',
      );
    }

    if (await isMasrafOnaylandi(davaId)) {
      return const MasrafOnayResult.alreadyApproved();
    }

    final String? davaciMail = davaciEmail(decision.davaciJudgeName);
    final String? davaliMail = davaliEmail(decision.davaliJudgeName);

    int? yeniHaksizSari;
    int? yeniHaksizYesil;
    int? yeniHakliYesil;

    switch (decision.durum) {
      case MasrafDurum.durum1:
        // Davalı (üye, haksız) → −Sarı, −Yeşil
        // Davacı (haklı) → +Yeşil
        if (davaliMail == null) {
          throw StateError('Davalı üye fakat e-posta bulunamadı.');
        }
        final spent = await UserStarBalanceStore.trySpendYellowStars(
          davaliMail,
          yellowStarCost,
        );
        if (!spent) {
          throw InsufficientYellowStarException(
            email: davaliMail,
            judgeName: decision.davaliJudgeName,
            required: yellowStarCost,
            current: await UserStarBalanceStore.getYellowStars(davaliMail),
          );
        }
        await UserStarBalanceStore.spendGreenStars(davaliMail, greenStarDelta);
        if (davaciMail != null) {
          await UserStarBalanceStore.addGreenStars(davaciMail, greenStarDelta);
        }
        yeniHaksizSari = await UserStarBalanceStore.getYellowStars(davaliMail);
        yeniHaksizYesil = await UserStarBalanceStore.getGreenStars(davaliMail);
        if (davaciMail != null) {
          yeniHakliYesil = await UserStarBalanceStore.getGreenStars(davaciMail);
        }
        break;

      case MasrafDurum.durum3:
        // Davacı (üye, haksız) → −Sarı, −Yeşil
        // Davalı (üye, haklı) → +Yeşil
        if (davaciMail == null) {
          throw StateError('Davacı kaydı bulunamadı.');
        }
        final spent = await UserStarBalanceStore.trySpendYellowStars(
          davaciMail,
          yellowStarCost,
        );
        if (!spent) {
          throw InsufficientYellowStarException(
            email: davaciMail,
            judgeName: decision.davaciJudgeName,
            required: yellowStarCost,
            current: await UserStarBalanceStore.getYellowStars(davaciMail),
          );
        }
        await UserStarBalanceStore.spendGreenStars(davaciMail, greenStarDelta);
        if (davaliMail != null) {
          await UserStarBalanceStore.addGreenStars(davaliMail, greenStarDelta);
        }
        yeniHaksizSari = await UserStarBalanceStore.getYellowStars(davaciMail);
        yeniHaksizYesil = await UserStarBalanceStore.getGreenStars(davaciMail);
        if (davaliMail != null) {
          yeniHakliYesil = await UserStarBalanceStore.getGreenStars(davaliMail);
        }
        break;

      case MasrafDurum.durum4:
        // Davacı (üye, haksız) → −Sarı, −Yeşil
        // Davalı (üye değil) → etki yok
        if (davaciMail == null) {
          throw StateError('Davacı kaydı bulunamadı.');
        }
        final spent = await UserStarBalanceStore.trySpendYellowStars(
          davaciMail,
          yellowStarCost,
        );
        if (!spent) {
          throw InsufficientYellowStarException(
            email: davaciMail,
            judgeName: decision.davaciJudgeName,
            required: yellowStarCost,
            current: await UserStarBalanceStore.getYellowStars(davaciMail),
          );
        }
        await UserStarBalanceStore.spendGreenStars(davaciMail, greenStarDelta);
        yeniHaksizSari = await UserStarBalanceStore.getYellowStars(davaciMail);
        yeniHaksizYesil = await UserStarBalanceStore.getGreenStars(davaciMail);
        break;

      case MasrafDurum.durum2:
        // Buraya hiç gelinmemeli (Whobooma butonu kullanılır).
        throw StateError('Durum 2 için onaylaWhobooma kullanılmalıdır.');
    }

    await _persistState(davaId, <String, dynamic>{
      'onaylandi': true,
      'durum': decision.durum.name,
      'basan': decision.basanTaraf.name,
      'davaci': decision.davaciJudgeName,
      'davali': decision.davaliJudgeName,
      'davaliUye': decision.davaliUye,
      'onayZamani': DateTime.now().toIso8601String(),
      'tip': 'masraflar_onayla',
    });

    return MasrafOnayResult(
      success: true,
      durum: decision.durum,
      haksizTarafYeniSari: yeniHaksizSari,
      haksizTarafYeniYesil: yeniHaksizYesil,
      hakliTarafYeniYesil: yeniHakliYesil,
    );
  }

  /// "Whobooma'a Ödensin" butonuna basılırsa çağrılır (Durum 2).
  ///
  /// KURAL: Davacı haklı, Davalı üye değil. Davacı sistemde gerçek bir karşı
  /// taraf bulamasa da Whobooma'a ödeme yapmayı kabul ederek "şeref sahibi"
  /// olur → **Davacı'ya +Yeşil yıldız** eklenir. Davalı sistemde yer almadığı
  /// için ondan düşüş yapılmaz (eklenmez de).
  static Future<MasrafOnayResult> onaylaWhobooma({
    required String davaId,
    required MasrafOnayDecision decision,
  }) async {
    if (decision.buttonType != MasrafButtonType.whoboomaOdensin) {
      throw StateError(
        'onaylaWhobooma yalnızca "Whobooma\'a Ödensin" butonu için çağrılır.',
      );
    }

    if (await isMasrafOnaylandi(davaId)) {
      return const MasrafOnayResult.alreadyApproved();
    }

    int? yeniDavaciYesil;
    final String? davaciMail = davaciEmail(decision.davaciJudgeName);
    if (davaciMail != null) {
      await UserStarBalanceStore.addGreenStars(davaciMail, greenStarDelta);
      yeniDavaciYesil = await UserStarBalanceStore.getGreenStars(davaciMail);
    }

    await _persistState(davaId, <String, dynamic>{
      'onaylandi': true,
      'durum': decision.durum.name,
      'basan': decision.basanTaraf.name,
      'davaci': decision.davaciJudgeName,
      'davali': decision.davaliJudgeName,
      'davaliUye': decision.davaliUye,
      'onayZamani': DateTime.now().toIso8601String(),
      'tip': 'whobooma_odensin',
      'hayali': true,
      'davaciYesilDelta': greenStarDelta,
    });

    return MasrafOnayResult(
      success: true,
      durum: decision.durum,
      isHayali: true,
      // Whobooma akışında haklı taraf = Davacı; bu alanı doldurarak UI'ın
      // "yeni yeşil yıldız bakiyeniz" mesajını göstermesini sağlıyoruz.
      hakliTarafYeniYesil: yeniDavaciYesil,
    );
  }

  // ───────────────── 19 günlük Masraf/Uyar butonu ─────────────────

  /// MASRAF/UYAR butonu bu senaryoda anlamlı mı?
  ///
  /// **TEK KURAL**: *Davalı Whoboom üyesi DEĞİLSE buton gösterilmez.*
  ///
  /// Bunun temeli:
  /// - Durum 2 (Davacı haklı, Davalı üye değil) → Davalı sistemde yok, hayali
  ///   bir karakter; uyarılacak kimse yok. Süreç zaten `Whobooma'a Ödensin`
  ///   tek tıkıyla kapanır.
  /// - Durum 4 (Davacı haksız, Davalı üye değil) → uyarıyı *basacak* haklı
  ///   taraf (Davalı) sistemde yok. Buton kimsenin parmağına ulaşmaz.
  ///
  /// Yani davalı üye olmayan tüm senaryolarda uyarı, **ya gönderilebilecek
  /// bir adres bulamadığı için ya da basacak gerçek bir kullanıcı olmadığı
  /// için** anlamsızdır. Tek bir `davaliUye` kontrolü her iki durumu da
  /// karşılar.
  ///
  /// Ek olarak Whobooma butonu görünen senaryoda da uyarı mesajı
  /// ("masrafları onayla, şeref sahibi ol") anlamsızdır → ikinci güvenlik
  /// kapısı olarak buton tipi de elenir (Durum 2 için redundant ama açık).
  static bool gosterMasrafUyar(MasrafOnayDecision decision) {
    // Asıl kural: Davalı üye değilse → buton hiç gösterilmez.
    if (!decision.davaliUye) return false;
    // Whobooma senaryosunda (Durum 2) uyarı mesajı da anlamsız — bu zaten
    // davalıUye=false ile elenir, ama niyet kodu açık olsun.
    if (decision.buttonType == MasrafButtonType.whoboomaOdensin) return false;
    return true;
  }

  /// Haklı taraf masraf uyarısı gönderebilir mi?
  ///
  /// - Masraf zaten onaylanmışsa: hayır.
  /// - Senaryo gereği uyarı anlamsızsa (Durum 2 / haksız üye değil): hayır.
  /// - Son uyarıdan beri 19 gün geçmemişse: hayır.
  /// - İlk kez uyarılıyorsa: evet.
  ///
  /// [decision] verilirse senaryo bazlı (Durum 2 vb.) elemeyi de uygular.
  /// Geri uyumluluk için zorunlu değildir; yalnızca cooldown/onay durumu
  /// gerektiğinde [decision] geçilmeyebilir.
  static Future<MasrafUyarStatus> getMasrafUyarStatus(
    String davaId, {
    MasrafOnayDecision? decision,
  }) async {
    final box = await _ensureBox();
    if (await isMasrafOnaylandi(davaId)) {
      return const MasrafUyarStatus(
        canSend: false,
        reason: MasrafUyarReason.zatenOnaylandi,
      );
    }
    if (decision != null && !gosterMasrafUyar(decision)) {
      return const MasrafUyarStatus(
        canSend: false,
        reason: MasrafUyarReason.davaliUyeDegil,
      );
    }
    final raw = box.get(_uyariKey(davaId));
    DateTime? sonUyari;
    if (raw is Map && raw['sonUyariTarihi'] is String) {
      sonUyari = DateTime.tryParse(raw['sonUyariTarihi'] as String);
    }
    if (sonUyari == null) {
      return const MasrafUyarStatus(canSend: true);
    }
    final fark = DateTime.now().difference(sonUyari);
    if (fark >= uyariCooldown) {
      return MasrafUyarStatus(canSend: true, sonUyari: sonUyari);
    }
    final kalan = uyariCooldown - fark;
    return MasrafUyarStatus(
      canSend: false,
      reason: MasrafUyarReason.cooldownActive,
      sonUyari: sonUyari,
      kalanSure: kalan,
    );
  }

  /// Uyarı kaydı yapar (19 günlük cooldown başlatır) ve mesajı döndürür.
  ///
  /// Mesaj kalıbı: "masrafları onayla, şeref sahibi ol" + dava adı.
  static Future<MasrafUyarSendResult> sendMasrafUyar({
    required String davaId,
    required String davaAdi,
    required MasrafOnayDecision decision,
  }) async {
    // Senaryo bazlı eleme: Davalı üye değilse → uyarı gönderilemez. Bu çağrı
    // UI dışı bir yerden (test, CLI, otomasyon) gelse bile düşmeli.
    if (!gosterMasrafUyar(decision)) {
      return const MasrafUyarSendResult(
        success: false,
        status: MasrafUyarStatus(
          canSend: false,
          reason: MasrafUyarReason.davaliUyeDegil,
        ),
      );
    }

    final status = await getMasrafUyarStatus(davaId, decision: decision);
    if (!status.canSend) {
      return MasrafUyarSendResult(success: false, status: status);
    }
    final box = await _ensureBox();
    final now = DateTime.now();
    final List<String> gecmis = <String>[];
    final existing = box.get(_uyariKey(davaId));
    if (existing is Map && existing['gecmis'] is List) {
      gecmis.addAll((existing['gecmis'] as List).map((e) => e.toString()));
    }
    gecmis.add(now.toIso8601String());
    await box.put(_uyariKey(davaId), <String, dynamic>{
      'davaId': davaId,
      'davaAdi': davaAdi,
      'sonUyariTarihi': now.toIso8601String(),
      'gecmis': gecmis,
    });

    final message = '"$davaAdi" davasında masrafları onayla, şeref sahibi ol.';

    return MasrafUyarSendResult(
      success: true,
      status: MasrafUyarStatus(
        canSend: false,
        sonUyari: now,
        reason: MasrafUyarReason.cooldownActive,
        kalanSure: uyariCooldown,
      ),
      message: message,
    );
  }

  /// Belirli bir kullanıcının (e-posta) bu davadaki onay butonunu basabilme
  /// yetkisi var mı? — KURAL 3'teki "Kim basar?" sütununa göre kontrol eder.
  static bool canUserPressButton({
    required MasrafOnayDecision decision,
    required String? userEmail,
    required String? userJudgeName,
  }) {
    if (userEmail == null && userJudgeName == null) return false;

    final String targetName = decision.basanTaraf == MasrafTaraf.davaci
        ? decision.davaciJudgeName
        : decision.davaliJudgeName;

    if (targetName.isEmpty) return false;

    if (userJudgeName != null && userJudgeName.trim().isNotEmpty) {
      if (userJudgeName.trim().toLowerCase() ==
          targetName.trim().toLowerCase()) {
        return true;
      }
    }
    if (userEmail != null && userEmail.trim().isNotEmpty) {
      final reg = HiveDatabaseService.getRegistrationByEmail(userEmail);
      if (reg != null &&
          reg.judgeName.trim().toLowerCase() ==
              targetName.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  /// Haklı tarafın 19 günlük uyarı butonunu basabilme yetkisi.
  ///
  /// Yetki için sıralı kontroller:
  ///   1. Davalı Whoboom üyesi mi? (KURAL: değilse her zaman `false`)
  ///   2. Login user bilgisi var mı?
  ///   3. Login user gerçekten haklı taraf mı?
  static bool canUserSendUyari({
    required MasrafOnayDecision decision,
    required String? userEmail,
    required String? userJudgeName,
  }) {
    // KURAL SETİ: Davalı üye değilse uyarılacak kimse yok — yetki yok.
    if (!gosterMasrafUyar(decision)) return false;

    if (userEmail == null && userJudgeName == null) return false;

    // Haklı taraf = haksızın tersi.
    final MasrafTaraf hakliTaraf = decision.haksizTaraf == MasrafTaraf.davaci
        ? MasrafTaraf.davali
        : MasrafTaraf.davaci;

    final String targetName = hakliTaraf == MasrafTaraf.davaci
        ? decision.davaciJudgeName
        : decision.davaliJudgeName;

    if (targetName.isEmpty) return false;

    if (userJudgeName != null &&
        userJudgeName.trim().toLowerCase() ==
            targetName.trim().toLowerCase()) {
      return true;
    }
    if (userEmail != null) {
      final reg = HiveDatabaseService.getRegistrationByEmail(userEmail);
      if (reg != null &&
          reg.judgeName.trim().toLowerCase() ==
              targetName.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }
}

// ───────────────── Yardımcı tipler ─────────────────

enum MasrafDurum { durum1, durum2, durum3, durum4 }

enum MasrafTaraf { davaci, davali }

enum MasrafButtonType { masraflarOnayla, whoboomaOdensin }

class MasrafOnayDecision {
  const MasrafOnayDecision({
    required this.durum,
    required this.davaciHakli,
    required this.davaliUye,
    required this.haksizTaraf,
    required this.haksizUye,
    required this.buttonType,
    required this.basanTaraf,
    required this.davaciJudgeName,
    required this.davaliJudgeName,
  });

  final MasrafDurum durum;
  final bool davaciHakli;
  final bool davaliUye;
  final MasrafTaraf haksizTaraf;
  final bool haksizUye;
  final MasrafButtonType buttonType;
  final MasrafTaraf basanTaraf;
  final String davaciJudgeName;
  final String davaliJudgeName;

  bool get isWhobooma => buttonType == MasrafButtonType.whoboomaOdensin;
  bool get isMasraflarOnayla =>
      buttonType == MasrafButtonType.masraflarOnayla;

  String get durumOzeti {
    final hakli =
        haksizTaraf == MasrafTaraf.davaci ? 'Davalı haklı' : 'Davacı haklı';
    final uye = davaliUye ? 'Davalı üye' : 'Davalı üye değil';
    return '${durum.name.toUpperCase()} — $hakli, $uye';
  }
}

class MasrafOnayResult {
  const MasrafOnayResult({
    required this.success,
    this.durum,
    this.haksizTarafYeniSari,
    this.haksizTarafYeniYesil,
    this.hakliTarafYeniYesil,
    this.isHayali = false,
    this.alreadyApproved = false,
  });

  const MasrafOnayResult.alreadyApproved()
      : success = true,
        durum = null,
        haksizTarafYeniSari = null,
        haksizTarafYeniYesil = null,
        hakliTarafYeniYesil = null,
        isHayali = false,
        alreadyApproved = true;

  final bool success;
  final MasrafDurum? durum;
  final int? haksizTarafYeniSari;
  final int? haksizTarafYeniYesil;
  final int? hakliTarafYeniYesil;
  final bool isHayali;
  final bool alreadyApproved;
}

class InsufficientYellowStarException implements Exception {
  InsufficientYellowStarException({
    required this.email,
    required this.judgeName,
    required this.required,
    required this.current,
  });

  final String email;
  final String judgeName;
  final int required;
  final int current;

  int get eksik => required - current;

  @override
  String toString() =>
      'InsufficientYellowStarException(judgeName=$judgeName, current=$current, required=$required)';
}

enum MasrafUyarReason {
  zatenOnaylandi,
  cooldownActive,

  /// Davalı Whoboom üyesi değil → uyarı gönderilemez.
  ///
  /// Hem Durum 2 (Davalı haksız, üye değil → bildirim alacak hesap yok) hem
  /// Durum 4 (Davalı haklı, üye değil → uyaracak gerçek kullanıcı yok) bu
  /// sebep altında elenir.
  davaliUyeDegil,
}

class MasrafUyarStatus {
  const MasrafUyarStatus({
    required this.canSend,
    this.reason,
    this.sonUyari,
    this.kalanSure,
  });

  final bool canSend;
  final MasrafUyarReason? reason;
  final DateTime? sonUyari;
  final Duration? kalanSure;

  String? get kalanLabel {
    final d = kalanSure;
    if (d == null) return null;
    if (d.inDays > 0) return '${d.inDays} gün';
    if (d.inHours > 0) return '${d.inHours} saat';
    if (d.inMinutes > 0) return '${d.inMinutes} dakika';
    return 'az sonra';
  }
}

class MasrafUyarSendResult {
  const MasrafUyarSendResult({
    required this.success,
    required this.status,
    this.message,
  });

  final bool success;
  final MasrafUyarStatus status;
  final String? message;
}
