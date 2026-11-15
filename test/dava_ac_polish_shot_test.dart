import 'dart:async';
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
/// `davaac3-after-*.png` yazar (seçili davalı, fotoğrafsız; ayrıca davacı fotoğraflı).
const _shotFont = 'DavaAcShot';
const _email = 'ayse.demir@example.com';
const _davaliEmail = 'mehmet.kaya@example.com';
const _silhouetteAsset = 'lib/icons/07_profil_picture_davaci.png';
const _davaciPhotoAsset = 'lib/icons/03_davala_ana_icon.png';

String? _gavelDataUrlCache;
String get _gavelDataUrl => _gavelDataUrlCache ??=
    'data:image/png;base64,${base64Encode(File(_davaciPhotoAsset).readAsBytesSync())}';

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

Future<void> _setProfilePhoto(String email, String? url) async {
  final existing = await HiveDatabaseService.getOrCreateSettings(email);
  await HiveDatabaseService.saveSettings(
    SettingsModel(
      userEmail: email,
      privacySettings: Map<String, bool>.from(existing.privacySettings),
      stringSettings: Map<String, String>.from(existing.stringSettings),
      profileImageUrl: url,
    ),
  );
}

Future<void> _setDavaciPhoto(String? url) => _setProfilePhoto(_email, url);

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
    if (HiveDatabaseService.getRegistrationByEmail(_davaliEmail) == null) {
      await HiveDatabaseService.addRegistration(
        RegistrationModel(
          id: 'shot-mehmet',
          judgeName: 'Mehmet Kaya',
          email: _davaliEmail,
          password: 'shot',
          country: 'Türkiye',
          oath: true,
          createdAt: DateTime(2024, 1, 2),
          lastLoginAt: DateTime(2024, 6, 2),
        ),
      );
    }
    await _setDavaciPhoto(null);
    await _setProfilePhoto(_davaliEmail, null);
  });

  Future<void> pumpForm(
    WidgetTester tester,
    ThemeData theme, {
    required bool collapsed,
    bool davaciPhoto = false,
  }) async {
    await tester.runAsync(() async {
      await _setDavaciPhoto(davaciPhoto ? _gavelDataUrl : null);
      await _setProfilePhoto(_davaliEmail, null);
    });
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

  Future<void> awaitImages(WidgetTester tester) async {
    final context = tester.element(find.byType(MaterialApp));
    final providers = <ImageProvider<Object>>{
      const AssetImage(_silhouetteAsset),
      const AssetImage(_davaciPhotoAsset),
    };
    for (final avatar in tester.widgetList<CircleAvatar>(find.byType(CircleAvatar))) {
      final image = avatar.backgroundImage;
      if (image != null) providers.add(image);
    }
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      providers.add(image.image);
    }
    await tester.runAsync(() async {
      for (final provider in providers) {
        await precacheImage(provider, context);
      }
      final pending = <Future<void>>[];
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        final stream = image.image.resolve(createLocalImageConfiguration(element));
        final done = Completer<void>();
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (ImageInfo _, bool __) {
            stream.removeListener(listener);
            if (!done.isCompleted) done.complete();
          },
          onError: (Object _, StackTrace? __) {
            stream.removeListener(listener);
            if (!done.isCompleted) done.complete();
          },
        );
        stream.addListener(listener);
        pending.add(done.future);
      }
      await Future.wait(pending);
    });
    await tester.pump();
    await tester.pump();
  }

  Future<void> saveShot(WidgetTester tester, String filename) async {
    final dir = Platform.environment['DAVAAC_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    await awaitImages(tester);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('dava-ac-shot')),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File('$dir/$filename');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  Finder assetImage(String asset) {
    return find.byWidgetPredicate((widget) {
      if (widget is! Image) return false;
      final provider = widget.image;
      return provider is AssetImage && provider.assetName == asset;
    });
  }

  void expectFilledForm(WidgetTester tester) {
    expect(find.text('Dava Aç'), findsOneWidget);
    expect(find.text('Dava  Aç '), findsNothing);
    expect(find.text('Ayşe Demir'), findsWidgets);
    expect(find.text('A'), findsNothing);
    expect(assetImage(_silhouetteAsset), findsNWidgets(2));
    expect(
      tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).where((avatar) => avatar.radius == 22),
      hasLength(2),
    );
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
    await saveShot(tester, 'davaac3-after-light.png');
  });

  testWidgets('expanded filled form dark', (tester) async {
    await pumpForm(tester, _shotTheme(Brightness.dark), collapsed: false);
    expectFilledForm(tester);
    await saveShot(tester, 'davaac3-after-dark.png');
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

  testWidgets('profile photo replaces the silhouette', (tester) async {
    await tester.runAsync(() async {
      await _setDavaciPhoto(_davaciPhotoAsset);
      await _setProfilePhoto(_davaliEmail, null);
    });
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final davaAdi = TextEditingController(text: 'Gece gürültüsü');
    final davali = TextEditingController(text: 'Mehmet Kaya');
    final detay = TextEditingController(text: _konu);
    final focus = FocusNode();
    addTearDown(davaAdi.dispose);
    addTearDown(davali.dispose);
    addTearDown(detay.dispose);
    addTearDown(focus.dispose);
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
              profilResmi: _davaciPhotoAsset,
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
            davaliFocusNode: focus,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('A'), findsNothing);
    expect(assetImage(_davaciPhotoAsset), findsOneWidget);
    expect(assetImage(_silhouetteAsset), findsOneWidget);
  });

  testWidgets('expanded form with davacı photo', (tester) async {
    await pumpForm(
      tester,
      _shotTheme(Brightness.light),
      collapsed: false,
      davaciPhoto: true,
    );
    expect(find.text('A'), findsNothing);
    expect(find.text('Mehmet Kaya'), findsOneWidget);
    expect(assetImage(_silhouetteAsset), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is Image && widget.image is MemoryImage),
      findsOneWidget,
    );
    await saveShot(tester, 'davaac3-after-photo-light.png');
  });
}
