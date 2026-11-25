import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/evidence_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/delil_detay_page.dart';
import 'package:its19/screens/delil_ekle_page.dart';
import 'package:its19/screens/delil_listesi_ekrani.dart';
import 'package:its19/screens/delilleri_incele_page.dart';
import 'package:its19/services/evidence_comment_service.dart';
import 'package:its19/services/evidence_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:provider/provider.dart';

/// Delil sayfalarının ekran görüntüsü.
///
/// DELIL_SHOT_DIR ve DELIL_SHOT_PHASE (before | after) set ise
/// `delil-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'DelilFallback';
const _email = 'ayse.demir@example.com';
const _davaId = 'shot-dava-1';
const _evidenceId = 'shot-dava-1_01';

bool get _after =>
    (Platform.environment['DELIL_SHOT_PHASE'] ?? 'after') != 'before';

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

EvidenceModel _shotEvidence() {
  return EvidenceModel(
    id: _evidenceId,
    davaId: _davaId,
    type: 'image',
    title: 'Gece fotoğrafı',
    description: 'Sokak lambasının yanmadığını gösteren fotoğraf',
    filePath: '',
    createdAt: DateTime(2026, 11, 1, 21, 15),
    userId: _email,
    likeCount: 3,
    dislikeCount: 1,
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
      DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
  final existing = await HiveDatabaseService.getAcceptedDavalar(_email);
  final already = existing.any(
    (dava) => (dava['id'] ?? dava['davaId'])?.toString() == _davaId,
  );
  if (!already) {
    await HiveDatabaseService.saveAcceptedDava(<String, dynamic>{
      'id': _davaId,
      'davaId': _davaId,
      'userEmail': _email,
      'adi': 'Gece lambası',
      'davaAdi': 'Gece lambası',
      'davaci': 'Ayşe Demir',
      'davali': 'Mehmet Kaya',
      'userRole': 'Yargıç',
      'mevkii': 'Yargıç',
      'kategori': 'Komşuluk',
      'davaKonusu': 'Sokak lambası günlerdir yanmıyor.',
      'openedAt': openedAt,
      'createdAt': openedAt,
      'kalanSure': '52 saat',
    });
  }

  final evidenceService = EvidenceService();
  await evidenceService.initialize();
  if (evidenceService.getEvidenceById(_evidenceId) == null) {
    final box = evidenceService;
    await box.addEvidence(_shotEvidence());
  }

  final comments = EvidenceCommentService();
  await comments.initialize();
  await comments.addOrUpdateComment(
    evidenceId: _evidenceId,
    davaId: _davaId,
    userRole: 'Yargıç',
    userEmail: _email,
    commentText: 'Fotoğraf net, lamba gerçekten sönük.',
    criticism: 'positive',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    Directory('/tmp/delil-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/delil-hive',
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
        key: const Key('delil-shot'),
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
    final dir = Platform.environment['DELIL_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('delil-shot')),
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
      'delil-$page-${_after ? 'after' : 'before'}-$brightness.png';

  testWidgets('delil ekle light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilEklePage(
        userEmail: _email,
        davaId: _davaId,
        davaAdi: 'Gece lambası',
      ),
    );
    await waitForText(tester, 'Resim Ekle');
    expect(find.textContaining('DELİL EKLE'), findsOneWidget);
    expect(find.text('Gece fotoğrafı'), findsOneWidget);
    if (_after) {
      expect(find.text('DELİL EKLE'), findsOneWidget);
      expect(find.text('DELİL EKLE '), findsNothing);
      final title = tester.widget<Text>(find.text('DELİL EKLE'));
      expect(title.style?.fontSize, SeyirTokens.typeHeadline);
      final back = tester.getSize(find.byTooltip('Geri'));
      expect(back.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      expect(back.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      final add = tester.getSize(find.byTooltip('Delil Ekle'));
      expect(add.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      expect(add.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      final remove = tester.getSize(find.byTooltip('Sil'));
      expect(remove.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
      expect(remove.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    }
    await saveShot(tester, shot('ekle', 'light'));
    await releasePage(tester);
  });

  testWidgets('delil ekle dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DelilEklePage(
        userEmail: _email,
        davaId: _davaId,
        davaAdi: 'Gece lambası',
      ),
    );
    await waitForText(tester, 'Resim Ekle');
    expect(find.text('Gece fotoğrafı'), findsOneWidget);
    await saveShot(tester, shot('ekle', 'dark'));
    await releasePage(tester);
  });

  testWidgets('delil detay light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      DelilDetayPage(
        userEmail: _email,
        evidence: _shotEvidence(),
        userRole: 'Yargıç',
      ),
      size: const Size(420, 2200),
    );
    await waitForText(tester, 'Gece fotoğrafı');
    expect(find.text('DELİL DETAYI'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byTooltip('Geri'), findsNothing);
    final title = tester.getRect(find.text('DELİL DETAYI'));
    expect((title.center.dx - tester.view.physicalSize.width / 2).abs(), lessThan(8));
    await saveShot(tester, shot('detay', 'light'));
    await releasePage(tester);
  });

  testWidgets('delil detay dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      DelilDetayPage(
        userEmail: _email,
        evidence: _shotEvidence(),
        userRole: 'Yargıç',
      ),
      size: const Size(420, 2200),
    );
    await waitForText(tester, 'Gece fotoğrafı');
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byTooltip('Geri'), findsNothing);
    await saveShot(tester, shot('detay', 'dark'));
    await releasePage(tester);
  });

  testWidgets('delil incele light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilleriIncelePage(
        userEmail: _email,
        davaId: _davaId,
      ),
      size: const Size(420, 1800),
    );
    await waitForText(tester, 'Delil Türlerini İncele');
    expect(find.textContaining('Delilleri İncele'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byTooltip('Geri'), findsNothing);
    await saveShot(tester, shot('incele', 'light'));
    await releasePage(tester);
  });

  testWidgets('delil incele dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DelilleriIncelePage(
        userEmail: _email,
        davaId: _davaId,
      ),
      size: const Size(420, 1800),
    );
    await waitForText(tester, 'Delil Türlerini İncele');
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byTooltip('Geri'), findsNothing);
    await saveShot(tester, shot('incele', 'dark'));
    await releasePage(tester);
  });

  testWidgets('delil incele empty light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilleriIncelePage(),
      size: const Size(420, 1400),
    );
    await waitForText(tester, 'Henüz kabul edilmiş dava yok');
    expect(find.text('Henüz kabul edilmiş dava yok'), findsOneWidget);
    await saveShot(tester, shot('incele-empty', 'light'));
    await releasePage(tester);
  });

  testWidgets('delil incele empty dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DelilleriIncelePage(),
      size: const Size(420, 1400),
    );
    await waitForText(tester, 'Henüz kabul edilmiş dava yok');
    await saveShot(tester, shot('incele-empty', 'dark'));
    await releasePage(tester);
  });

  testWidgets('delil listesi light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilListesiEkrani(
        davaId: _davaId,
        userEmail: _email,
      ),
      size: const Size(420, 1100),
    );
    await waitForText(tester, 'Delil Türlerini İncele');
    expect(find.text('Delil Listesi'), findsOneWidget);
    await saveShot(tester, shot('listesi', 'light'));
    await releasePage(tester);
  });

  testWidgets('delil listesi dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DelilListesiEkrani(
        davaId: _davaId,
        userEmail: _email,
      ),
      size: const Size(420, 1100),
    );
    await waitForText(tester, 'Delil Türlerini İncele');
    await saveShot(tester, shot('listesi', 'dark'));
    await releasePage(tester);
  });

  testWidgets('delil delete confirm', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilEklePage(
        userEmail: _email,
        davaId: _davaId,
        davaAdi: 'Gece lambası',
      ),
    );
    await waitForText(tester, 'Gece fotoğrafı');
    await tester.tap(find.byTooltip('Sil'));
    await tester.pumpAndSettle();
    expect(find.text('Silmek istediğine emin misin?'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);
    expect(find.text('Sil'), findsOneWidget);
    await saveShot(tester, 'delil-delete-confirm-after-light.png');
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(find.text('Gece fotoğrafı'), findsOneWidget);
    await releasePage(tester);
  });

  testWidgets('delil error retry light', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilleriIncelePage(
        userEmail: _email,
        davaId: _davaId,
        forceLoadError: true,
      ),
      size: const Size(420, 1400),
    );
    await waitForText(tester, 'Tekrar dene');
    expect(find.text('Kabul edilen davalar yüklenemedi'), findsOneWidget);
    expect(find.text('Henüz kabul edilmiş dava yok'), findsNothing);
    await saveShot(tester, 'delil-error-retry-after-light.png');
    await releasePage(tester);
  });

  testWidgets('delil error retry dark', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DelilleriIncelePage(
        userEmail: _email,
        davaId: _davaId,
        forceLoadError: true,
      ),
      size: const Size(420, 1400),
    );
    await waitForText(tester, 'Tekrar dene');
    expect(find.text('Kabul edilen davalar yüklenemedi'), findsOneWidget);
    expect(find.text('Henüz kabul edilmiş dava yok'), findsNothing);
    await saveShot(tester, 'delil-error-retry-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('delil ekle counts error', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilEklePage(
        userEmail: _email,
        davaId: _davaId,
        davaAdi: 'Gece lambası',
        forceLoadError: true,
      ),
      size: const Size(420, 1400),
    );
    await waitForText(tester, 'Tekrar dene');
    expect(find.text('Delil sayıları yüklenemedi'), findsOneWidget);
    expect(find.text('Resim Ekle'), findsNothing);
    await saveShot(tester, 'delil-ekle-error-retry-after-light.png');
    await releasePage(tester);
  });

  testWidgets('delil plus type picker', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilEklePage(
        userEmail: _email,
        davaId: _davaId,
        davaAdi: 'Gece lambası',
      ),
      size: const Size(420, 1200),
    );
    await waitForText(tester, 'Resim Ekle');
    await tester.tap(find.byTooltip('Delil Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Delil türü'), findsOneWidget);
    expect(find.text('Video Ekle'), findsWidgets);
    expect(find.text('PDF Ekle'), findsWidgets);
    expect(find.text('Link Ekle'), findsWidgets);
    await saveShot(tester, 'delil-plus-type-picker-after-light.png');
    await releasePage(tester);
  });

  testWidgets('delil incele with user', (tester) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DelilleriIncelePage(
        userEmail: _email,
        davaId: _davaId,
      ),
      size: const Size(420, 1800),
    );
    await waitForText(tester, 'Delil Türlerini İncele');
    expect(find.text('Henüz kabul edilmiş dava yok'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byTooltip('Geri'), findsNothing);
    expect(find.text('1'), findsWidgets);
    await saveShot(tester, 'delil-incele-with-user-after-light.png');
    await releasePage(tester);
  });
}
