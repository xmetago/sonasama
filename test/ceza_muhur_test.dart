import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Hive'ın belge dizini sahte saatte açılmaz; mevcut demo testiyle aynı kapı.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:its19/providers/dava_provider.dart';
import 'package:its19/services/ceza_muhur.dart';
import 'package:its19/services/dava_timer_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/cezalar_ceza_unified_panel.dart';

class _InMemoryPathProvider extends PathProviderPlatform {
  Directory? _tempDirectory;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    _tempDirectory ??= Directory.systemTemp.createTempSync('ceza_muhur_test_');
    return _tempDirectory!.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = _InMemoryPathProvider();
    await HiveDatabaseService.initialize();
    // Hüküm kutusu ilk okumada açılır. Widget testinin sahte saati bu
    // dosya açılışını bitirmez; kutuyu burada, gerçek saatte ısıt.
    await HiveDatabaseService.getHukumlerByDavaIdGrouped('__muhur_warmup__');
  });

  group('Ceza kaydı', () {
    test('eski düz metin yüklenir, tarih boş kalır', () {
      final CezaKaydi? kayit = CezaKaydi.parse('🎭 BERAAT');
      expect(kayit, isNotNull);
      expect(kayit!.text, '🎭 BERAAT');
      expect(kayit.sealedAt, isNull);
      expect(kayit.isSealed, isTrue);
      expect(CezaKaydi.parse('   '), isNull);
      expect(CezaKaydi.parse(null), isNull);
    });

    test('tarihli harita geriye dönük okunur', () {
      final DateTime when = DateTime.utc(2026, 3, 4, 9, 5);
      final Map<String, dynamic> raw = CezaKaydi(
        text: '🎭 DELİDİR',
        sealedAt: when,
      ).toPersisted();
      final CezaKaydi? kayit = CezaKaydi.parse(raw);
      expect(kayit!.text, '🎭 DELİDİR');
      expect(kayit.sealedAt, when);
    });

    test('Hive eski metni ve yeni mühür tarihini aynı kapıdan okur', () async {
      const String davaId = 'muhur-kayit-dava';
      const String eskiEmail = 'eski@test';
      const String yeniEmail = 'yeni@test';
      final DateTime when = DateTime(2026, 3, 4, 9, 5);

      await HiveDatabaseService.saveCeza(
        davaId: davaId,
        userEmail: eskiEmail,
        cezaText: '🎭 BERAAT',
      );
      await HiveDatabaseService.saveCeza(
        davaId: davaId,
        userEmail: yeniEmail,
        cezaText: '🎭 DELİDİR',
        sealedAt: when,
      );

      final CezaKaydi? eski = await HiveDatabaseService.getCezaKaydi(
        davaId: davaId,
        userEmail: eskiEmail,
      );
      final CezaKaydi? yeni = await HiveDatabaseService.getCezaKaydi(
        davaId: davaId,
        userEmail: yeniEmail,
      );
      expect(eski!.text, '🎭 BERAAT');
      expect(eski.sealedAt, isNull);
      expect(await HiveDatabaseService.getCeza(davaId: davaId, userEmail: eskiEmail), '🎭 BERAAT');
      expect(yeni!.text, '🎭 DELİDİR');
      expect(yeni.sealedAt, when);

      final Map<String, String> harita =
          await HiveDatabaseService.getCezaMapForDavaId(davaId);
      expect(harita[eskiEmail], '🎭 BERAAT');
      expect(harita[yeniEmail], '🎭 DELİDİR');
      expect(harita[yeniEmail], isNot(contains('sealedAt')));

      await HiveDatabaseService.deleteCeza(davaId: davaId, userEmail: eskiEmail);
      await HiveDatabaseService.deleteCeza(davaId: davaId, userEmail: yeniEmail);
    });

    test('sağlayıcı mühür tarihini kaydeder', () async {
      const String davaId = 'provider-dava';
      const String email = 'provider@test';
      final bool saved = await DavaProvider().updateCezaForDava(
        davaId: davaId,
        userEmail: email,
        cezaText: '🎭 19  Mucizesi',
        sealedAt: DateTime(2026, 3, 4, 9, 5),
      );
      expect(saved, isTrue);
      final CezaKaydi? kayit = await HiveDatabaseService.getCezaKaydi(
        davaId: davaId,
        userEmail: email,
      );
      expect(kayit, isNotNull);
      expect(kayit!.sealedAt, DateTime(2026, 3, 4, 9, 5));
      expect(kayit.text, contains('19'));
      expect(await HiveDatabaseService.getCeza(davaId: davaId, userEmail: email), contains('19'));
      await HiveDatabaseService.deleteCeza(davaId: davaId, userEmail: email);
    });
  });

  group('Mühür kilidi', () {
    final DateTime now = DateTime(2026, 6, 1, 12);

    test('yargıç 144. saatten önce ve altı rol bitmeden kilitli', () {
      final CezaMuhurKilit kilit = CezaMuhurKilit.degerlendir(
        gorev: 'Yargıç',
        openedAt: now.subtract(const Duration(hours: 10)),
        now: now,
        altiRolTamam: false,
        temyizPenceresiAcik: false,
      );
      expect(kilit.kilitli, isTrue);
      expect(kilit.neden, contains('144. saat'));
    });

    test('yargıç karar döneminde veya altı rol bitince açık', () {
      final CezaMuhurKilit sure = CezaMuhurKilit.degerlendir(
        gorev: 'Yargıç Kararı',
        openedAt: now.subtract(DavaTimerService.mainTrialWindow - const Duration(hours: 10)),
        now: now,
        altiRolTamam: false,
        temyizPenceresiAcik: false,
      );
      final CezaMuhurKilit erken = CezaMuhurKilit.degerlendir(
        gorev: 'Yargıç',
        openedAt: now.subtract(const Duration(hours: 2)),
        now: now,
        altiRolTamam: true,
        temyizPenceresiAcik: false,
      );
      expect(sure.kilitli, isFalse);
      expect(erken.kilitli, isFalse);
    });

    test('jüri ana sürede açık, 168 saat sonra kilitli', () {
      final CezaMuhurKilit acik = CezaMuhurKilit.degerlendir(
        gorev: '1. Jüri',
        openedAt: now.subtract(const Duration(hours: 20)),
        now: now,
        altiRolTamam: false,
        temyizPenceresiAcik: false,
      );
      final CezaMuhurKilit kapali = CezaMuhurKilit.degerlendir(
        gorev: '1. Jüri',
        openedAt: now.subtract(const Duration(hours: 200)),
        now: now,
        altiRolTamam: true,
        temyizPenceresiAcik: false,
      );
      expect(acik.kilitli, isFalse);
      expect(kapali.kilitli, isTrue);
      expect(kapali.neden, contains('168 saat'));
    });

    test('temyiz penceresi dışında kilitli', () {
      final CezaMuhurKilit kilit = CezaMuhurKilit.degerlendir(
        gorev: 'Temyiz Hakimi',
        openedAt: now.subtract(const Duration(hours: 200)),
        now: now,
        altiRolTamam: true,
        temyizPenceresiAcik: false,
      );
      expect(kilit.kilitli, isTrue);
      expect(kilit.neden, contains('Temyiz'));
    });
  });

  group('Mühür paneli', () {
    Future<void> pumpPanel(
      WidgetTester tester, {
      required CezalarCezaUnifiedPanel panel,
      ThemeData? theme,
    }) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final Widget child = panel;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? WhoBoomTheme.light,
          home: Scaffold(body: child),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    /// Hive dosya yazımı sahte saatte tamamlanmaz; gerçek döngüye bırakılır.
    Future<void> flushIo(WidgetTester tester) async {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
    }

    CezalarUnifiedDava dava(String mevkii) {
      return CezalarUnifiedDava(
        adi: 'Deneme Davası',
        davali: 'Davalı',
        davaci: 'Davacı',
        mevkii: mevkii,
        kalanSure: '—',
        profilResmi: 'lib/icons/03_davala_ana_icon.png',
      );
    }

    Future<void> reveal(WidgetTester tester, Finder target) async {
      final Finder scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 15; i++) {
        final Rect rect = tester.getRect(target);
        final double height =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        if (rect.top >= 0 && rect.bottom <= height - 120) {
          return;
        }
        await tester.drag(
          scrollable,
          Offset(0, rect.bottom > height ? -220 : 220),
        );
        await tester.pump();
      }
    }

    Future<void> openDecision(WidgetTester tester) async {
      await reveal(tester, find.text('OK'));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .removeCurrentSnackBar();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await reveal(tester, find.byKey(const Key('ceza-muhurle')));
    }

    Future<void> confirmSeal(WidgetTester tester) async {
      final Finder muhur = find.byKey(const Key('ceza-muhurle'));
      await reveal(tester, muhur);
      await tester.tap(muhur);
      await tester.pump();
      expect(find.text('Emin misin?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Mühürle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await flushIo(tester);
      await tester.pump();
    }

    testWidgets('erken mühür nedenini gösterir', (WidgetTester tester) async {
      await pumpPanel(
        tester,
        panel: CezalarCezaUnifiedPanel(
          dava: dava('Yargıç'),
          davaId: 'erken-dava',
          userEmail: 'yargic@test',
          embeddedMiddlePane: true,
        ),
      );
      await openDecision(tester);
      await tester.tap(find.byKey(const Key('ceza-muhurle')));
      await tester.pump();
      await flushIo(tester);
      await tester.pump();
      expect(find.textContaining('mühür kilitli'), findsOneWidget);
      expect(find.text('Emin misin?'), findsNothing);
      expect(find.text('Mühürlendi'), findsNothing);
    });

    testWidgets('kimlik yoksa mühürlü görünmez, tekrar dene çıkar', (WidgetTester tester) async {
      await pumpPanel(
        tester,
        panel: CezalarCezaUnifiedPanel(
          dava: dava('1. Jüri'),
          embeddedMiddlePane: true,
        ),
      );
      await openDecision(tester);
      await confirmSeal(tester);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Mühürlendi'), findsNothing);
      expect(find.textContaining('Mühür kaydedilemedi'), findsWidgets);
    });

    testWidgets('kayıt başarısızsa mühürlü duruma geçmez', (WidgetTester tester) async {
      await pumpPanel(
        tester,
        panel: CezalarCezaUnifiedPanel(
          dava: dava('1. Jüri'),
          davaId: 'hata-dava',
          userEmail: 'juri@test',
          embeddedMiddlePane: true,
          cezaKaydedici: ({
            required String davaId,
            required String userEmail,
            required String cezaText,
            required DateTime sealedAt,
          }) async {
            return false;
          },
        ),
      );
      await openDecision(tester);
      await confirmSeal(tester);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Mühürlendi'), findsNothing);
      expect(find.byTooltip('Seçimi kapat'), findsOneWidget);
    });

    testWidgets('mühürden sonra seçim kilitlenir ve kapatma kalkar', (WidgetTester tester) async {
      await pumpPanel(
        tester,
        panel: CezalarCezaUnifiedPanel(
          dava: dava('1. Jüri'),
          davaId: 'kilit-dava',
          userEmail: 'juri@test',
          embeddedMiddlePane: true,
          cezaKaydedici: ({
            required String davaId,
            required String userEmail,
            required String cezaText,
            required DateTime sealedAt,
          }) async {
            return true;
          },
        ),
      );
      await openDecision(tester);
      expect(tester.getSize(find.byTooltip('Seçimi kapat')).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(find.byTooltip('Seçimi kapat')).height, greaterThanOrEqualTo(44));
      await confirmSeal(tester);
      expect(find.text('Mühürlendi'), findsWidgets);
      expect(find.text('Paylaş'), findsOneWidget);
      expect(find.byTooltip('Seçimi kapat'), findsNothing);
      final IconButton sonraki = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Sonraki ceza'),
          matching: find.byType(IconButton),
        ),
      );
      expect(sonraki.onPressed, isNull);
    });

    testWidgets('kayıtlı mühür açılışta kilitli gelir', (WidgetTester tester) async {
      const String davaId = 'geri-dava';
      const String email = 'geri@test';
      final DateTime when = DateTime(2026, 3, 4, 9, 5);
      await tester.runAsync(() async {
        await HiveDatabaseService.saveCeza(
          davaId: davaId,
          userEmail: email,
          cezaText: '🎭 BERAAT',
          sealedAt: when,
        );
      });

      await pumpPanel(
        tester,
        panel: CezalarCezaUnifiedPanel(
          dava: dava('1. Jüri'),
          davaId: davaId,
          userEmail: email,
          embeddedMiddlePane: true,
        ),
      );
      expect(find.text('Mühürlendi'), findsWidgets);
      expect(find.textContaining('🎭 BERAAT'), findsWidgets);
      expect(find.text('Mühür: 04.03.2026 09:05'), findsOneWidget);
      expect(find.byTooltip('Seçimi kapat'), findsNothing);
      final IconButton sonraki = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Sonraki ceza'),
          matching: find.byType(IconButton),
        ),
      );
      expect(sonraki.onPressed, isNull);

      await tester.runAsync(() async {
        await HiveDatabaseService.deleteCeza(davaId: davaId, userEmail: email);
      });
    });

    testWidgets('eski metin kaydı mühürlü açılır, tarih satırı boşluğu söyler', (WidgetTester tester) async {
      const String davaId = 'eski-metin-dava';
      const String email = 'eski-metin@test';
      await tester.runAsync(() async {
        await HiveDatabaseService.saveCeza(
          davaId: davaId,
          userEmail: email,
          cezaText: '🎭 DELİDİR',
        );
      });

      await pumpPanel(
        tester,
        panel: CezalarCezaUnifiedPanel(
          dava: dava('1. Jüri'),
          davaId: davaId,
          userEmail: email,
          embeddedMiddlePane: true,
        ),
      );
      expect(find.text('Mühür tarihi kayıtlı değil'), findsOneWidget);
      expect(find.text('Mühürlendi'), findsWidgets);
      expect(find.textContaining('🎭 DELİDİR'), findsWidgets);

      await tester.runAsync(() async {
        await HiveDatabaseService.deleteCeza(davaId: davaId, userEmail: email);
      });
    });

    testWidgets('koyu temada mühür yazısı bordo değildir', (WidgetTester tester) async {
      await pumpPanel(
        tester,
        theme: WhoBoomTheme.dark,
        panel: CezalarCezaUnifiedPanel(
          dava: dava('1. Jüri'),
          embeddedMiddlePane: true,
        ),
      );
      await openDecision(tester);
      final Text muhur = tester.widget<Text>(find.text('Mühürle'));
      expect(muhur.style?.color, SeyirTokens.brand);
      expect(muhur.style?.color, isNot(const Color(0xFF8B0000)));
      expect(muhur.style?.fontSize, SeyirTokens.typeBody);
      final Text baslik = tester.widget<Text>(find.text('📜 MAHKEME KARARI'));
      expect(baslik.style?.color, isNot(const Color(0xFFCECBF6)));
      expect(baslik.style?.fontSize, SeyirTokens.typeHeadline);
    });
  });
}
