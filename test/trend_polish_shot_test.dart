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
import 'package:its19/screens/category_page.dart';
import 'package:its19/screens/sekiz_hukum_page.dart';
import 'package:its19/screens/trend_insights_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/services/trending_insights_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:provider/provider.dart';

/// Trendler ve kategoriler ekran görüntüsü.
///
/// TREND_SHOT_DIR set ise `trend-*.png` ve `kategori-*.png` yazar.
/// Faz varsayılanı after. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'TrendFallback';
const _email = 'ayse.demir@example.com';
const _davaId = 'shot-act-1';
const _davaTitle = 'Gece lambası';

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
      Platform.environment['FLUTTER_ROOT'] ?? '/tmp/flutter-sdk/flutter';
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

Future<void> _seed() async {
  if (HiveDatabaseService.getRegistrationByEmail(_email) == null) {
    await HiveDatabaseService.addRegistration(
      RegistrationModel(
        id: 'shot-ayse',
        judgeName: 'Ayşe Demir',
        email: _email,
        password: 'shot',
        country: 'Türkiye',
        oath: true,
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: DateTime(2024, 6, 1),
      ),
    );
  }
  await HiveDatabaseService.getOrCreateSettings(_email);

  final openedAt =
      DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
  HiveDatabaseService.saveOpenedDava(<String, dynamic>{
    'id': _davaId,
    'userEmail': _email,
    'davaciEmail': _email,
    'davaAdi': _davaTitle,
    'adi': _davaTitle,
    'davaci': 'Ayşe Demir',
    'davali': 'Mehmet Kaya',
    'kategori': 'Komşuluk',
    'mevkii': 'Yargıç',
    'kalanSure': '117 saat',
    'davaKonusu': 'Sokak lambası günlerdir yanmıyor.',
    'openedAt': openedAt,
    'createdAt': openedAt,
    'isOpened': true,
  });

  await HiveDatabaseService.addDavaComment(
    _davaId,
    'bir@example.com',
    yorumMetni: 'Birinci yorum',
  );
  await HiveDatabaseService.addDavaComment(
    _davaId,
    'iki@example.com',
    yorumMetni: 'İkinci yorum',
  );
  await HiveDatabaseService.addDavaComment(
    _davaId,
    'uc@example.com',
    yorumMetni: 'Üçüncü yorum',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    Directory('/tmp/trend-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/trend-hive',
    );
    await HiveDatabaseService.initialize();
    await _seed();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    Widget page, {
    Size size = const Size(430, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DavaProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: RepaintBoundary(
            key: const Key('trend-shot'),
            child: page,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> waitForText(WidgetTester tester, String text) async {
    for (var i = 0; i < 30 && find.text(text).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
    }
  }

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['TREND_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('trend-shot')),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File('$dir/$name');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  void expectMinTap(WidgetTester tester, Finder finder) {
    expect(finder, findsWidgets);
    final Size size = tester.getSize(finder.first);
    expect(size.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(size.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
  }

  Finder buttonOf(String label, Type buttonType) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(buttonType),
    );
  }

  Text textOf(String data) => find.text(data).evaluate().first.widget as Text;

  test('haykırış sekmesi alfabetik davayla dolmaz', () async {
    final TrendingInsights insights =
        await const TrendingInsightsService().load(userEmail: _email);
    expect(
      insights.trendDavalar.any((item) => item.title == _davaTitle),
      isTrue,
    );
    expect(insights.trendHaykirislar, isEmpty);
  });

  Future<void> expectTrendDavalar(WidgetTester tester) async {
    await waitForText(tester, _davaTitle);
    expect(find.text(_davaTitle, skipOffstage: true), findsOneWidget);
    expect(find.text('Trend Davalar & Haykırışlar'), findsOneWidget);
    expect(
      textOf('Trend Davalar & Haykırışlar').style?.fontSize,
      SeyirTokens.typeHeadline,
    );
    expect(find.text('Komşuluk', skipOffstage: true), findsOneWidget);
    expectMinTap(tester, find.byTooltip('Menü'));
    expectMinTap(tester, find.byTooltip('Yenile'));
    expectMinTap(tester, buttonOf('Destek (0)', TextButton));
    expectMinTap(tester, buttonOf('Kınama (0)', TextButton));
    expectMinTap(
      tester,
      find.ancestor(
        of: find.textContaining('Yorum ('),
        matching: find.byType(TextButton),
      ),
    );
    await waitForText(tester, 'Tüm yorumları gör (3)');
    expect(find.text('Tüm yorumları gör (3)', skipOffstage: true), findsOneWidget);

    final Card card = tester.widget<Card>(
      find.descendant(
        of: find.byKey(const ValueKey('trend-card-$_davaId-0')),
        matching: find.byType(Card),
      ),
    );
    final RoundedRectangleBorder shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side.width, greaterThanOrEqualTo(1));
    expect(card.color, isNot(Colors.white));
  }

  testWidgets('trend davalar light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const TrendInsightsPage(userEmail: _email),
    );
    await expectTrendDavalar(tester);
    await saveShot(tester, 'trend-davalar-after-light.png');
    await releasePage(tester);
  });

  testWidgets('trend davalar dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const TrendInsightsPage(userEmail: _email),
    );
    await expectTrendDavalar(tester);
    await saveShot(tester, 'trend-davalar-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('trend haykiris empty light and dark', (tester) async {
    for (final Brightness brightness in [Brightness.light, Brightness.dark]) {
      await pumpPage(
        tester,
        _shotTheme(brightness),
        const TrendInsightsPage(userEmail: _email),
        size: const Size(430, 1100),
      );
      await waitForText(tester, _davaTitle);
      await tester.tap(find.text('Trend Haykırışlar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('Trend haykırış bulunamadı', skipOffstage: true),
        findsOneWidget,
      );
      expect(find.text(_davaTitle, skipOffstage: true), findsNothing);
      final String phase = brightness == Brightness.dark ? 'dark' : 'light';
      await saveShot(tester, 'trend-haykiris-after-$phase.png');
      await releasePage(tester);
    }
  });

  testWidgets('trend error retry light and dark', (tester) async {
    for (final Brightness brightness in [Brightness.light, Brightness.dark]) {
      await pumpPage(
        tester,
        _shotTheme(brightness),
        TrendInsightsPage(
          userEmail: _email,
          insightsLoader: ({String? userEmail}) async {
            throw StateError('trend');
          },
        ),
        size: const Size(430, 900),
      );
      await waitForText(tester, 'Trend verileri alınamadı. Lütfen tekrar deneyin.');
      expect(find.text('Tekrar dene'), findsWidgets);
      expectMinTap(tester, buttonOf('Tekrar dene', OutlinedButton));
      final String phase = brightness == Brightness.dark ? 'dark' : 'light';
      await saveShot(tester, 'trend-hata-after-$phase.png');
      await releasePage(tester);
    }
  });

  testWidgets('trend card opens dava detail', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const TrendInsightsPage(userEmail: _email),
    );
    await waitForText(tester, _davaTitle);
    await tester.tap(find.text(_davaTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SekizHukumPage), findsOneWidget);
    expect(find.text('Mehmet Kaya'), findsWidgets);
    await releasePage(tester);
  });

  testWidgets('comments stay visible without login', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const TrendInsightsPage(),
      size: const Size(430, 1500),
    );
    await waitForText(tester, 'Tüm yorumları gör (3)');
    await tester.ensureVisible(find.text('Tüm yorumları gör (3)'));
    await tester.tap(find.text('Tüm yorumları gör (3)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Birinci yorum'), findsWidgets);
    expect(find.text('Yorum yazmak için giriş yapın.'), findsOneWidget);
    expect(find.text('Yorumunu yaz...'), findsNothing);
    await releasePage(tester);
  });

  Future<void> expectCategory(WidgetTester tester) async {
    await waitForText(tester, 'Kategorisiz');
    expect(find.text('📋 Kategoriler'), findsOneWidget);
    expect(
      textOf('📋 Kategoriler').style?.fontSize,
      SeyirTokens.typeHeadline,
    );
    final TextField search = tester.widget<TextField>(find.byType(TextField));
    expect(search.style?.fontSize, SeyirTokens.typeBody);
    expect(search.decoration?.hintStyle?.fontSize, SeyirTokens.typeBody);
    expectMinTap(tester, find.byTooltip('Kapat'));
    expect(find.text('Kategorisiz'), findsOneWidget);
  }

  testWidgets('kategoriler light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const CategoryPage(userEmail: _email),
      size: const Size(430, 980),
    );
    await expectCategory(tester);
    await saveShot(tester, 'kategori-after-light.png');
    await releasePage(tester);
  });

  testWidgets('kategoriler dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const CategoryPage(userEmail: _email),
      size: const Size(430, 980),
    );
    await expectCategory(tester);
    await saveShot(tester, 'kategori-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('kategori empty search light and dark', (tester) async {
    for (final Brightness brightness in [Brightness.light, Brightness.dark]) {
      await pumpPage(
        tester,
        _shotTheme(brightness),
        const CategoryPage(userEmail: _email),
        size: const Size(430, 900),
      );
      await waitForText(tester, 'Kategorisiz');
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kategori bulunamadı'), findsOneWidget);
      expect(find.text('"zzzz" için eşleşme yok'), findsOneWidget);
      expectMinTap(tester, find.byTooltip('Aramayı temizle'));
      final String phase = brightness == Brightness.dark ? 'dark' : 'light';
      await saveShot(tester, 'kategori-bos-after-$phase.png');
      await releasePage(tester);
    }
  });

  testWidgets('kategori load error light and dark', (tester) async {
    for (final Brightness brightness in [Brightness.light, Brightness.dark]) {
      await pumpPage(
        tester,
        _shotTheme(brightness),
        CategoryPage(
          userEmail: _email,
          categoryLoader: () async => throw StateError('kategori'),
        ),
        size: const Size(430, 900),
      );
      await waitForText(tester, 'Kategoriler yüklenemedi.');
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Kategori bulunamadı'), findsNothing);
      expectMinTap(tester, buttonOf('Tekrar dene', OutlinedButton));
      final String phase = brightness == Brightness.dark ? 'dark' : 'light';
      await saveShot(tester, 'kategori-hata-after-$phase.png');
      await releasePage(tester);
    }
  });
}
