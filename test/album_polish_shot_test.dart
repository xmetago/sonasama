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
import 'package:its19/screens/album_goruntule_page.dart';
import 'package:its19/screens/album_olustur_page.dart';
import 'package:its19/screens/albumler_liste_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/seyir_defteri_menu_items.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Albüm listesi, oluşturma ve galeri ekran görüntüsü.
///
/// ALBUM_SHOT_DIR ve ALBUM_SHOT_PHASE (before | after) set ise
/// `album-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'AlbumFallback';
const _email = 'ayse.demir@example.com';
const _description = 'Ege kıyısında bir hafta';
const _albumName = 'Tatil Fotoğrafları';
const _emptyAlbumName = 'Mahkeme Notları';

bool get _after =>
    (Platform.environment['ALBUM_SHOT_PHASE'] ?? 'after') != 'before';

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

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
      loader
          .addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
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

String _tatilId = '';
String _bosId = '';

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

  final existing = HiveDatabaseService.getAlbums(_email);
  for (final album in existing) {
    await HiveDatabaseService.deleteAlbum(albumId: album.id, userEmail: _email);
  }
  _tatilId = '';
  _bosId = '';

  if (_tatilId.isEmpty) {
    _tatilId = await HiveDatabaseService.createAlbum(
      name: _albumName,
      userEmail: _email,
      description: _description,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await HiveDatabaseService.addImageToAlbum(
      albumId: _tatilId,
      imageUrl: 'data:image/png;base64,${base64Encode(_png)}',
      title: 'Kıyı',
      fileSize: 240 * 1024,
    );
    _bosId = await HiveDatabaseService.createAlbum(
      name: _emptyAlbumName,
      userEmail: _email,
      description: 'Duruşma arası çizimler',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Directory('/tmp/album-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/album-hive',
    );
    await HiveDatabaseService.initialize();
    await _seed();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    Widget page, {
    Size size = const Size(480, 2000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('album-shot'),
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
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['ALBUM_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('album-shot')),
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
      'album-$page-${_after ? 'after' : 'before'}-$brightness.png';

  Finder albumSearch() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Albüm ara...',
    );
  }

  Future<void> expectListChrome(
      WidgetTester tester, Brightness brightness) async {
    await waitForText(tester, 'ALBÜMLERİM');
    expect(find.text('ALBÜMLERİM'), findsOneWidget);
    expect(find.text(_albumName), findsOneWidget);
    expect(find.text(_emptyAlbumName), findsOneWidget);
    if (!_after) return;

    final title = tester.widget<Text>(find.text('ALBÜMLERİM'));
    expect(title.style?.fontSize, SeyirTokens.typeHeadline);
    final name = tester.widget<Text>(find.text(_albumName));
    expect(name.style?.fontSize, SeyirTokens.typeTitle);

    for (final tooltip in ['Geri', 'Sırala', 'Toplu İşlem', 'Yeni Albüm']) {
      final box = tester.getSize(find.byTooltip(tooltip));
      expect(box.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      expect(box.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    }
    final viewTip = find.byTooltip('Liste Görünümü');
    expect(viewTip, findsOneWidget);
    final viewSize = tester.getSize(viewTip);
    expect(viewSize.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));

    final backIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byTooltip('Geri'),
        matching: find.byIcon(Icons.arrow_back),
      ),
    );
    expect(backIcon.color, isNot(Colors.black));

    final field = tester.widget<TextField>(albumSearch());
    expect(field.decoration?.fillColor, isNot(Colors.grey[50]));
    if (brightness == Brightness.dark) {
      expect(field.decoration?.fillColor, isNot(const Color(0xFFFAFAFA)));
    }

    final card = tester.widget<Card>(find.byType(Card).first);
    final shape = card.shape! as RoundedRectangleBorder;
    expect(
      shape.side.color,
      SeyirPalette.of(tester.element(find.byType(Card).first)).border,
    );
    expect(card.color, isNotNull);
  }

  testWidgets('album list light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(userEmail: _email),
    );
    await expectListChrome(tester, Brightness.light);
    await saveShot(tester, shot('liste', 'light'));
    await releasePage(tester);
  });

  testWidgets('album list dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const AlbumlerListePage(userEmail: _email),
    );
    await expectListChrome(tester, Brightness.dark);
    await saveShot(tester, shot('liste', 'dark'));
    await releasePage(tester);
  });

  testWidgets('album list empty light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(userEmail: 'bos.album@example.com'),
      size: const Size(480, 1600),
    );
    await waitForText(tester, 'Henüz albüm oluşturmadınız');
    expect(find.text('Henüz albüm oluşturmadınız'), findsOneWidget);
    await saveShot(tester, shot('liste-bos', 'light'));
    await releasePage(tester);
  });

  testWidgets('album list empty dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const AlbumlerListePage(userEmail: 'bos.album@example.com'),
      size: const Size(480, 1600),
    );
    await waitForText(tester, 'Henüz albüm oluşturmadınız');
    await saveShot(tester, shot('liste-bos', 'dark'));
    await releasePage(tester);
  });

  testWidgets('album search empty light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(userEmail: _email),
    );
    await waitForText(tester, _albumName);
    await tester.enterText(albumSearch(), 'zzzz-yok');
    await tester.pump();
    await waitForText(tester, 'Arama sonucu bulunamadı');
    expect(find.text('Arama sonucu bulunamadı'), findsOneWidget);
    await saveShot(tester, shot('liste-arama', 'light'));
    await releasePage(tester);
  });

  testWidgets('album search empty dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const AlbumlerListePage(userEmail: _email),
    );
    await waitForText(tester, _albumName);
    await tester.enterText(albumSearch(), 'zzzz-yok');
    await tester.pump();
    await waitForText(tester, 'Arama sonucu bulunamadı');
    await saveShot(tester, shot('liste-arama', 'dark'));
    await releasePage(tester);
  });

  testWidgets('album login and load error', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(),
      size: const Size(480, 1500),
    );
    if (_after) {
      await waitForText(tester, 'Giriş gerekli');
      expect(find.text('Giriş gerekli'), findsOneWidget);
      expect(find.text('Henüz albüm oluşturmadınız'), findsNothing);
    }
    await saveShot(tester, shot('liste-giris', 'light'));
    await releasePage(tester);

    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const AlbumlerListePage(userEmail: _email, forceLoadError: true),
      size: const Size(480, 1500),
    );
    if (_after) {
      await waitForText(tester, 'Tekrar dene');
      expect(find.text('Albümler yüklenemedi'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    }
    await saveShot(tester, shot('liste-hata', 'dark'));
    await releasePage(tester);
  });

  testWidgets('album create light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      AlbumOlusturPage(userEmail: _email, existingAlbumId: _tatilId),
      size: const Size(480, 1700),
    );
    await waitForText(tester, 'ALBÜM DÜZENLE');
    expect(find.text('ALBÜM DÜZENLE'), findsOneWidget);
    if (_after) {
      await waitForText(tester, 'Açıklama');
      expect(find.text('Açıklama'), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(
        fields.any((field) => field.controller?.text == _description),
        isTrue,
      );
      expect(
        fields.any((field) => field.controller?.text == _albumName),
        isTrue,
      );
      final save = tester.getSize(find.byTooltip('Albümü Kaydet'));
      expect(save.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      final album = tester.getSize(find.byTooltip('Albümlerim'));
      expect(album.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      final add =
          tester.getSize(find.widgetWithText(ElevatedButton, 'Resim Ekle'));
      expect(add.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      final nameField = fields.firstWhere(
        (field) => field.decoration?.labelText == 'Albüm Adı *',
      );
      expect(nameField.decoration?.fillColor, isNot(Colors.grey[50]));
    }
    await saveShot(tester, shot('olustur', 'light'));
    await releasePage(tester);
  });

  testWidgets('album create dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      AlbumOlusturPage(userEmail: _email, existingAlbumId: _tatilId),
      size: const Size(480, 1700),
    );
    await waitForText(tester, 'ALBÜM DÜZENLE');
    if (_after) {
      await waitForText(tester, _description);
    }
    await saveShot(tester, shot('olustur', 'dark'));
    await releasePage(tester);
  });

  testWidgets('album gallery light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      AlbumGoruntulePage(userEmail: _email, albumId: _tatilId),
      size: const Size(480, 900),
    );
    await waitForText(tester, _albumName);
    await waitForText(tester, '1 / 1');
    expect(find.text('1 / 1'), findsOneWidget);
    if (_after) {
      expect(find.text('Kıyı'), findsOneWidget);
      final counter = tester.widget<Text>(find.text('1 / 1'));
      expect(counter.style?.fontSize, SeyirTokens.typeTitle);
    }
    await saveShot(tester, shot('galeri', 'light'));
    await releasePage(tester);
  });

  testWidgets('album gallery dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      AlbumGoruntulePage(userEmail: _email, albumId: _tatilId),
      size: const Size(480, 900),
    );
    await waitForText(tester, '1 / 1');
    await saveShot(tester, shot('galeri', 'dark'));
    await releasePage(tester);
  });

  testWidgets('album gallery empty', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      AlbumGoruntulePage(userEmail: _email, albumId: _bosId),
      size: const Size(480, 1100),
    );
    await waitForText(tester, 'Albümde resim bulunmuyor');
    expect(find.text('Albümde resim bulunmuyor'), findsOneWidget);
    await saveShot(tester, shot('galeri-bos', 'light'));
    await releasePage(tester);

    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      AlbumGoruntulePage(userEmail: _email, albumId: _bosId),
      size: const Size(480, 1100),
    );
    await waitForText(tester, 'Albümde resim bulunmuyor');
    await saveShot(tester, shot('galeri-bos', 'dark'));
    await releasePage(tester);
  });

  testWidgets('tap opens gallery and edit stays in menu', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(userEmail: _email),
    );
    await waitForText(tester, _albumName);
    final card = find.text(_albumName).first;
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    if (_after) {
      await waitForText(tester, '1 / 1');
      expect(find.text('ALBÜM DÜZENLE'), findsNothing);
      expect(find.text('Kıyı'), findsOneWidget);
    }
    await releasePage(tester);
  });

  testWidgets('edit stays in the options menu', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(userEmail: _email),
    );
    await waitForText(tester, _albumName);
    await tester.longPress(find.text(_albumName).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Düzenle'), findsOneWidget);
    await tester.tap(find.text('Düzenle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await waitForText(tester, 'ALBÜM DÜZENLE');
    await waitForText(tester, 'Açıklama');
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(
      fields.any((field) => field.controller?.text == _description),
      isTrue,
    );
    expect(
      fields.any((field) => field.controller?.text == _albumName),
      isTrue,
    );
    await releasePage(tester);
  });

  testWidgets('copy and share album info', (tester) async {
    String? shared;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (MethodCall call) async {
        final args = call.arguments;
        if (args is Map && args['text'] is String) {
          shared = args['text'] as String;
        }
        return 'shared';
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      );
    });

    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(userEmail: _email),
    );
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments;
          if (args is Map) clipboardText = args['text'] as String?;
        }
        return null;
      },
    );

    await waitForText(tester, _albumName);
    await tester.ensureVisible(find.text(_albumName).first);
    await tester.longPress(find.text(_albumName).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Paylaş'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bilgileri Kopyala'), findsOneWidget);
    await tester.tap(find.text('Bilgileri Kopyala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(clipboardText, contains('Albüm: $_albumName'));
    expect(clipboardText, contains(_description));

    await tester.longPress(find.text(_albumName).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Paylaş'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Paylaş'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(shared, contains('Albüm: $_albumName'));
    expect(find.text('Paylaşım açılamadı. Albüm bilgileri panoya kopyalandı'),
        findsNothing);
    await releasePage(tester);
  });

  testWidgets('menu entry opens album list', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      Builder(
        builder: (context) {
          return TextButton(
            onPressed: () {
              final items =
                  buildSeyirDefteriMenuItems(context, userEmail: _email);
              final album = items.where((item) => item.tooltip == 'Albümler');
              expect(album, isNotEmpty);
              album.first.onTap();
            },
            child: const Text('Albümler menü'),
          );
        },
      ),
      size: const Size(480, 1400),
    );
    await tester.tap(find.text('Albümler menü'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await waitForText(tester, 'ALBÜMLERİM');
    expect(find.text('ALBÜMLERİM'), findsOneWidget);
    await releasePage(tester);
  });

  testWidgets('list view shows description', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AlbumlerListePage(userEmail: _email),
    );
    await waitForText(tester, _albumName);
    await tester.tap(find.byTooltip('Liste Görünümü'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(_description), findsOneWidget);
    await saveShot(tester, shot('liste-satir', 'light'));
    await releasePage(tester);
  });
}
