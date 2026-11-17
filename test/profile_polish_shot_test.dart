import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/home_page.dart';
import 'package:its19/screens/statistics_dashboard_page.dart';
import 'package:its19/screens/user_gamified_score_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/common_header_widgets.dart';
import 'package:its19/widgets/delil_surface.dart';
import 'package:provider/provider.dart';

/// Profil, puan kartı ve istatistik ekran görüntüleri.
///
/// PROFILE_SHOT_DIR ve PROFILE_SHOT_PHASE (before | after) set ise
/// `score|stats|profile|chart-...-<phase>-<brightness>.png` yazar.
/// Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'ProfileFallback';
const _email = 'ayse.demir@example.com';
const _otherEmail = 'mehmet.kaya@example.com';
const _emptyEmail = 'bos.istatistik@example.com';
const _davaId = 'shot-dava-gece';

bool get _after =>
    (Platform.environment['PROFILE_SHOT_PHASE'] ?? 'after') != 'before';

String? _packageRoot(String name) {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final decoded = jsonDecode(config.readAsStringSync());
  if (decoded is! Map) return null;
  final packages = decoded['packages'];
  if (packages is! List) return null;
  for (final entry in packages) {
    if (entry is! Map || entry['name'] != name) continue;
    final root = entry['rootUri'];
    if (root is! String) return null;
    final uri = Uri.parse(root);
    if (uri.scheme == 'file') return uri.toFilePath();
    return config.parent.uri.resolve(root).toFilePath();
  }
  return null;
}

ThemeData _shotTheme(Brightness brightness) {
  final ThemeData base =
      brightness == Brightness.dark ? WhoBoomTheme.dark : WhoBoomTheme.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: base.colorScheme,
    fontFamily: _shotFont,
    fontFamilyFallback: const <String>[_fallbackFont],
    scaffoldBackgroundColor: base.scaffoldBackgroundColor,
    extensions: base.extensions.values.toList(),
    elevatedButtonTheme: base.elevatedButtonTheme,
    iconTheme: base.iconTheme,
  );
}

Future<void> _loadFonts() async {
  Future<void> loadFamily(String family, List<String> paths) async {
    final files = paths.map(File.new).where((file) => file.existsSync());
    if (files.isEmpty) return;
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  await loadFamily(_shotFont, const [
    'lib/fonts/cocon_regular.otf',
  ]);
  await loadFamily(_fallbackFont, const [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  ]);
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/tmp/flutter-sdk';
  await loadFamily('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
  final mdiRoot = _packageRoot('flutter_material_design_icons');
  await loadFamily(
    'packages/flutter_material_design_icons/Material Design Icons',
    [
      if (mdiRoot != null) '$mdiRoot/assets/materialdesignicons-webfont.ttf',
    ],
  );
}

RegistrationModel _person({
  required String id,
  required String name,
  required String email,
}) {
  return RegistrationModel(
    id: id,
    judgeName: name,
    email: email,
    password: 'shot',
    country: 'Türkiye',
    oath: true,
    createdAt: DateTime(2024, 1, 1),
    lastLoginAt: DateTime(2024, 6, 1),
  );
}

Future<void> _seed() async {
  if (HiveDatabaseService.getRegistrationByEmail(_email) == null) {
    await HiveDatabaseService.addRegistration(
      _person(id: 'shot-ayse', name: 'Ayşe Demir', email: _email),
    );
  }
  if (HiveDatabaseService.getRegistrationByEmail(_otherEmail) == null) {
    await HiveDatabaseService.addRegistration(
      _person(id: 'shot-mehmet', name: 'Mehmet Kaya', email: _otherEmail),
    );
  }
  if (HiveDatabaseService.getRegistrationByEmail(_emptyEmail) == null) {
    await HiveDatabaseService.addRegistration(
      _person(id: 'shot-bos', name: 'Boş Kayıt', email: _emptyEmail),
    );
  }
  await HiveDatabaseService.getOrCreateSettings(_email);
  await HiveDatabaseService.getOrCreateSettings(_otherEmail);

  HiveDatabaseService.saveOpenedDava(<String, dynamic>{
    'id': _davaId,
    'davaId': _davaId,
    'userEmail': _otherEmail,
    'adi': 'Gece lambası',
    'davaAdi': 'Gece lambası',
    'davaci': 'Selim Aras',
    'davali': 'Mehmet Kaya',
    'kategori': 'Komşuluk',
    'davaKonusu': 'Sokak lambası günlerdir yanmıyor.',
    'openedAt': DateTime(2026, 11, 16, 21, 10).toIso8601String(),
    'createdAt': DateTime(2026, 11, 16, 21, 10).toIso8601String(),
  });
  await HiveDatabaseService.addHaykir(<String, dynamic>{
    'id': 'shot-haykir-1',
    'adi': 'Sokak sesi',
    'title': 'Sokak sesi',
    'slogan': 'Lamba yanmıyor',
    'direme': 'Komşuluk',
    'userEmail': _email,
    'createdAt': DateTime(2026, 11, 16, 22).toIso8601String(),
    'isActive': 'true',
    'isVisibleInHaykirPage': 'true',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    Directory('/tmp/profile-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/profile-hive',
    );
    await HiveDatabaseService.initialize();
    await _seed();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    Widget page, {
    Size size = const Size(420, 1680),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('profile-shot'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => DavaProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: page,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> waitForText(WidgetTester tester, String text) async {
    for (var i = 0; i < 30 && find.text(text).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
    }
    if (find.text(text).evaluate().isEmpty) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((element) => (element.widget as Text).data)
          .whereType<String>()
          .take(24)
          .join(' | ');
      fail('Metin bulunamadı: $text. Görünenler: $texts');
    }
  }

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['PROFILE_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('profile-shot')),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File('$dir/$name');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  String phaseName(String stem, String brightness) =>
      '$stem-${_after ? 'after' : 'before'}-$brightness.png';

  RegistrationModel ayse() =>
      HiveDatabaseService.getRegistrationByEmail(_email)!;

  Future<void> shotScore(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      UserGamifiedScorePage(targetUser: ayse()),
      size: const Size(420, 1900),
    );
    await waitForText(tester, 'Ayşe Demir');
    expect(find.text('Puan Kartı'), findsOneWidget);
    expect(find.text('Ayşe Demir'), findsWidgets);
    expect(find.text('İtibar Endeksi'), findsWidgets);
    if (_after) {
      final Text title = tester.widget<Text>(find.text('Puan Kartı'));
      expect(title.style?.fontSize, SeyirTokens.typeDisplay);
      expect(title.style?.color, isNot(equals(Colors.white)));
    }
    await saveShot(tester, phaseName('score', brightness.name));
    await releasePage(tester);
  }

  testWidgets('score light', (tester) async {
    await shotScore(tester, Brightness.light);
  });

  testWidgets('score dark', (tester) async {
    await shotScore(tester, Brightness.dark);
  });

  Future<void> shotChart(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      UserGamifiedScorePage(targetUser: ayse()),
      size: const Size(420, 900),
    );
    await waitForText(tester, 'Trend grafiği');
    final trend = find.text('Trend grafiği');
    await tester.scrollUntilVisible(
      trend,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(trend);
    await tester.pump();
    await tester.tap(find.text('Trend grafiği'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    if (_after) {
      expect(find.text('Henüz geçmiş yok'), findsOneWidget);
      expect(find.text('12 ay (yıllık)'), findsNothing);
    } else {
      expect(find.text('12 ay (yıllık)'), findsOneWidget);
      expect(find.text('Henüz geçmiş yok'), findsNothing);
    }
    await saveShot(tester, phaseName('chart-no-history', brightness.name));
    await releasePage(tester);
  }

  testWidgets('chart no history light', (tester) async {
    await shotChart(tester, Brightness.light);
  });

  testWidgets('chart no history dark', (tester) async {
    await shotChart(tester, Brightness.dark);
  });

  Future<void> shotStats(
    WidgetTester tester,
    Brightness brightness,
    String email,
    String stem,
    String needle,
  ) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      StatisticsDashboardPage(userEmail: email),
      size: const Size(420, 1700),
    );
    await waitForText(tester, needle);
    expect(find.text(needle), findsWidgets);
    if (_after && stem == 'stats') {
      final Icon chat = tester.widget<Icon>(
        find.descendant(
          of: find.byType(StatisticsDashboardPage),
          matching: find.byIcon(Icons.search),
        ),
      );
      expect(chat.color, isNot(equals(Colors.black54)));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      final TextField field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.focusNode?.hasFocus, isTrue);
    }
    if (_after && stem == 'stats-empty') {
      expect(find.byType(DelilSoftEmpty), findsOneWidget);
      expect(find.text('Veri bulunamadı'), findsOneWidget);
    }
    await saveShot(tester, phaseName(stem, brightness.name));
    await releasePage(tester);
  }

  testWidgets('stats light', (tester) async {
    await shotStats(
      tester,
      Brightness.light,
      _email,
      'stats',
      'Gece lambası',
    );
  });

  testWidgets('stats dark', (tester) async {
    await shotStats(
      tester,
      Brightness.dark,
      _email,
      'stats',
      'Gece lambası',
    );
  });

  Future<void> clearStatsData() async {
    HiveDatabaseService.clearOpenedDavalar();
    HiveDatabaseService.clearSavedDavalar();
    await HiveDatabaseService.deleteHaykir('shot-haykir-1');
  }

  testWidgets('stats empty light', (tester) async {
    await tester.runAsync(clearStatsData);
    await shotStats(
      tester,
      Brightness.light,
      _emptyEmail,
      'stats-empty',
      _after ? 'Veri bulunamadı' : 'Kayıt bulunamadı',
    );
  });

  testWidgets('stats empty dark', (tester) async {
    await tester.runAsync(clearStatsData);
    await shotStats(
      tester,
      Brightness.dark,
      _emptyEmail,
      'stats-empty',
      _after ? 'Veri bulunamadı' : 'Kayıt bulunamadı',
    );
  });

  Future<void> shotStrip(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      Scaffold(
        body: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
          userEmail: _email,
          targetUserEmail: _otherEmail,
        ),
      ),
      size: const Size(420, 280),
    );
    await tester.pump();
    expect(find.text('Mehmet Kaya'), findsOneWidget);
    expect(find.text('Sohbet'), findsOneWidget);
    expect(find.text('Dürt'), findsOneWidget);
    if (_after) {
      final Text name = tester.widget<Text>(find.text('Mehmet Kaya'));
      expect(name.style?.fontSize, SeyirTokens.typeTitle);
      expect(name.style?.color, SeyirPalette.of(tester.element(find.text('Mehmet Kaya'))).textPrimary);
      final Size chat = tester.getSize(find.widgetWithText(OutlinedButton, 'Sohbet'));
      expect(chat.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      final Size poke = tester.getSize(find.widgetWithText(OutlinedButton, 'Dürt'));
      expect(poke.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    }
    await saveShot(tester, phaseName('profile-strip', brightness.name));
    await releasePage(tester);
  }

  testWidgets('profile strip light', (tester) async {
    await shotStrip(tester, Brightness.light);
  });

  testWidgets('profile strip dark', (tester) async {
    await shotStrip(tester, Brightness.dark);
  });

  testWidgets('other photo opens score read only', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      Scaffold(
        body: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
          userEmail: _email,
          targetUserEmail: _otherEmail,
        ),
      ),
      size: const Size(420, 320),
    );
    await tester.tap(find.byType(CircleAvatar));
    await tester.pump();
    await waitForText(tester, 'Puan Kartı');
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(UserGamifiedScorePage), findsOneWidget);
    final UserGamifiedScorePage page =
        tester.widget<UserGamifiedScorePage>(find.byType(UserGamifiedScorePage));
    expect(page.readOnly, isTrue);
    expect(page.targetUser.email, _otherEmail);
    await saveShot(tester, 'score-readonly-nav-after-light.png');
    await releasePage(tester);
  });

  testWidgets('own photo and name open score', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      Scaffold(
        body: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
          userEmail: _email,
        ),
      ),
      size: const Size(420, 320),
    );
    await tester.tap(find.byType(CircleAvatar));
    await tester.pump();
    await waitForText(tester, 'Puan Kartı');
    final UserGamifiedScorePage fromPhoto =
        tester.widget<UserGamifiedScorePage>(find.byType(UserGamifiedScorePage));
    expect(fromPhoto.readOnly, isFalse);
    expect(fromPhoto.targetUser.email, _email);
    await releasePage(tester);

    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      Scaffold(
        body: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
          userEmail: _email,
        ),
      ),
      size: const Size(420, 320),
    );
    await tester.tap(find.text('Ayşe Demir'));
    await tester.pump();
    await waitForText(tester, 'Puan Kartı');
    final UserGamifiedScorePage fromName =
        tester.widget<UserGamifiedScorePage>(find.byType(UserGamifiedScorePage));
    expect(fromName.readOnly, isFalse);
    expect(fromName.targetUser.email, _email);
    await releasePage(tester);
  });

  testWidgets('stats error dark', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const StatisticsDashboardPage(
        userEmail: _email,
        forceLoadError: true,
      ),
      size: const Size(420, 900),
    );
    await tester.pump();
    expect(find.byType(DelilLoadError), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Veri bulunamadı'), findsNothing);
    await saveShot(tester, 'stats-error-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('score error light', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      UserGamifiedScorePage(
        targetUser: ayse(),
        forceLoadError: true,
      ),
      size: const Size(420, 900),
    );
    await tester.pump();
    expect(find.byType(DelilLoadError), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    await saveShot(tester, 'score-error-after-light.png');
    await releasePage(tester);
  });

  testWidgets('stats starts loading', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const StatisticsDashboardPage(
        userEmail: _email,
        forceLoading: true,
      ),
      size: const Size(420, 900),
    );
    expect(find.text('İstatistikler yükleniyor...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Veri bulunamadı'), findsNothing);
    await saveShot(tester, 'stats-loading-after-light.png');
    await releasePage(tester);
  });
}
