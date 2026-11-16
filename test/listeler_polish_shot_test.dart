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
import 'package:its19/screens/actigim_davalar_page.dart';
import 'package:its19/screens/gelen_davalar_page.dart';
import 'package:its19/screens/katildigim_davalar_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:provider/provider.dart';

/// Açtığım, Katıldığım ve Gelen listelerinin ekran görüntüsü.
///
/// LISTELER_SHOT_DIR ve LISTELER_SHOT_PHASE (before | after) set ise
/// `listeler-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'ListelerFallback';
const _email = 'ayse.demir@example.com';
const _emptyEmail = 'bos.liste@example.com';

bool get _after =>
    (Platform.environment['LISTELER_SHOT_PHASE'] ?? 'after') != 'before';

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
  Future<void> register(String email, String name, String id) async {
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

  await register(_email, 'Ayşe Demir', 'shot-ayse');
  await register(_emptyEmail, 'Boş Liste', 'shot-bos');
  await HiveDatabaseService.getOrCreateSettings(_email);
  await HiveDatabaseService.getOrCreateSettings(_emptyEmail);

  final openedAt =
      DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
  HiveDatabaseService.saveOpenedDava(<String, dynamic>{
    'id': 'shot-act-1',
    'userEmail': _email,
    'davaciEmail': _email,
    'davaAdi': 'Gece lambası',
    'adi': 'Gece lambası',
    'davaci': 'Ayşe Demir',
    'davali': 'Mehmet Kaya',
    'kategori': 'Komşuluk',
    'davaKonusu': 'Sokak lambası günlerdir yanmıyor.',
    'openedAt': openedAt,
    'createdAt': openedAt,
    'isOpened': true,
  });

  await HiveDatabaseService.saveRejectedDava(<String, dynamic>{
    'id': 'shot-rej-1',
    'userEmail': _email,
    'adi': 'Eski şikayet',
    'davali': 'Kemal Usta',
    'mevkii': 'Yargıç',
    'kalanSure': '0 saat',
    'profilResmi': '',
    'davaKonusu': 'Reddedilen başvuru',
  });

  await HiveDatabaseService.addKatildigimDava(_email, <String, dynamic>{
    'id': 'shot-kat-1',
    'davaId': 'shot-kat-1',
    'adi': 'Sokak davası',
    'davaAdi': 'Sokak davası',
    'davaci': 'Ayşe Demir',
    'davali': 'Ali Rıza',
    'mevkii': 'Yargıç',
    'userRole': 'Yargıç',
    'kategori': 'Komşuluk',
    'davaKonusu': 'Kaldırım işgali',
    'openedAt': openedAt,
    'createdAt': openedAt,
    'userEmail': _email,
  });

  final gelenAt =
      DateTime.now().subtract(const Duration(hours: 3)).toIso8601String();
  HiveDatabaseService.addIncomingDava(_email, <String, dynamic>{
    'id': 'shot-gel-1',
    'adi': 'Bahçe duvarı',
    'davaAdi': 'Bahçe duvarı',
    'davali': 'Selim Aras',
    'davaci': 'Ayşe Demir',
    'mevkii': '',
    'kalanSure': '117 saat',
    'profilResmi': 'lib/icons/03_davala_ana_icon.png',
    'davaKonusu': 'Duvar sınırı',
    'createdAt': gelenAt,
    'openedAt': gelenAt,
    'lifecycleStatus': 'AwaitingRole',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    Directory('/tmp/listeler-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/listeler-hive',
    );
    await HiveDatabaseService.initialize();
    await _seed();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    Widget page, {
    Size size = const Size(430, 1680),
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
            key: const Key('listeler-shot'),
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
    for (var i = 0; i < 25 && find.text(text).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
    }
  }

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['LISTELER_SHOT_DIR'];
    final phase = Platform.environment['LISTELER_SHOT_PHASE'];
    if (dir == null || dir.isEmpty || phase == null || phase.isEmpty) return;
    if (name.contains('empty') && phase != 'after') return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('listeler-shot')),
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

  Text textOf(String data) => find.text(data).evaluate().first.widget as Text;

  void expectActigimCopy() {
    expect(find.text('Gece lambası'), findsWidgets);
    expect(find.text('Eski şikayet'), findsWidgets);
    expect(find.textContaining('RED EDİLEN DAVALAR'), findsOneWidget);
    expect(find.text('Ayşe Demir'), findsWidgets);
    if (_after) {
      expect(find.text('Açtığım Davalar'), findsOneWidget);
      expect(find.text('|| AÇTIĞIM DAVALAR ||'), findsNothing);
      final title = textOf('Açtığım Davalar');
      expect(title.style?.fontSize, SeyirTokens.typeHeadline);
    } else {
      expect(find.text('|| AÇTIĞIM DAVALAR ||'), findsOneWidget);
    }
  }

  void expectKatildigimCopy() {
    expect(find.text('Sokak davası'), findsWidgets);
    expect(find.text('Ayşe Demir'), findsWidgets);
    if (_after) {
      expect(find.text('Katıldığım Davalar'), findsOneWidget);
      expect(find.text('|| KATILDIĞIM DAVALAR ||'), findsNothing);
      expect(
        textOf('Katıldığım Davalar').style?.fontSize,
        SeyirTokens.typeHeadline,
      );
    } else {
      expect(find.text('|| KATILDIĞIM DAVALAR ||'), findsOneWidget);
    }
  }

  void expectGelenCopy() {
    expect(find.text('Bahçe duvarı'), findsOneWidget);
    expect(find.text('Ayşe Demir'), findsWidgets);
    expect(find.text('Selim Aras'), findsOneWidget);
    expect(find.text('KABUL ET'), findsOneWidget);
    expect(find.text('RED ET'), findsOneWidget);
    expect(find.text('Dava Adı'), findsOneWidget);
    expect(find.text('Davalı'), findsOneWidget);
    if (_after) {
      expect(find.text('Gelen Davalar'), findsOneWidget);
      expect(find.text(' || GELEN DAVALAR ||'), findsNothing);
      final title = textOf('Gelen Davalar');
      expect(title.style?.fontSize, SeyirTokens.typeHeadline);
      final badge = find.byTooltip('Gelen dava özeti');
      expect(badge, findsOneWidget);
    } else {
      expect(find.text(' || GELEN DAVALAR ||'), findsOneWidget);
    }
  }

  testWidgets('actigim list light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ActigimDavalarPage(userEmail: _email),
    );
    expectActigimCopy();
    await saveShot(
      tester,
      'listeler-actigim-${_after ? 'after' : 'before'}-light.png',
    );
    await releasePage(tester);
  });

  testWidgets('actigim list dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const ActigimDavalarPage(userEmail: _email),
    );
    expectActigimCopy();
    await saveShot(
      tester,
      'listeler-actigim-${_after ? 'after' : 'before'}-dark.png',
    );
    await releasePage(tester);
  });

  testWidgets('katildigim list light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const KatildigimDavalarPage(userEmail: _email),
    );
    expectKatildigimCopy();
    await saveShot(
      tester,
      'listeler-katildigim-${_after ? 'after' : 'before'}-light.png',
    );
    await releasePage(tester);
  });

  testWidgets('katildigim list dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const KatildigimDavalarPage(userEmail: _email),
    );
    expectKatildigimCopy();
    await saveShot(
      tester,
      'listeler-katildigim-${_after ? 'after' : 'before'}-dark.png',
    );
    await releasePage(tester);
  });

  testWidgets('gelen list light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const GelenDavalarPage(userEmail: _email),
      size: const Size(430, 1280),
    );
    await waitForText(tester, 'Bahçe duvarı');
    expectGelenCopy();
    await saveShot(
      tester,
      'listeler-gelen-${_after ? 'after' : 'before'}-light.png',
    );
    await releasePage(tester);
  });

  testWidgets('gelen list dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const GelenDavalarPage(userEmail: _email),
      size: const Size(430, 1280),
    );
    await waitForText(tester, 'Bahçe duvarı');
    expectGelenCopy();
    await saveShot(
      tester,
      'listeler-gelen-${_after ? 'after' : 'before'}-dark.png',
    );
    await releasePage(tester);
  });

  testWidgets('gelen empty light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const GelenDavalarPage(userEmail: _emptyEmail),
      size: const Size(430, 900),
    );
    if (_after) {
      expect(find.text('Gelen dava yok'), findsOneWidget);
      expect(find.text('Size atanan davalar burada görünür'), findsOneWidget);
      expect(find.text('Gelen Davalar'), findsOneWidget);
    }
    await saveShot(tester, 'listeler-gelen-empty-after-light.png');
    await releasePage(tester);
  });

  testWidgets('collapsed header tap targets', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ActigimDavalarPage(
        userEmail: _email,
        initiallyCollapsed: true,
      ),
      size: const Size(430, 720),
    );
    final arrow = find.byTooltip('Arayüzü Aç');
    expect(arrow, findsOneWidget);
    if (_after) {
      final size = tester.getSize(arrow);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(find.text('Açtığım Davalar'), findsNothing);
    }
    await releasePage(tester);

    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const KatildigimDavalarPage(
        userEmail: _email,
        initiallyCollapsed: true,
      ),
      size: const Size(430, 720),
    );
    expect(find.byTooltip('Arayüzü Aç'), findsOneWidget);
    if (_after) {
      final size = tester.getSize(find.byTooltip('Arayüzü Aç'));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    await releasePage(tester);
  });
}
