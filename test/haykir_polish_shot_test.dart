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
import 'package:its19/screens/gunun_haykirisi_page.dart';
import 'package:its19/screens/haykir_page.dart';
import 'package:its19/screens/haykirislarim_page.dart';
import 'package:its19/screens/saved_haykirlar_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/home_haykir_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haykır sayfalarının ekran görüntüsü.
///
/// HAYKIR_SHOT_DIR ve HAYKIR_SHOT_PHASE (before | after) set ise
/// `haykir-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'HaykirFallback';
const _email = 'ayse.demir@example.com';
const _emptyEmail = 'bos.haykir@example.com';
const _beforeHaykirislarim = 'HAYKIRI\u00C5\u009ELARIM';
const _beforeKatildigim = 'KATILDI\u00C4\u009EIM';
const _daySlogan = 'Sessiz kalmak, zulmü onaylamaktır.';
const _dayDetail =
    'Bugün, dünyadaki tüm haksızlıklara karşı tek bir nefes oluyoruz. '
    'Zulme karşı durmak, mazlumun yanında saf tutmak için sesini yükselt!';

bool get _after =>
    (Platform.environment['HAYKIR_SHOT_PHASE'] ?? 'after') != 'before';

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

  final createdAt =
      DateTime.now().subtract(const Duration(hours: 5)).toIso8601String();
  await HiveDatabaseService.addHaykir(<String, dynamic>{
    'id': 'shot-pub',
    'adi': 'Sokak davası',
    'slogan': 'Kaldırım bizim',
    'direme': 'İşgali bırak',
    'detaylar': 'Kaldırım işgali yüzünden çocuklar yola iniyor.',
    'userEmail': _email,
    'createdAt': createdAt,
    'isActive': 'true',
    'isPublishedOnCard': 'true',
    'isVisibleInHaykirPage': 'true',
  });
  await HiveDatabaseService.addHaykir(<String, dynamic>{
    'id': 'shot-draft',
    'adi': 'Gece lambası',
    'slogan': 'Sessiz kalmak yetmez',
    'direme': 'Işık yak',
    'detaylar': 'Sokak lambası günlerdir yanmıyor ve yol karanlık.',
    'userEmail': _email,
    'createdAt': createdAt,
    'isActive': 'true',
    'isPublishedOnCard': 'false',
    'isVisibleInHaykirPage': 'true',
  });
  await HiveDatabaseService.addHaykir(<String, dynamic>{
    'id': 'shot-saved',
    'adi': 'Bahçe duvarı',
    'slogan': 'Sınır burada biter',
    'direme': 'Duvarı indir',
    'detaylar': 'Komşu duvarı bahçeye taşmış.',
    'userEmail': _email,
    'createdAt': createdAt,
    'isActive': 'true',
    'isPublishedOnCard': 'true',
    'isVisibleInHaykirPage': 'true',
  });

  final box = HiveDatabaseService.getHaykirBox();
  await box.put('haykir_stats_shot-saved', <String, dynamic>{
    'haykirId': 'shot-saved',
    'shareCount': 2,
    'commentCount': 5,
    'retweetCount': 1,
    'likeCount': 12,
    'kinaCount': 3,
    'userLikes': <String>[],
    'userKinas': <String>[],
    'userSaves': <String>[_email],
    'userRetweets': <String>[],
    'userComments': <String>[],
    'isActive': 'false',
    'isVisibleInHaykirPage': 'false',
  });

  HiveDatabaseService.addHomeFeedPost(<String, dynamic>{
    'id': 'haykir_shot-pub',
    'type': 'haykir',
    'createdAt': createdAt,
    'authorEmail': _email,
    'payload': <String, dynamic>{
      'haykirId': 'shot-pub',
      'adi': 'Sokak davası',
      'slogan': 'Kaldırım bizim',
      'direme': 'İşgali bırak',
      'detaylar': 'Kaldırım işgali yüzünden çocuklar yola iniyor.',
      'createdAt': createdAt,
      'shareCount': 1,
      'commentCount': 2,
      'retweetCount': 0,
      'likeCount': 4,
      'kinaCount': 0,
      'isSaved': false,
      'isLiked': false,
    },
  }, userEmail: _email);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Directory('/tmp/haykir-polish-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/haykir-polish-hive',
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
      RepaintBoundary(
        key: const Key('haykir-shot'),
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
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['HAYKIR_SHOT_DIR'];
    final phase = Platform.environment['HAYKIR_SHOT_PHASE'];
    if (dir == null || dir.isEmpty || phase == null || phase.isEmpty) return;
    if (!name.contains(phase) && !name.contains('after')) return;
    if (name.contains('before') && phase != 'before') return;
    if (name.contains('after') && phase != 'after') return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('haykir-shot')),
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

  Future<void> fillCreateFields(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Gece lambası');
    await tester.enterText(fields.at(1), 'Sessiz kalmak yetmez');
    await tester.pump();
  }

  testWidgets('create form light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const HaykirPage(userEmail: _email, initialShowForm: true),
    );
    await fillCreateFields(tester);
    expect(find.text('Yeni Haykırış Oluştur'), findsOneWidget);
    expect(find.text('HAYKIR'), findsWidgets);
    if (_after) {
      expect(find.text('Kartı hazırla'), findsOneWidget);
      expect(find.text('Ekle'), findsWidgets);
      final button = tester.getSize(find.widgetWithText(ElevatedButton, 'Kartı hazırla'));
      expect(button.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      final close = tester.getSize(find.byTooltip('Kapat'));
      expect(close.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      expect(close.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    } else {
      expect(find.text('Kartı hazırla'), findsNothing);
    }
    await saveShot(tester, 'haykir-create-${_after ? 'after' : 'before'}-light.png');
    await releasePage(tester);
  });

  testWidgets('create form dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const HaykirPage(userEmail: _email, initialShowForm: true),
    );
    await fillCreateFields(tester);
    expect(find.text('Yeni Haykırış Oluştur'), findsOneWidget);
    if (_after) {
      expect(find.text('Kartı hazırla'), findsOneWidget);
      expect(textOf('Yeni Haykırış Oluştur').style?.fontSize, SeyirTokens.typeHeadline);
    }
    await saveShot(tester, 'haykir-create-${_after ? 'after' : 'before'}-dark.png');
    await releasePage(tester);
  });

  testWidgets('form button', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const HaykirPage(userEmail: _email, initialShowForm: true),
      size: const Size(430, 900),
    );
    await fillCreateFields(tester);
    await tester.scrollUntilVisible(
      find.text('Kartı hazırla'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Kartı hazırla'), findsOneWidget);
    await saveShot(tester, 'haykir-form-button-after-light.png');
    await releasePage(tester);
  });

  testWidgets('draft label', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const HaykirPage(userEmail: _email),
      size: const Size(430, 1900),
    );
    expect(find.text('Gece lambası'), findsWidgets);
    if (_after) {
      expect(find.text('Taslak'), findsWidgets);
      expect(find.byTooltip('Sil'), findsWidgets);
    } else {
      expect(find.text('Taslak'), findsNothing);
    }
    await saveShot(
      tester,
      'haykir-draft-label-${_after ? 'after' : 'before'}-light.png',
    );
    await releasePage(tester);
  });

  testWidgets('delete confirm', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const HaykirPage(userEmail: _email),
      size: const Size(430, 1900),
    );
    final sil = find.byTooltip('Sil');
    expect(sil, findsWidgets);
    await tester.ensureVisible(sil.first);
    await tester.tap(sil.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Silmek istediğine emin misin?'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sil'), findsOneWidget);
    await saveShot(tester, 'haykir-delete-confirm-after-light.png');
    await tester.tap(find.text('İptal'));
    await tester.pump();
    await releasePage(tester);
  });

  testWidgets('haykirislarim light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const HaykirislarimPage(userEmail: _email),
    );
    expect(find.text('Sokak davası'), findsWidgets);
    if (_after) {
      expect(find.text('HAYKIRIŞLARIM'), findsOneWidget);
      expect(find.text('KATILDIĞIM'), findsOneWidget);
      expect(find.text(_beforeHaykirislarim), findsNothing);
      expect(textOf('HAYKIRIŞLARIM').style?.fontSize, SeyirTokens.typeBody);
      final menu = tester.getSize(find.byTooltip('Menü'));
      expect(menu.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      expect(menu.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    } else {
      expect(find.text(_beforeHaykirislarim), findsOneWidget);
      expect(find.text(_beforeKatildigim), findsOneWidget);
    }
    await saveShot(
      tester,
      'haykir-haykirislarim-${_after ? 'after' : 'before'}-light.png',
    );
    await releasePage(tester);
  });

  testWidgets('haykirislarim dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const HaykirislarimPage(userEmail: _email),
    );
    expect(find.text('Sokak davası'), findsWidgets);
    if (_after) {
      expect(find.text('HAYKIRIŞLARIM'), findsOneWidget);
      expect(find.text('KATILDIĞIM'), findsOneWidget);
    } else {
      expect(find.text(_beforeHaykirislarim), findsOneWidget);
    }
    await saveShot(
      tester,
      'haykir-haykirislarim-${_after ? 'after' : 'before'}-dark.png',
    );
    await releasePage(tester);
  });

  testWidgets('haykirislarim empty light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const HaykirislarimPage(userEmail: _emptyEmail),
      size: const Size(430, 1400),
    );
    if (_after) {
      expect(find.text('Henüz haykırışınız yok!'), findsOneWidget);
      expect(find.text('Haykır oluştur'), findsOneWidget);
      final button = tester.getSize(find.widgetWithText(FilledButton, 'Haykır oluştur'));
      expect(button.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    } else {
      expect(find.textContaining('Hen\u00C3\u00BCz hayk'), findsOneWidget);
    }
    await saveShot(
      tester,
      'haykir-haykirislarim-empty-${_after ? 'after' : 'before'}-light.png',
    );
    if (_after) {
      await saveShot(tester, 'haykirislarim-empty-button-after-light.png');
    }
    await releasePage(tester);
  });

  testWidgets('haykirislarim empty dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const HaykirislarimPage(userEmail: _emptyEmail),
      size: const Size(430, 1400),
    );
    if (_after) {
      expect(find.text('Henüz haykırışınız yok!'), findsOneWidget);
      expect(find.text('Haykır oluştur'), findsOneWidget);
      expect(textOf('Henüz haykırışınız yok!').style?.fontSize, SeyirTokens.typeTitle);
    } else {
      expect(find.textContaining('Hen\u00C3\u00BCz hayk'), findsOneWidget);
    }
    await saveShot(
      tester,
      'haykir-haykirislarim-empty-${_after ? 'after' : 'before'}-dark.png',
    );
    await releasePage(tester);
  });

  testWidgets('kaydedilenler light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const SavedHaykirlarPage(userEmail: _email),
      size: const Size(430, 1200),
    );
    expect(find.text('Bahçe duvarı'), findsOneWidget);
    expect(find.text('Sınır burada biter'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    if (_after) {
      expect(textOf('Bahçe duvarı').style?.fontSize, SeyirTokens.typeTitle);
      expect(textOf('Sınır burada biter').style?.fontSize, SeyirTokens.typeBody);
      await tester.tap(find.text('Bahçe duvarı'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HaykirCardWidget), findsOneWidget);
      await saveShot(tester, 'haykir-kaydedilenler-detail-after-light.png');
      await releasePage(tester);
      await pumpPage(
        tester,
        _shotTheme(Brightness.light),
        const SavedHaykirlarPage(userEmail: _email),
        size: const Size(430, 1200),
      );
    }
    await saveShot(
      tester,
      'haykir-kaydedilenler-${_after ? 'after' : 'before'}-light.png',
    );
    await releasePage(tester);
  });

  testWidgets('kaydedilenler dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const SavedHaykirlarPage(userEmail: _email),
      size: const Size(430, 1200),
    );
    expect(find.text('Bahçe duvarı'), findsOneWidget);
    expect(find.text('Sınır burada biter'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    if (_after) {
      expect(textOf('Bahçe duvarı').style?.color, isNot(const Color(0xFF212121)));
    }
    await saveShot(
      tester,
      'haykir-kaydedilenler-${_after ? 'after' : 'before'}-dark.png',
    );
    await releasePage(tester);
  });

  testWidgets('gunun light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const GununHaykirisiPage(isAuthenticated: true, userEmail: _email),
      size: const Size(430, 1400),
    );
    expect(find.text('VİCDANIN SESİ'), findsOneWidget);
    expect(find.text(_daySlogan), findsOneWidget);
    expect(find.text('HAYDİ HAYKIR'), findsOneWidget);
    if (_after) {
      expect(textOf(_daySlogan).style?.fontSize, SeyirTokens.typeHeadline);
      expect(textOf('VİCDANIN SESİ').style?.fontSize, SeyirTokens.typeDisplay);
    }
    await saveShot(tester, 'haykir-gunun-${_after ? 'after' : 'before'}-light.png');
    await releasePage(tester);
  });

  testWidgets('gunun dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const GununHaykirisiPage(isAuthenticated: true, userEmail: _email),
      size: const Size(430, 1400),
    );
    expect(find.text(_daySlogan), findsOneWidget);
    expect(find.textContaining('Bugün, dünyadaki'), findsWidgets);
    if (_after) {
      expect(textOf(_daySlogan).style?.fontSize, SeyirTokens.typeHeadline);
    }
    await saveShot(tester, 'haykir-gunun-${_after ? 'after' : 'before'}-dark.png');
    await releasePage(tester);
  });

  testWidgets('gunun prefill', (tester) async {
    if (!_after) return;
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('haykir-shot'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => DavaProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _shotTheme(Brightness.light),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const GununHaykirisiPage(
                            isAuthenticated: true,
                            userEmail: _email,
                          ),
                        ),
                      );
                    },
                    child: const Text('Günü aç'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Günü aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('HAYDİ HAYKIR'), findsOneWidget);
    await tester.ensureVisible(find.text('HAYDİ HAYKIR'));
    await tester.tap(find.text('HAYDİ HAYKIR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kartı hazırla'), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.any((field) => field.controller?.text == _daySlogan), isTrue);
    expect(fields.any((field) => field.controller?.text == _dayDetail), isTrue);
    await saveShot(tester, 'gunun-haykir-prefill-after-light.png');
    await releasePage(tester);
  });
}
