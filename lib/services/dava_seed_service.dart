import '../models/hukum_sentiment.dart';
import 'dava_timer_service.dart';
import 'hive_database_service.dart';

/// Geliştirme ve demo amaçlı veri tohumlama yardımcıları.
class DavaSeedService {
  /// Davacı onay butonları testi — sabit ID'ler.
  ///
  /// KURAL SETİ matrisi:
  /// - Durum 1 → Davacı HAKLI + Davalı ÜYE      → Davalı "Masrafları Onayla" basar.
  /// - Durum 2 → Davacı HAKLI + Davalı ÜYE DEĞİL → Davacı "Whobooma'a Ödensin" basar.
  /// - Durum 3 → Davacı HAKSIZ + Davalı ÜYE      → Davacı "Masrafları Onayla" basar.
  /// - Durum 4 → Davacı HAKSIZ + Davalı ÜYE DEĞİL → Davacı "Masrafları Onayla" basar.
  static const String testOnayDurum1Id = 'test_onay_durum1_hakli_uye';
  static const String testOnayDurum2Id = 'test_onay_durum2_hakli_uyesiz';
  static const String testOnayDurum3Id = 'test_onay_durum3_haksiz_uye';
  static const String testOnayDurum4Id = 'test_onay_durum4_haksiz_uyesiz';

  /// Geriye dönük uyumluluk için eski sabit ID'ler (eski test verisi silinirken
  /// kullanılır).
  static const String testOnayDavaciHakliId = 'test_onay_davaci_hakli';
  static const String testOnayDavaciHaksizId = 'test_onay_davaci_haksiz';
  static const String testOnayYargicEmail = 'onay.test.yargic@its19.local';

  /// Davalı ÜYE olarak kullanılan kayıtlı test hesapları — bu adlar
  /// [HiveDatabaseService.getRegistrationByJudgeName] ile çözülebilmeli.
  /// `main.dart` içindeki seed kullanıcı listesiyle uyumlu seçildi.
  static const String _uyeDavaliDurum1 = 'Canan Yargıç';
  static const String _uyeDavaliDurum3 = 'Fatih Yargıç';
  static const String _uyesizDavaliDurum2 = 'Üyesiz Davalı 2 (Durum 2)';
  static const String _uyesizDavaliDurum4 = 'Üyesiz Davalı 4 (Durum 4)';

  static const String _testCezaText = '🏛️ Test cezası — 3 gün susturma';
  static const List<String> _testHediyeMasrafSatirlari = <String>[
    '🎁 Test Çikolata · ⭐ · Yiyecek',
    '🎁 Test Çiçek · ⭐ · Hediye',
  ];
  /// Kabul edilen ve süre aşımına uğramış örnek bir dava oluşturur.
  ///
  /// Dönen veri:
  /// - `davaId`
  /// - `davaAdi`
  /// - `acceptedAt`
  static Future<Map<String, dynamic>> seedExpiredAcceptedDava({
    required String userEmail,
    required String judgeName,
    required String mevki,
    String? davaId,
    String? davaAdi,
    String davaci = 'Nasrullah Keskin',
    String davali = 'Örnek Davalı',
    String kategori = 'Genel',
    DateTime? openedAt,
    DateTime? acceptedAt,
  }) async {
    final now = DateTime.now();
    final resolvedDavaId =
        davaId ?? 'dava_expired_${now.millisecondsSinceEpoch}';
    final resolvedDavaAdi =
        (davaAdi ?? 'Vicdani Problemler Davası').trim().isEmpty
            ? 'Vicdani Problemler Davası'
            : (davaAdi ?? 'Vicdani Problemler Davası').trim();

    final resolvedAcceptedAt = acceptedAt ??
        now.subtract(
          DavaTimerService.acceptedHukumWindow + const Duration(hours: 4),
        );
    final resolvedOpenedAt = openedAt ??
        resolvedAcceptedAt.subtract(const Duration(hours: 24));

    final openedDavaRecord = {
      'id': resolvedDavaId,
      'davaAdi': resolvedDavaAdi,
      'adi': resolvedDavaAdi,
      'davaci': davaci,
      'davali': davali,
      'davaKonusu': resolvedDavaAdi,
      'kategori': kategori,
      'davaKategori': kategori,
      'openedAt': resolvedOpenedAt.toIso8601String(),
      'createdAt': resolvedOpenedAt.toIso8601String(),
    };

    HiveDatabaseService.saveOpenedDava(openedDavaRecord);

    final acceptedDavaRecord = {
      'id': 'accepted_${resolvedDavaId}_${now.millisecondsSinceEpoch}',
      'davaId': resolvedDavaId,
      'adi': resolvedDavaAdi,
      'davaAdi': resolvedDavaAdi,
      'davaKonusu': resolvedDavaAdi,
      'davaci': davaci,
      'davali': davali,
      'userEmail': userEmail,
      'userRole': mevki,
      'mevkii': mevki,
      'kalanSure': resolvedAcceptedAt
          .add(DavaTimerService.acceptedHukumWindow)
          .toIso8601String(),
      'profilResmi': 'lib/icons/03_davala_ana_icon.png',
      'status': 'accepted',
      'acceptedAt': resolvedAcceptedAt.toIso8601String(),
      'createdAt': resolvedOpenedAt.toIso8601String(),
      'isActive': true,
    };

    await HiveDatabaseService.saveAcceptedDava(acceptedDavaRecord);

    await HiveDatabaseService.markDavaParticipantStatus(
      davaId: resolvedDavaId,
      userEmail: userEmail,
      status: 'accepted',
      statusAt: resolvedAcceptedAt,
      extra: {
        'displayName': judgeName,
        'mevkii': mevki,
        'userRole': mevki,
        'acceptedAt': resolvedAcceptedAt.toIso8601String(),
      },
      reason: 'seed_expired_demo',
    );

    return {
      'davaId': resolvedDavaId,
      'davaAdi': resolvedDavaAdi,
      'acceptedAt': resolvedAcceptedAt,
    };
  }

  /// Davacı onay butonları testi: KURAL SETİ'ndeki 4 durumun her birini
  /// gösteren 4 ayrı açık dava oluşturur.
  ///
  /// - Durum 1: Davacı HAKLI + Davalı ÜYE       → Davalı `Masrafları Onayla`.
  /// - Durum 2: Davacı HAKLI + Davalı ÜYE DEĞİL  → Davacı `Whobooma'a Ödensin`.
  /// - Durum 3: Davacı HAKSIZ + Davalı ÜYE       → Davacı `Masrafları Onayla`.
  /// - Durum 4: Davacı HAKSIZ + Davalı ÜYE DEĞİL → Davacı `Masrafları Onayla`.
  ///
  /// Login yapan kullanıcı [davaciName] olarak Davacı rolündedir; tüm
  /// senaryolar açtığım davalar (Davacı) sayfasından test edilir. Davalı
  /// üyelik durumu, `Hive`'da kayıtlı judgeName eşleşmesine göre belirlenir
  /// (bkz. [_uyeDavaliDurum1] / [_uyesizDavaliDurum2]).
  ///
  /// Dönüş anahtarları her durum için `durum<N>Id` ve `durum<N>Adi`
  /// taşır.
  static Future<Map<String, String>> seedDavaciOnayTestDavalar({
    required String davaciName,
    String? davaliName,
  }) async {
    final String davaci = davaciName.trim().isNotEmpty
        ? davaciName.trim()
        : 'Test Davacı';

    // Eski (2 durumlu) seed davalarını temizle — kalıntı bırakmayalım.
    HiveDatabaseService.deleteOpenedDava(testOnayDavaciHakliId);
    HiveDatabaseService.deleteOpenedDava(testOnayDavaciHaksizId);

    // Mevcut 4 durum davalarını da temizle — idempotent seed.
    HiveDatabaseService.deleteOpenedDava(testOnayDurum1Id);
    HiveDatabaseService.deleteOpenedDava(testOnayDurum2Id);
    HiveDatabaseService.deleteOpenedDava(testOnayDurum3Id);
    HiveDatabaseService.deleteOpenedDava(testOnayDurum4Id);

    final DateTime now = DateTime.now();

    final List<_OnayTestSenaryo> senaryolar = <_OnayTestSenaryo>[
      _OnayTestSenaryo(
        davaId: testOnayDurum1Id,
        davaAdi: 'TEST · Durum 1 — Davacı HAKLI + Davalı ÜYE',
        davaci: davaci,
        davali: _uyeDavaliDurum1,
        davaciHakli: true,
        openedAt: now,
        beklenenButton: 'Davalı → Masrafları Onayla',
      ),
      _OnayTestSenaryo(
        davaId: testOnayDurum2Id,
        davaAdi: 'TEST · Durum 2 — Davacı HAKLI + Davalı ÜYE DEĞİL',
        davaci: davaci,
        davali: _uyesizDavaliDurum2,
        davaciHakli: true,
        openedAt: now.subtract(const Duration(seconds: 1)),
        beklenenButton: "Davacı → Whobooma'a Ödensin",
      ),
      _OnayTestSenaryo(
        davaId: testOnayDurum3Id,
        davaAdi: 'TEST · Durum 3 — Davacı HAKSIZ + Davalı ÜYE',
        davaci: davaci,
        davali: _uyeDavaliDurum3,
        davaciHakli: false,
        openedAt: now.subtract(const Duration(seconds: 2)),
        beklenenButton: 'Davacı → Masrafları Onayla',
      ),
      _OnayTestSenaryo(
        davaId: testOnayDurum4Id,
        davaAdi: 'TEST · Durum 4 — Davacı HAKSIZ + Davalı ÜYE DEĞİL',
        davaci: davaci,
        davali: _uyesizDavaliDurum4,
        davaciHakli: false,
        openedAt: now.subtract(const Duration(seconds: 3)),
        beklenenButton: 'Davacı → Masrafları Onayla',
      ),
    ];

    // Override: caller davalı adını dışarıdan zorluyorsa hepsini onunla kur.
    final String? forcedDavali =
        davaliName != null && davaliName.trim().isNotEmpty
            ? davaliName.trim()
            : null;

    for (final _OnayTestSenaryo s in senaryolar) {
      final String resolvedDavali = forcedDavali ?? s.davali;

      _saveOnayTestOpenedDava(
        id: s.davaId,
        davaAdi: s.davaAdi,
        davaci: s.davaci,
        davali: resolvedDavali,
        openedAt: s.openedAt,
      );

      await _seedOnayTestHukumler(
        davaId: s.davaId,
        davaciHakli: s.davaciHakli,
      );

      // Yargıç ve jüri katılımcılarını kaydet — ceza/masraf/hediye
      // consensus servisleri rolden e-posta'ya eşleşmeyi
      // [HiveDatabaseService.getDavaParticipants] üzerinden yapıyor;
      // katılımcı yoksa onay butonları satırı hiç render edilmiyor.
      await _registerOnayTestParticipants(s.davaId);

      await HiveDatabaseService.saveCeza(
        davaId: s.davaId,
        userEmail: testOnayYargicEmail,
        cezaText: _testCezaText,
      );
      await HiveDatabaseService.saveMasrafExpenses(
        davaId: s.davaId,
        userEmail: testOnayYargicEmail,
        expenses: List<String>.from(_testHediyeMasrafSatirlari),
      );
    }

    return <String, String>{
      'durum1Id': senaryolar[0].davaId,
      'durum1Adi': senaryolar[0].davaAdi,
      'durum1Buton': senaryolar[0].beklenenButton,
      'durum2Id': senaryolar[1].davaId,
      'durum2Adi': senaryolar[1].davaAdi,
      'durum2Buton': senaryolar[1].beklenenButton,
      'durum3Id': senaryolar[2].davaId,
      'durum3Adi': senaryolar[2].davaAdi,
      'durum3Buton': senaryolar[2].beklenenButton,
      'durum4Id': senaryolar[3].davaId,
      'durum4Adi': senaryolar[3].davaAdi,
      'durum4Buton': senaryolar[3].beklenenButton,
      // Geriye dönük uyumluluk anahtarları.
      'hakliDavaId': senaryolar[0].davaId,
      'haksizDavaId': senaryolar[2].davaId,
      'hakliDavaAdi': senaryolar[0].davaAdi,
      'haksizDavaAdi': senaryolar[2].davaAdi,
    };
  }

  static void _saveOnayTestOpenedDava({
    required String id,
    required String davaAdi,
    required String davaci,
    required String davali,
    required DateTime openedAt,
  }) {
    HiveDatabaseService.saveOpenedDava(<String, dynamic>{
      'id': id,
      'davaAdi': davaAdi,
      'adi': davaAdi,
      'davaci': davaci,
      'davali': davali,
      'davaKonusu': '$davaAdi — davacı onay butonları test senaryosu.',
      'kategori': 'Test',
      'davaKategori': 'Test',
      'mevkii': 'Davacı',
      'kalanSure': 'Süre doldu',
      'profilResmi': 'lib/icons/03_davala_ana_icon.png',
      'isOpened': true,
      'openedAt': openedAt.toIso8601String(),
      'createdAt': openedAt.toIso8601String(),
      'lifecycleStatus': 'Active',
      'isArchived': false,
      'isAppealable': false,
      'isTestOnaySeed': true,
    });
  }

  static const List<String> _testJuriRoller = <String>[
    '1.Jüri',
    '2.Jüri',
    '3.Jüri',
    '4.Jüri',
  ];

  static String _testJuriEmail(String juriRolu) =>
      'onay.test.panel.${juriRolu.replaceAll('.', '_')}@its19.local';

  static Future<void> _seedOnayTestHukumler({
    required String davaId,
    required bool davaciHakli,
  }) async {
    final String yargicSentiment = davaciHakli
        ? HukumSentiment.positive.storageValue
        : HukumSentiment.negative.storageValue;

    await HiveDatabaseService.saveHukum(
      davaId: davaId,
      userRole: 'Yargıç Kararı',
      hukumText: davaciHakli
          ? 'Test: Davacı haklı — yargıç olumlu.'
          : 'Test: Davacı haksız — yargıç olumsuz.',
      userEmail: testOnayYargicEmail,
      hukumSentiment: yargicSentiment,
      isFinalized: true,
    );

    final List<String> panelSentimentleri = davaciHakli
        ? <String>[
            HukumSentiment.positive.storageValue,
            HukumSentiment.positive.storageValue,
            HukumSentiment.positive.storageValue,
            HukumSentiment.negative.storageValue,
          ]
        : <String>[
            HukumSentiment.negative.storageValue,
            HukumSentiment.negative.storageValue,
            HukumSentiment.negative.storageValue,
            HukumSentiment.positive.storageValue,
          ];

    for (int i = 0; i < _testJuriRoller.length; i++) {
      final String juriRolu = _testJuriRoller[i];
      await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: juriRolu,
        hukumText: 'Test panel hükmü ($juriRolu).',
        userEmail: _testJuriEmail(juriRolu),
        hukumSentiment: panelSentimentleri[i],
        isFinalized: true,
      );
    }
  }

  /// Davacı onay testi için yargıç + jüri katılımcılarını dava katılımcı
  /// listesine yazar. [CezaConsensusService] / [HediyeConsensusService] role
  /// karşılık gelen e-postayı buradan çözer.
  static Future<void> _registerOnayTestParticipants(String davaId) async {
    final DateTime now = DateTime.now();

    await HiveDatabaseService.markDavaParticipantStatus(
      davaId: davaId,
      userEmail: testOnayYargicEmail,
      status: 'accepted',
      statusAt: now,
      extra: <String, dynamic>{
        'displayName': 'Test Yargıç',
        'mevkii': 'Yargıç',
        'userRole': 'Yargıç',
        'acceptedAt': now.toIso8601String(),
        'isTestOnaySeed': true,
      },
      reason: 'seed_onay_test',
    );

    for (final String juriRolu in _testJuriRoller) {
      await HiveDatabaseService.markDavaParticipantStatus(
        davaId: davaId,
        userEmail: _testJuriEmail(juriRolu),
        status: 'accepted',
        statusAt: now,
        extra: <String, dynamic>{
          'displayName': 'Test $juriRolu',
          'mevkii': juriRolu,
          'userRole': juriRolu,
          'acceptedAt': now.toIso8601String(),
          'isTestOnaySeed': true,
        },
        reason: 'seed_onay_test',
      );
    }
  }
}

/// Davacı onay testi için tek bir senaryoyu temsil eden veri taşıyıcı.
class _OnayTestSenaryo {
  const _OnayTestSenaryo({
    required this.davaId,
    required this.davaAdi,
    required this.davaci,
    required this.davali,
    required this.davaciHakli,
    required this.openedAt,
    required this.beklenenButton,
  });

  final String davaId;
  final String davaAdi;
  final String davaci;
  final String davali;
  final bool davaciHakli;
  final DateTime openedAt;
  final String beklenenButton;
}

