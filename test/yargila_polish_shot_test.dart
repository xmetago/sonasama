import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/models/sekiz_hukum_arguments.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/cezalar_page.dart';
import 'package:its19/screens/hukum_gift_selection_page.dart';
import 'package:its19/screens/sekiz_hukum_page.dart';
import 'package:its19/screens/yargila_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/delil_surface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yargıla, 8-Hüküm, Cezalar ve hediye seçiminin ekran görüntüsü.
///
/// YARGILA_SHOT_DIR ve YARGILA_SHOT_PHASE (before | after) set ise
/// `yargila-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'YargilaFallback';
const _email = 'ayse.demir@example.com';
const _emptyEmail = 'bos.yargila@example.com';
const _davaId = 'shot-yargila-1';

bool get _after =>
    (Platform.environment['YARGILA_SHOT_PHASE'] ?? 'after') != 'before';

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

Future<void> _register(String email, String name, String id) async {
  if (HiveDatabaseService.getRegistrationByEmail(email) != null) return;
  await HiveDatabaseService.addRegistration(
    RegistrationModel(
      id: id,
      judgeName: name,
      email: email,
      password: 'shot',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime(2024, 1, 1),
      lastLoginAt: DateTime(2024, 6, 1),
    ),
  );
}

Future<void> _seed() async {
  await _register(_email, 'Ayşe Demir', 'shot-ayse');
  await _register(_emptyEmail, 'Boş Liste', 'shot-bos');
  await HiveDatabaseService.getOrCreateSettings(_email);
  await HiveDatabaseService.getOrCreateSettings(_emptyEmail);

  final acceptedAt =
      DateTime.now().subtract(const Duration(hours: 6)).toIso8601String();
  await HiveDatabaseService.saveAcceptedDava(<String, dynamic>{
    'id': _davaId,
    'userEmail': _email,
    'adi': 'Gece lambası',
    'davaAdi': 'Gece lambası',
    'davaci': 'Ayşe Demir',
    'davali': 'Mehmet Kaya',
    'mevkii': 'Yargıç',
    'kalanSure': '162 saat',
    'profilResmi': 'lib/icons/03_davala_ana_icon.png',
    'davaKonusu': 'Sokak lambası günlerdir yanmıyor ve yol karanlık.',
    'acceptedAt': acceptedAt,
    'createdAt': acceptedAt,
  });
  HiveDatabaseService.saveOpenedDava(<String, dynamic>{
    'id': _davaId,
    'userEmail': _email,
    'davaciEmail': _email,
    'davaAdi': 'Gece lambası',
    'adi': 'Gece lambası',
    'davaci': 'Ayşe Demir',
    'davali': 'Mehmet Kaya',
    'kategori': 'Komşuluk',
    'davaKonusu': 'Sokak lambası günlerdir yanmıyor ve yol karanlık.',
    'openedAt': acceptedAt,
    'createdAt': acceptedAt,
    'isOpened': true,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Directory hiveDir = Directory('/tmp/yargila-hive');
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
    hiveDir.createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/yargila-hive',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/in_app_purchase'),
      (MethodCall call) async => false,
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
        key: const Key('yargila-shot'),
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
    // Geri sayaç 1 sn'de bir, Play faturalandırma 4 sn zaman aşımı kurar.
    await tester.pump(const Duration(seconds: 5));
  }

  void expectTapHeight(WidgetTester tester, Finder finder) {
    expect(finder, findsWidgets);
    expect(
      tester.getSize(finder.first).height,
      greaterThanOrEqualTo(SeyirTokens.tapTarget),
    );
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['YARGILA_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('yargila-shot')),
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

  String shot(String page, String brightness) =>
      'yargila-$page-${_after ? 'after' : 'before'}-$brightness.png';

  Future<void> shotYargila(
    WidgetTester tester,
    Brightness brightness,
    String email,
    String page,
    String needle,
  ) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      YargilaPage(userEmail: email),
      size: const Size(420, 1800),
    );
    await waitForText(tester, needle);
    expect(find.text(needle), findsWidgets);
    if (_after && page == 'page') {
      expectTapHeight(tester, find.widgetWithText(ElevatedButton, 'Deliller'));
      expectTapHeight(tester, find.widgetWithText(ElevatedButton, '8-HÜKÜM'));
      final Finder yargilaMenu = find.byWidgetPredicate((Widget widget) {
        if (widget is! IconButton) return false;
        final Widget icon = widget.icon;
        return icon is Icon && icon.icon == MdiIcons.menuOpen && icon.size == 19;
      });
      await tester.ensureVisible(yargilaMenu);
      await tester.tap(yargilaMenu);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final IgnorePointer? pointer = tester
          .element(find.byIcon(Icons.save_outlined))
          .findAncestorWidgetOfExactType<IgnorePointer>();
      expect(pointer?.ignoring, isTrue);
      await tester.tap(yargilaMenu);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }
    if (_after && page == 'empty') {
      expect(find.byType(DelilSoftEmpty), findsOneWidget);
    }
    await saveShot(tester, shot(page, brightness.name));
    await releasePage(tester);
  }

  testWidgets('yargila with data light', (tester) async {
    await shotYargila(
      tester,
      Brightness.light,
      _email,
      'page',
      'Gece lambası',
    );
  });

  testWidgets('yargila with data dark', (tester) async {
    await shotYargila(
      tester,
      Brightness.dark,
      _email,
      'page',
      'Gece lambası',
    );
  });

  testWidgets('yargila empty light', (tester) async {
    await shotYargila(
      tester,
      Brightness.light,
      _emptyEmail,
      'empty',
      'Henüz yargılanacak dava yok',
    );
  });

  testWidgets('yargila empty dark', (tester) async {
    await shotYargila(
      tester,
      Brightness.dark,
      _emptyEmail,
      'empty',
      'Henüz yargılanacak dava yok',
    );
  });

  Future<void> shotHukum(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      SekizHukumPage(
        userEmail: _email,
        arguments: SekizHukumArguments(
          davaId: _davaId,
          davaAdi: 'Gece lambası',
          davaDavali: 'Mehmet Kaya',
          davaDavaci: 'Ayşe Demir',
          davaGorev: 'Yargıç',
          kalanSure: '162 saat',
          openedAt: DateTime(2026, 11, 10, 9),
        ),
      ),
    );
    await waitForText(tester, 'Gece lambası');
    expect(find.text('Gece lambası'), findsWidgets);
    await saveShot(tester, shot('sekiz-hukum', brightness.name));
    await releasePage(tester);
  }

  testWidgets('sekiz hukum light', (tester) async {
    await shotHukum(tester, Brightness.light);
  });

  testWidgets('sekiz hukum dark', (tester) async {
    await shotHukum(tester, Brightness.dark);
  });

  Future<void> shotCezalar(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      CezalarPage(
        userEmail: _email,
        davaId: _davaId,
        davaAdi: 'Gece lambası',
        davaDavali: 'Mehmet Kaya',
        davaDavaci: 'Ayşe Demir',
        davaGorev: 'Yargıç',
        kalanSure: '162 saat',
        davaOpenedAt: DateTime(2026, 11, 10, 9),
      ),
      size: const Size(420, 1900),
    );
    await waitForText(tester, 'Gece lambası');
    expect(find.text('Gece lambası'), findsWidgets);
    expect(find.text('Şeytanın Hileleri'), findsNothing);
    if (_after) {
      final Text title = tester.widget<Text>(find.text('CEZALAR'));
      expect(title.data, 'CEZALAR');
      expect(title.style?.fontSize, SeyirTokens.typeHeadline);
      expect(title.style?.letterSpacing ?? 0, 0);
    }
    await saveShot(tester, shot('cezalar', brightness.name));
    await releasePage(tester);
  }

  testWidgets('cezalar light', (tester) async {
    await shotCezalar(tester, Brightness.light);
  });

  testWidgets('cezalar dark', (tester) async {
    await shotCezalar(tester, Brightness.dark);
  });

  Future<void> shotCezalarNoCase(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      CezalarPage(userEmail: _email),
      size: const Size(420, 1400),
    );
    await tester.pump(const Duration(milliseconds: 300));
    if (_after) {
      expect(find.text('Şeytanın Hileleri'), findsNothing);
      expect(find.text('Edip Yüksel'), findsNothing);
      expect(find.text('Seçili dava yok'), findsOneWidget);
      await saveShot(
        tester,
        'cezalar-no-case-empty-after-${brightness.name}.png',
      );
    } else {
      expect(find.text('Şeytanın Hileleri'), findsWidgets);
      await saveShot(tester, shot('cezalar-nocase', brightness.name));
    }
    await releasePage(tester);
  }

  testWidgets('cezalar no case light', (tester) async {
    await shotCezalarNoCase(tester, Brightness.light);
  });

  testWidgets('cezalar no case dark', (tester) async {
    await shotCezalarNoCase(tester, Brightness.dark);
  });

  Future<void> shotGift(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const HukumGiftSelectionPage(
        userEmail: _email,
        davaId: _davaId,
        davaAdi: 'Gece lambası',
      ),
      size: const Size(420, 1600),
    );
    await waitForText(tester, 'Masraflat');
    expect(find.text('Masraflat'), findsOneWidget);
    if (_after) {
      final Text title = tester.widget<Text>(find.text('MASRAF — HEDİYE'));
      expect(title.style?.fontSize, SeyirTokens.typeHeadline);
      expect(title.style?.letterSpacing ?? 0, 0);
      expect(find.text('Henüz favori yok'), findsNothing);
    }
    await saveShot(tester, shot('hediye', brightness.name));
    await releasePage(tester);
  }

  testWidgets('hediye light', (tester) async {
    await shotGift(tester, Brightness.light);
  });

  testWidgets('hediye dark', (tester) async {
    await shotGift(tester, Brightness.dark);
  });

  Future<void> shotLoading(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const YargilaPage(userEmail: _email, forceLoading: true),
      size: const Size(420, 1400),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Henüz yargılanacak dava yok'), findsNothing);
    await saveShot(tester, 'yargila-loading-after-${brightness.name}.png');
    await releasePage(tester);
  }

  testWidgets('yargila loading light', (tester) async {
    if (!_after) return;
    await shotLoading(tester, Brightness.light);
  });

  testWidgets('yargila loading dark', (tester) async {
    if (!_after) return;
    await shotLoading(tester, Brightness.dark);
  });

  Future<void> shotLoadError(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const YargilaPage(userEmail: _email, forceLoadError: true),
      size: const Size(420, 1400),
    );
    await waitForText(tester, 'Tekrar dene');
    expect(find.text('Yargılanacak davalar yüklenemedi'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Henüz yargılanacak dava yok'), findsNothing);
    expect(find.byType(DelilLoadError), findsOneWidget);
    await saveShot(tester, 'yargila-error-retry-after-${brightness.name}.png');
    await releasePage(tester);
  }

  testWidgets('yargila error retry light', (tester) async {
    if (!_after) return;
    await shotLoadError(tester, Brightness.light);
  });

  testWidgets('yargila error retry dark', (tester) async {
    if (!_after) return;
    await shotLoadError(tester, Brightness.dark);
  });

  Future<void> shotKaydaGecir(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const YargilaPage(userEmail: _email),
      size: const Size(420, 2200),
    );
    await waitForText(tester, 'Gece lambası');
    final Finder konu = find.text('Dava Konusu:');
    expect(konu, findsWidgets);
    await tester.ensureVisible(konu.first);
    await tester.tap(konu.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final Finder kayda = find.text('Hükmümü Kayda Geçir');
    expect(kayda, findsWidgets);
    await tester.ensureVisible(kayda.first);
    await tester.tap(kayda.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('8-HÜKÜM'), findsWidgets);
    expect(find.text('Gece lambası'), findsWidgets);
    expect(find.textContaining('yakında eklenecek'), findsNothing);
    await saveShot(tester, 'yargila-kayda-gecir-nav-after-${brightness.name}.png');
    await releasePage(tester);
  }

  testWidgets('yargila kayda gecir light', (tester) async {
    if (!_after) return;
    await shotKaydaGecir(tester, Brightness.light);
  });

  testWidgets('yargila kayda gecir dark', (tester) async {
    if (!_after) return;
    await shotKaydaGecir(tester, Brightness.dark);
  });
}
