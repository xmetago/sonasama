import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/models/settings_model.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/dava_ac_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/common_header_widgets.dart';
import 'package:provider/provider.dart';

/// Dava Aç formunun dolu hali. DAVAAC_SHOT_DIR set ise
/// `davaac2-<phase>-<brightness>.png` yazar. phase: before | after.
const _shotFont = 'DavaAcShot';
const _email = 'ayse.demir@example.com';

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
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      '/tmp/flutter-sdk/flutter';
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

String get _konu {
  const sentence =
      'Komşum her gece yüksek sesle müzik açıyor ve çocuklar uyuyamıyor. ';
  return (sentence * 8).trim();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    Directory('/tmp/davaac-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/davaac-hive',
    );
    await HiveDatabaseService.initialize();
    final existingSettings = await HiveDatabaseService.getOrCreateSettings(_email);
    await HiveDatabaseService.saveSettings(
      SettingsModel(
        userEmail: _email,
        privacySettings: existingSettings.privacySettings,
        stringSettings: existingSettings.stringSettings,
      ),
    );
    final existing = HiveDatabaseService.getRegistrationByEmail(_email);
    if (existing == null) {
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
  });

  Future<void> pumpForm(
    WidgetTester tester,
    ThemeData theme, {
    required bool collapsed,
  }) async {
    tester.view.physicalSize = const Size(420, 1080);
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
            key: const Key('dava-ac-shot'),
            child: DavaAcPage(
              userEmail: _email,
              selectedCategory: 'Komşuluk',
              selectedSubCategory: 'Gürültü',
              initialCollapsed: collapsed,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final adi = find.byType(TextField).at(0);
    final davali = find.byType(TextField).at(1);
    final konu = find.byType(TextField).at(2);
    await tester.enterText(adi, 'Gece gürültüsü');
    await tester.enterText(davali, 'Mehmet Kaya');
    await tester.enterText(konu, _konu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> saveShot(WidgetTester tester, String brightness) async {
    final dir = Platform.environment['DAVAAC_SHOT_DIR'];
    final phase = Platform.environment['DAVAAC_SHOT_PHASE'];
    if (dir == null || dir.isEmpty || phase == null || phase.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('dava-ac-shot')),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File('$dir/davaac2-$phase-$brightness.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  void expectFilledForm(WidgetTester tester) {
    expect(find.text('Dava Aç'), findsOneWidget);
    expect(find.text('Dava  Aç '), findsNothing);
    expect(find.text('Ayşe Demir'), findsWidgets);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('DAVALA'), findsOneWidget);
    expect(find.text('Gece gürültüsü'), findsWidgets);
    expect(find.text('Mehmet Kaya'), findsOneWidget);
    expect(find.text('Komşuluk > Gürültü'), findsOneWidget);
    expect(find.text('${_konu.length} / 285'), findsOneWidget);
    expect(find.byTooltip('Kaydet'), findsOneWidget);
    expect(find.byTooltip('Delil Ekle'), findsOneWidget);

    final davaliField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(davaliField.decoration?.hintText, 'Üye ara (en az 4 harf)');

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'DAVALA'),
    );
    expect(button.onPressed, isNotNull);
    expect(
      button.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFF34DFAE),
    );

    for (final tooltip in ['Kaydet', 'Delil Ekle']) {
      final icon = tester.widget<IconButton>(
        find.descendant(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );
      final size = icon.style?.fixedSize?.resolve(const <WidgetState>{});
      expect(size, const Size(48, 48));
    }
  }

  testWidgets('expanded filled form light', (tester) async {
    await pumpForm(tester, _shotTheme(Brightness.light), collapsed: false);
    expectFilledForm(tester);
    await saveShot(tester, 'light');
  });

  testWidgets('expanded filled form dark', (tester) async {
    await pumpForm(tester, _shotTheme(Brightness.dark), collapsed: false);
    expectFilledForm(tester);
    await saveShot(tester, 'dark');
  });

  testWidgets('collapsed header uses the page title', (tester) async {
    await pumpForm(tester, _shotTheme(Brightness.light), collapsed: true);
    expect(find.byType(CollapsedWbHeaderRow), findsOneWidget);
    expect(find.byType(TreeMenuPageheadlines), findsNothing);
    expect(find.text('Dava Aç'), findsOneWidget);
    expect(find.text('Dava  Aç '), findsNothing);
  });

  testWidgets('disabled DAVALA stays readable', (tester) async {
    await pumpForm(tester, _shotTheme(Brightness.light), collapsed: false);
    await tester.enterText(find.byType(TextField).at(2), 'kısa');
    await tester.pump();
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'DAVALA'),
    );
    expect(button.onPressed, isNull);
    expect(
      button.style?.foregroundColor?.resolve(const <WidgetState>{WidgetState.disabled}),
      SeyirTokens.neutral700,
    );
    expect(
      button.style?.backgroundColor?.resolve(const <WidgetState>{WidgetState.disabled}),
      SeyirTokens.neutral200,
    );
  });

  testWidgets('profile photo replaces the initial', (tester) async {
    await tester.runAsync(() async {
      await HiveDatabaseService.updateProfileInfo(
        _email,
        profileImageUrl: 'lib/icons/03_davala_ana_icon.png',
      );
    });
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final davaAdi = TextEditingController(text: 'Gece gürültüsü');
    final davali = TextEditingController(text: 'Mehmet Kaya');
    final detay = TextEditingController(text: _konu);
    addTearDown(davaAdi.dispose);
    addTearDown(davali.dispose);
    addTearDown(detay.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: _shotTheme(Brightness.light),
        home: Scaffold(
          body: FiveCardCaseInformation(
            dava: Dava(
              id: 'shot',
              adi: 'Gece gürültüsü',
              davali: 'Mehmet Kaya',
              mevkii: 'Davalı',
              kalanSure: '.../.../.....',
              profilResmi: 'lib/icons/03_davala_ana_icon.png',
              davaKonusu: _konu,
              davaKategorisi: 'Komşuluk > Gürültü',
              davaci: 'Ayşe Demir',
            ),
            isExpanded: true,
            davaliController: davali,
            filteredUsers: const [],
            showUserSuggestions: false,
            onSelectUser: (_) {},
            isWhoboomUser: true,
            userEmail: _email,
            davaDetayController: detay,
            davaAdiController: davaAdi,
            canDavala: true,
            onSaveDava: () {},
            onOpenDava: () {},
            onCheckboxChanged: (_) {},
            showDavaAdiError: false,
            davaAdiErrorText: null,
            showDavaliError: false,
            davaliErrorText: null,
            davaliFocusNode: FocusNode(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('A'), findsNothing);
    expect(find.byType(Image), findsWidgets);
  });
}
