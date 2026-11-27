import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:its19/models/hukum_sentiment.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/services/dava_consensus_service.dart';
import 'package:its19/services/dava_hukum_eligibility_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/modern_hukum_card.dart';
import 'package:its19/widgets/rol_hukum_kartlari_section.dart';

class _InMemoryPathProvider extends PathProviderPlatform {
  Directory? _tempDirectory;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    _tempDirectory ??= Directory.systemTemp.createTempSync('sekiz_hukum_test_');
    return _tempDirectory!.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = _InMemoryPathProvider();
    await HiveDatabaseService.initialize();
  });

  group('Türkçe rol katlaması', () {
    test('Yargıç, ç ve noktasız ı ile yargic olur', () {
      expect(DavaHukumEligibilityService.foldTurkish('Yargıç'), 'yargic');
      expect(DavaHukumEligibilityService.foldTurkish('YARGIÇ'), 'yargic');
      expect(DavaHukumEligibilityService.foldTurkish('YARGİÇ'), 'yargic');
      expect(DavaHukumEligibilityService.roleLabelIsYargic('Yargıç'), isTrue);
      expect(DavaHukumEligibilityService.roleLabelIsYargic('Yargıç Kararı'), isTrue);
      expect(DavaHukumEligibilityService.roleLabelIsYargic('Yargic'), isTrue);
      expect(DavaHukumEligibilityService.roleLabelIsYargic('1. Jüri'), isFalse);
    });

    test('normalizeRolKarari eski yazılışları aynı role indirger', () {
      expect(normalizeRolKarari('Yargıç'), 'Yargıç Kararı');
      expect(normalizeRolKarari('Yargic'), 'Yargıç Kararı');
      expect(normalizeRolKarari('Yargic Karari'), 'Yargıç Kararı');
      expect(normalizeRolKarari('YARGİÇ KARARI'), 'Yargıç Kararı');
      expect(normalizeRolKarari('Hakim'), 'Yargıç Kararı');
      expect(normalizeRolKarari('1. Juri'), '1. Jüri Kararı');
      expect(normalizeRolKarari('1.Jüri'), '1. Jüri Kararı');
      expect(normalizeRolKarari('2.Jüri'), '2. Jüri Kararı');
      expect(normalizeRolKarari('Temyiz hakimi'), 'Temyiz Hakimi Kararı');
      expect(normalizeRolKarari('İstinaf Hakimi'), 'Temyiz Hakimi Kararı');
      expect(normalizeRolKarari('Davacı avukatı'), 'Davacı Avukatı Kararı');
      expect(normalizeRolKarari('Davacı Vekili'), 'Davacı Avukatı Kararı');
      expect(normalizeRolKarari('Davalı avukatı'), 'Davalı Avukatı Kararı');
      expect(normalizeRolKarari('Davalı Vekili'), 'Davalı Avukatı Kararı');
      expect(normalizeRolKarari('Davacı Şahidi'), 'Davacı Şahidi Kararı');
      expect(normalizeRolKarari('Davacı Tanığı'), 'Davacı Şahidi Kararı');
      expect(normalizeRolKarari('Davalı Şahidi'), 'Davalı Şahidi Kararı');
      expect(normalizeRolKarari('Davalı Tanığı'), 'Davalı Şahidi Kararı');
    });
  });

  group('Hüküm kaydı', () {
    test('finalize edilmiş farklı metin yazılmaz ve sağlayıcı false döner', () async {
      const String davaId = 'rollback-dava';
      const String role = '1. Jüri Kararı';
      final bool first = await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: role,
        hukumText: 'orijinal hüküm',
        userEmail: 'a@b.c',
        hukumSentiment: 'positive',
        isFinalized: true,
      );
      expect(first, isTrue);

      final bool overwritten = await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: role,
        hukumText: 'değişen hüküm',
        userEmail: 'a@b.c',
        hukumSentiment: 'negative',
        isFinalized: true,
      );
      expect(overwritten, isFalse);

      final Map<String, dynamic>? stored =
          await HiveDatabaseService.getHukumByDavaIdAndRole(davaId, role);
      expect(stored?['hukumText'], 'orijinal hüküm');

      final bool providerOk = await DavaProvider().updateHukumForDava(
        davaId: davaId,
        userRole: role,
        hukumText: 'sağlayıcı denemesi',
        userEmail: 'a@b.c',
        hukumSentiment: 'negative',
        isFinalized: true,
      );
      expect(providerOk, isFalse);
      final Map<String, dynamic>? after =
          await HiveDatabaseService.getHukumByDavaIdAndRole(davaId, role);
      expect(after?['hukumText'], 'orijinal hüküm');
    });

    test('boş kimlik ve ad hash kayıt bölmez', () async {
      const String name = 'Bolunmesin Davasi';
      final String hashId = 'dava_${name.hashCode}';
      await HiveDatabaseService.saveHukum(
        davaId: hashId,
        userRole: '1. Jüri Kararı',
        hukumText: 'hash altındaki eski kayıt',
        userEmail: 'a@b.c',
        hukumSentiment: 'positive',
      );

      final Map<String, Map<String, dynamic>> grouped =
          await HiveDatabaseService.getHukumlerByDavaIdGrouped(
        'gercek-kimlik',
        davaAdi: name,
      );
      expect(grouped, isEmpty);
      expect(
        await HiveDatabaseService.getHukumByDavaIdAndRole(
          'gercek-kimlik',
          '1. Jüri Kararı',
          davaAdi: name,
        ),
        isNull,
      );
      expect(
        await HiveDatabaseService.saveHukum(
          davaId: ' ',
          userRole: '1. Jüri Kararı',
          hukumText: 'yazilmamali',
          userEmail: 'a@b.c',
        ),
        isFalse,
      );
    });

    test('sekiz rolün hükmü Hive’a yazılır', () async {
      const String davaId = 'icon-tap-all-roles';
      const List<(String, String)> roles = <(String, String)>[
        ('Temyiz hakimi', 'Temyiz hükmü metni.'),
        ('Yargıç', 'Yargıç hükmü metni.'),
        ('1.Jüri', 'Birinci jüri hükmü.'),
        ('2.Jüri', 'İkinci jüri hükmü.'),
        ('Davacı avukatı', 'Davacı tarafı hükmü.'),
        ('Davalı avukatı', 'Davalı tarafı hükmü.'),
        ('Davacı Şahidi', 'Davacı şahit hükmü.'),
        ('Davalı Şahidi', 'Davalı şahit hükmü.'),
      ];
      for (final (String stored, String text) in roles) {
        expect(
          await HiveDatabaseService.saveHukum(
            davaId: davaId,
            userRole: stored,
            hukumText: text,
            userEmail: 'rol@test',
            hukumSentiment: HukumSentiment.positive.storageValue,
            isFinalized: false,
          ),
          isTrue,
        );
      }
      final Map<String, Map<String, dynamic>> grouped =
          await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId);
      expect(grouped.length, roles.length);
    });
  });

  group('Temyiz yansıması', () {
    test('süre dolunca temyiz yargıç yönünde sayılır, oy çiftlenmez', () async {
      final DateTime now = DateTime.now();
      const String davaId = 'appeal-fallback';
      HiveDatabaseService.saveOpenedDava(<String, dynamic>{
        'id': davaId,
        'openedAt': now.subtract(const Duration(days: 12)).toIso8601String(),
        'isAppealable': true,
        'appealRequestedAt':
            now.subtract(const Duration(hours: 80)).toIso8601String(),
      });
      await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: 'Yargıç Kararı',
        hukumText: 'yargıç olumsuz',
        userEmail: 'yargi@test',
        hukumSentiment: HukumSentiment.negative.storageValue,
        isFinalized: true,
      );
      await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: '1. Jüri Kararı',
        hukumText: 'jüri olumlu',
        userEmail: 'juri@test',
        hukumSentiment: HukumSentiment.positive.storageValue,
        isFinalized: true,
      );

      await DavaHukumEligibilityService.ensureAppealJudgeFallback(davaId);
      final Map<String, dynamic>? opened =
          HiveDatabaseService.getOpenedDavaById(davaId);
      expect(opened?['appealJudgeFallbackApplied'], isTrue);
      expect(opened?['appealJudgeFallbackSentiment'], 'negative');

      final DavaConsensusEvaluation evaluation =
          await DavaConsensusService.evaluateConsensus(davaId: davaId);
      expect(evaluation.verdict, DavaConsensusVerdict.haksiz);
      expect(evaluation.positiveCount, 1);
      expect(evaluation.negativeCount, 1);
      expect(
        DavaHukumEligibilityService.appealOrYargicDirection(
          davaId: davaId,
          temyiz: null,
          yargic: null,
        ),
        HukumSentiment.negative,
      );
    });
  });

  group('Süre kilidi', () {
    test('açılış tarihi yoksa 144 ve 168 atlanmaz', () {
      final DateTime now = DateTime(2026, 6, 1, 12);
      final HukumRoleEditLock juri =
          DavaHukumEligibilityService.evaluateRoleEditLock(
        gorev: '1. Jüri',
        openedAt: null,
        now: now,
        appealWindowActive: false,
        sixPanelFinalized: true,
      );
      final HukumRoleEditLock yargic =
          DavaHukumEligibilityService.evaluateRoleEditLock(
        gorev: 'Yargıç',
        openedAt: null,
        now: now,
        appealWindowActive: false,
        sixPanelFinalized: false,
      );
      expect(juri.locked, isTrue);
      expect(yargic.locked, isTrue);
      expect(juri.reason, contains('açılış tarihi'));
    });
  });

  group('8-Hüküm kartı', () {
    Future<void> flushIo(WidgetTester tester) async {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
    }

    Widget host(ModernHukumCard card) {
      return ChangeNotifierProvider<DavaProvider>(
        create: (_) => DavaProvider(),
        child: MaterialApp(
          theme: WhoBoomTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: card)),
        ),
      );
    }

    testWidgets('künye başlığı içerikle aynı durumu gösterir', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(host(ModernHukumCard(
        userEmail: 'kunye@test',
        davaId: 'kunye-dava',
        openedAt: DateTime(2026, 11, 1, 9),
        davaAdi: 'Künye Davası',
        davaDavali: 'Davalı',
        davaDavaci: 'Davacı',
        davaGorev: '1. Jüri',
        kalanSure: '',
      )));
      await flushIo(tester);
      await tester.pump();

      AnimatedCrossFade fade() {
        final Finder ink = find.ancestor(
          of: find.text('|| Dava Künyesi ||'),
          matching: find.byType(InkWell),
        );
        final Finder column = find
            .ancestor(of: ink, matching: find.byType(Column))
            .first;
        return tester.widget<AnimatedCrossFade>(
          find.descendant(of: column, matching: find.byType(AnimatedCrossFade)),
        );
      }

      AnimatedRotation rotation() {
        return tester.widget<AnimatedRotation>(
          find.descendant(
            of: find.ancestor(
              of: find.text('|| Dava Künyesi ||'),
              matching: find.byType(InkWell),
            ),
            matching: find.byType(AnimatedRotation),
          ),
        );
      }

      expect(fade().crossFadeState, CrossFadeState.showFirst);
      expect(rotation().turns, 0.5);

      await tester.tap(find.text('|| Dava Künyesi ||'));
      await tester.pump();
      expect(fade().crossFadeState, CrossFadeState.showSecond);
      expect(rotation().turns, 0);

      await tester.tap(find.text('|| Dava Künyesi ||'));
      await tester.pump();
      expect(fade().crossFadeState, CrossFadeState.showFirst);
      expect(rotation().turns, 0.5);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('hüküm verildi onay ister', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WhoBoomTheme.light,
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => confirmHukumVerildi(context),
                  child: const Text('aç'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text('Emin misin?'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(find.text('Emin misin?'), findsNothing);
    });

    testWidgets('kimlik yoksa kayıt engeli ve tekrar dene görünür', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(host(const ModernHukumCard(
        davaId: '',
        davaAdi: 'Adsız',
        davaDavali: 'Davalı',
        davaDavaci: 'Davacı',
        davaGorev: '1. Jüri',
        kalanSure: '',
      )));
      await flushIo(tester);
      await tester.pump();
      expect(find.textContaining('Dava kimliği yok'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.textContaining('düzenleme kilitli'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('yeniden açılınca ceza ve masraf tamamlanır', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      const String davaId = 'reopen-dava';
      const String email = 'reopen@test';
      const String prefix = 'whoboom sakinleri adına, gereği düşünüldü: ';
      final String body = List<String>.filled(70, 'karar').join(' ');
      await tester.runAsync(() async {
        await HiveDatabaseService.saveHukum(
          davaId: davaId,
          userRole: '1. Jüri Kararı',
          hukumText: '$prefix$body',
          userEmail: email,
          hukumSentiment: HukumSentiment.positive.storageValue,
          isFinalized: true,
        );
        await HiveDatabaseService.saveCeza(
          davaId: davaId,
          userEmail: email,
          cezaText: '🎭 BERAAT',
        );
        await HiveDatabaseService.saveMasrafExpenses(
          davaId: davaId,
          userEmail: email,
          expenses: const <String>['🎁 Çiçek · ⭐ hediye › not'],
        );
      });

      await tester.pumpWidget(host(ModernHukumCard(
        userEmail: email,
        davaId: davaId,
        openedAt: DateTime.now(),
        davaAdi: 'Yeniden Açılan',
        davaDavali: 'Davalı',
        davaDavaci: 'Davacı',
        davaGorev: '1. Jüri',
        kalanSure: '',
      )));
      await flushIo(tester);
      await tester.pump();
      await flushIo(tester);
      await tester.pump();

      Map<String, dynamic>? stored;
      await tester.runAsync(() async {
        stored = await HiveDatabaseService.getHukumByDavaIdAndRole(
          davaId,
          '1. Jüri Kararı',
        );
      });
      expect(stored?['isFinalized'], isTrue);
      expect(find.textContaining('Yön: Olumlu'), findsWidgets);
      expect(find.textContaining('BERAAT'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('yeniden açılınca ceza ve masraf hükmü tamamlar', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      const String davaId = 'reopen-auto-dava';
      const String email = 'reopen-auto@test';
      const String prefix = 'whoboom sakinleri adına, gereği düşünüldü: ';
      final String body = List<String>.filled(70, 'karar').join(' ');
      await tester.runAsync(() async {
        await HiveDatabaseService.saveHukum(
          davaId: davaId,
          userRole: '1. Jüri Kararı',
          hukumText: '$prefix$body',
          userEmail: email,
          hukumSentiment: HukumSentiment.positive.storageValue,
          isFinalized: false,
        );
        await HiveDatabaseService.saveCeza(
          davaId: davaId,
          userEmail: email,
          cezaText: '🎭 BERAAT',
        );
        await HiveDatabaseService.saveMasrafExpenses(
          davaId: davaId,
          userEmail: email,
          expenses: const <String>['🎁 Çiçek · ⭐ hediye › not'],
        );
      });

      await tester.pumpWidget(host(ModernHukumCard(
        userEmail: email,
        davaId: davaId,
        openedAt: DateTime.now(),
        davaAdi: 'Otomatik Tamamlanan',
        davaDavali: 'Davalı',
        davaDavaci: 'Davacı',
        davaGorev: '1. Jüri',
        kalanSure: '',
      )));
      await flushIo(tester);
      await tester.pump();
      await flushIo(tester);
      await tester.pump(const Duration(milliseconds: 600));
      await flushIo(tester);
      await tester.pump();

      Map<String, dynamic>? stored;
      await tester.runAsync(() async {
        stored = await HiveDatabaseService.getHukumByDavaIdAndRole(
          davaId,
          '1. Jüri Kararı',
        );
      });
      expect(stored?['isFinalized'], isTrue);
      expect(find.textContaining('Yön: Olumlu'), findsWidgets);
      expect(find.textContaining('BERAAT'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });

    const String iconDavaId = 'icon-tap-all-roles';
    const List<(String, String, String)> iconRoles = <(String, String, String)>[
      ('Temyiz hakimi', 'Temyiz Hakimi Kararı', 'Temyiz hükmü metni.'),
      ('Yargıç', 'Yargıç Kararı', 'Yargıç hükmü metni.'),
      ('1.Jüri', '1. Jüri Kararı', 'Birinci jüri hükmü.'),
      ('2.Jüri', '2. Jüri Kararı', 'İkinci jüri hükmü.'),
      ('Davacı avukatı', 'Davacı Avukatı Kararı', 'Davacı tarafı hükmü.'),
      ('Davalı avukatı', 'Davalı Avukatı Kararı', 'Davalı tarafı hükmü.'),
      ('Davacı Şahidi', 'Davacı Şahidi Kararı', 'Davacı şahit hükmü.'),
      ('Davalı Şahidi', 'Davalı Şahidi Kararı', 'Davalı şahit hükmü.'),
    ];

    testWidgets('dosya ikonu hüküm metnini açar ve Hive sonrası durur', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 2400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      Future<void> pumpCard() async {
        await tester.pumpWidget(host(ModernHukumCard(
          userEmail: 'viewer@test',
          davaId: iconDavaId,
          openedAt: DateTime(2026, 11, 1, 9),
          davaAdi: 'Rol İkon Davası',
          davaDavali: 'Davalı',
          davaDavaci: 'Davacı',
          davaGorev: 'Davacı',
          kalanSure: '',
        )));
        await flushIo(tester);
        await tester.pump();
        await flushIo(tester);
        await tester.pump(const Duration(milliseconds: 600));
        await flushIo(tester);
        await tester.pump();
      }

      Future<void> openRole(String title, String text) async {
        final Finder titleFinder = find.text(title);
        expect(titleFinder, findsOneWidget);
        await tester.ensureVisible(titleFinder);
        await tester.pump();
        final Finder row = find
            .ancestor(of: titleFinder, matching: find.byType(Row))
            .first;
        final Finder icon = find.descendant(
          of: row,
          matching: find.byIcon(MdiIcons.fileCheckOutline),
        );
        expect(icon, findsOneWidget);
        final Icon iconWidget = tester.widget<Icon>(icon);
        expect(iconWidget.size, 30);
        expect(iconWidget.color, Colors.green.shade700);
        final Size hit = tester.getSize(
          find.ancestor(of: icon, matching: find.byType(InkWell)).first,
        );
        expect(hit.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
        expect(hit.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
        expect(tester.getSize(icon), const Size(30, 30));

        await tester.tap(icon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining(text), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining(text), findsNothing);
      }

      await pumpCard();
      for (final (String _, String title, String text) in iconRoles) {
        await openRole(title, text);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await pumpCard();
      await openRole('Yargıç Kararı', 'Yargıç hükmü metni.');
      await openRole('Davacı Avukatı Kararı', 'Davacı tarafı hükmü.');
      await openRole('Davalı Avukatı Kararı', 'Davalı tarafı hükmü.');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('hüküm yoksa dosya ikonu kısa Türkçe mesaj gösterir', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 2400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(host(ModernHukumCard(
        userEmail: 'bos@test',
        davaId: 'icon-tap-empty',
        openedAt: DateTime(2026, 11, 1, 9),
        davaAdi: 'Boş Hüküm',
        davaDavali: 'Davalı',
        davaDavaci: 'Davacı',
        davaGorev: '1. Jüri',
        kalanSure: '',
      )));
      await tester.pump();

      final Finder title = find.text('1. Jüri Kararı');
      await tester.ensureVisible(title);
      await tester.pump();
      final Finder row =
          find.ancestor(of: title, matching: find.byType(Row)).first;
      final Finder icon = find.descendant(
        of: row,
        matching: find.byIcon(MdiIcons.fileCheckOutline),
      );
      expect(tester.widget<Icon>(icon).color, Colors.brown);
      expect(tester.widget<Icon>(icon).size, 30);

      await tester.tap(icon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bu rol için kayıtlı bir hüküm yok.'), findsOneWidget);
      expect(find.text('RESMİ HÜKÜM'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
