import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/screens/admin_page.dart';
import 'package:its19/screens/database_debug_page.dart';
import 'package:its19/screens/reklam_yonetim_page.dart';
import 'package:its19/screens/test_notifications_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/utils/timeago_helper.dart';

/// Admin, reklam, test ve debug ekran görüntüleri.
///
/// ADMIN_SHOT_DIR ve ADMIN_SHOT_PHASE (before | after) set ise
/// `admin-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'AdminFallback';
const _adminEmail = 'admin.seyir@example.com';
const _userEmail = 'ayse.demir@example.com';

bool get _after =>
    (Platform.environment['ADMIN_SHOT_PHASE'] ?? 'after') != 'before';

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

  await loadFamily(_shotFont, const ['lib/fonts/cocon_regular.otf']);
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

Future<void> _register({
  required String email,
  required String name,
  required String id,
  required bool isAdmin,
}) async {
  if (HiveDatabaseService.getRegistrationByEmail(email) != null) return;
  await HiveDatabaseService.addRegistration(
    RegistrationModel(
      id: id,
      judgeName: name,
      email: email,
      password: 'shot',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime(2024, 3, 12, 9, 30),
      lastLoginAt: DateTime(2024, 11, 2, 18, 5),
      isAdmin: isAdmin,
      isEmailVerified: true,
      isActive: true,
    ),
  );
}

Future<void> _seed() async {
  await _register(
    email: _adminEmail,
    name: 'Selin Yönetici',
    id: 'shot-admin',
    isAdmin: true,
  );
  await _register(
    email: _userEmail,
    name: 'Ayşe Demir',
    id: 'shot-ayse',
    isAdmin: false,
  );
  if (!Hive.isBoxOpen('notifications')) {
    await Hive.openBox('notifications');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    TimeAgoHelper.initialize();
    final hiveDir = Directory('/tmp/admin-polish-hive');
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
    hiveDir.createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => hiveDir.path,
    );
    await HiveDatabaseService.initialize();
    await _seed();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    Widget page, {
    Size size = const Size(430, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('admin-shot'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: page,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['ADMIN_SHOT_DIR'];
    final phase = Platform.environment['ADMIN_SHOT_PHASE'];
    if (dir == null || dir.isEmpty || phase == null || phase.isEmpty) return;
    if (name.contains('before') && phase != 'before') return;
    if (name.contains('after') && phase != 'after') return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('admin-shot')),
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

  String _phaseName(String stem, String brightness) =>
      'admin-$stem-${_after ? 'after' : 'before'}-$brightness.png';

  testWidgets('admin panel light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AdminPage(adminEmail: _adminEmail),
      size: const Size(430, 1400),
    );
    expect(find.text('Admin Paneli'), findsOneWidget);
    expect(find.text('Admin Bilgileri'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Admin Paneli'));
    expect(title.style?.fontSize, SeyirTokens.typeHeadline);
    final debugButton = tester.getSize(
      find.widgetWithText(ElevatedButton, 'Veritabanı Detaylarını Görüntüle'),
    );
    final adsButton = tester.getSize(
      find.widgetWithText(ElevatedButton, 'Reklamları Yönet'),
    );
    expect(debugButton.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(adsButton.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    final refresh = tester.getSize(find.byTooltip('Yenile'));
    expect(refresh.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(refresh.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    await saveShot(tester, _phaseName('panel', 'light'));
    await releasePage(tester);
  });

  testWidgets('admin panel dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const AdminPage(adminEmail: _adminEmail),
      size: const Size(430, 1400),
    );
    expect(find.text('Toplam Kullanıcı'), findsOneWidget);
    final stat = tester.widget<Text>(find.text('Toplam Kullanıcı'));
    expect(stat.style?.color, isNot(Colors.grey));
    expect(stat.style?.fontSize, SeyirTokens.typeBody);
    await saveShot(tester, _phaseName('panel', 'dark'));
    await releasePage(tester);
  });

  testWidgets('admin unauthorized', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const AdminPage(adminEmail: _userEmail),
      size: const Size(430, 800),
    );
    expect(find.text('Yetkiniz yok'), findsOneWidget);
    expect(find.text(_adminEmail), findsNothing);
    expect(find.text('Veritabanı Detaylarını Görüntüle'), findsNothing);
    await saveShot(tester, _phaseName('yetki-admin', 'light'));
    await releasePage(tester);
  });

  testWidgets('reklam light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ReklamYonetimPage(adminEmail: _adminEmail),
      size: const Size(430, 980),
    );
    expect(find.text('Reklam Yönetimi'), findsOneWidget);
    expect(find.text('Reklamlar yüklenemedi.'), findsNothing);
    expect(find.textContaining('WB-PREM'), findsWidgets);
    final add = tester.getSize(find.widgetWithText(FloatingActionButton, 'Yeni Reklam'));
    expect(add.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    final filter = tester.getSize(find.widgetWithText(FilterChip, 'Tümü'));
    expect(filter.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    await saveShot(tester, _phaseName('reklam', 'light'));
    await releasePage(tester);
  });

  testWidgets('reklam dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const ReklamYonetimPage(adminEmail: _adminEmail),
      size: const Size(430, 980),
    );
    expect(find.text('Toplam'), findsOneWidget);
    final label = tester.widget<Text>(find.text('Toplam'));
    expect(label.style?.color, isNot(Colors.grey));
    await saveShot(tester, _phaseName('reklam', 'dark'));
    await releasePage(tester);
  });

  testWidgets('reklam empty search', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ReklamYonetimPage(adminEmail: _adminEmail),
      size: const Size(430, 980),
    );
    await tester.enterText(find.byType(TextField), 'zzz-yok');
    await tester.pump();
    expect(find.text('Reklam bulunamadı'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsNothing);
    expect(find.text('Reklamlar yüklenemedi.'), findsNothing);
    await saveShot(tester, _phaseName('reklam-bos', 'light'));
    await releasePage(tester);
  });

  testWidgets('reklam unauthorized', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const ReklamYonetimPage(adminEmail: _userEmail),
      size: const Size(430, 800),
    );
    expect(find.text('Yetkiniz yok'), findsOneWidget);
    expect(find.text('Yeni Reklam'), findsNothing);
    await saveShot(tester, _phaseName('yetki-reklam', 'dark'));
    await releasePage(tester);
  });

  testWidgets('test empty light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const TestNotificationsPage(userEmail: _adminEmail),
      size: const Size(430, 1100),
    );
    expect(find.text('Henüz bildirim yok'), findsOneWidget);
    expect(find.text('Test Sayfası'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Bildirimler ve Performans Testi'));
    expect(title.style?.fontSize, SeyirTokens.typeHeadline);
    final wipe = tester.getSize(
      find.widgetWithText(OutlinedButton, 'Tüm Bildirimleri Sil'),
    );
    expect(wipe.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    await saveShot(tester, _phaseName('test', 'light'));
    await releasePage(tester);
  });

  testWidgets('test empty dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const TestNotificationsPage(userEmail: _adminEmail),
      size: const Size(430, 1100),
    );
    expect(find.text('Henüz bildirim yok'), findsOneWidget);
    final empty = tester.widget<Text>(find.text('Henüz bildirim yok'));
    expect(empty.style?.color, isNot(Colors.grey));
    await saveShot(tester, _phaseName('test', 'dark'));
    await releasePage(tester);
  });

  testWidgets('test delete asks first', (tester) async {
    final notes = Hive.box('notifications');
    await tester.runAsync(() async {
      await notes.put('notification_7', <String, dynamic>{
        'id': 7,
        'title': 'Duruşma hatırlatması',
        'body': 'Yarın saat 10.00',
        'payload': 'test',
        'channelId': 'dava_bildirimleri',
        'timestamp':
            DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
        'isRead': false,
        'isScheduled': false,
      });
    });
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const TestNotificationsPage(userEmail: _adminEmail),
      size: const Size(430, 1400),
    );
    expect(find.text('Duruşma hatırlatması'), findsOneWidget);
    await tester.tap(find.byTooltip('Sil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bu bildirimi silmek istediğine emin misin?'), findsOneWidget);
    expect(find.text('Duruşma hatırlatması'), findsOneWidget);
    await tester.tap(find.text('İptal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Duruşma hatırlatması'), findsOneWidget);

    await tester.tap(find.text('Tüm Bildirimleri Sil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tüm bildirimleri silmek istediğine emin misin?'), findsOneWidget);
    await tester.tap(find.text('İptal'));
    await tester.pump();
    await tester.runAsync(() => notes.delete('notification_7'));
    await releasePage(tester);
  });

  testWidgets('test unauthorized', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const TestNotificationsPage(userEmail: _userEmail),
      size: const Size(430, 800),
    );
    expect(find.text('Yetkiniz yok'), findsOneWidget);
    expect(find.text('Tüm Bildirimleri Sil'), findsNothing);
    await saveShot(tester, _phaseName('yetki-test', 'light'));
    await releasePage(tester);
  });

  testWidgets('debug light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DatabaseDebugPage(userEmail: _adminEmail),
      size: const Size(430, 1500),
    );
    expect(find.text('Açılan davalar:'), findsOneWidget);
    expect(find.text('Kayıtlar:'), findsOneWidget);
    expect(find.text('acilan_davalar:'), findsNothing);
    expect(find.text('kayitlar:'), findsNothing);
    expect(find.text(_userEmail), findsOneWidget);
    final refresh = tester.getSize(find.byTooltip('Yenile').first);
    expect(refresh.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    await saveShot(tester, _phaseName('debug', 'light'));
    await releasePage(tester);
  });

  testWidgets('debug dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DatabaseDebugPage(userEmail: _adminEmail),
      size: const Size(430, 1500),
    );
    final email = tester.widget<Text>(find.text(_userEmail));
    expect(email.style?.color, isNot(Colors.black));
    expect(email.style?.fontSize, SeyirTokens.typeBody);
    await saveShot(tester, _phaseName('debug', 'dark'));
    await releasePage(tester);
  });

  testWidgets('debug unauthorized hides accounts', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DatabaseDebugPage(userEmail: _userEmail),
      size: const Size(430, 800),
    );
    expect(find.text('Yetkiniz yok'), findsOneWidget);
    expect(find.text(_adminEmail), findsNothing);
    expect(find.text(_userEmail), findsNothing);
    expect(find.text('Açılan davalar:'), findsNothing);
    await saveShot(tester, _phaseName('yetki-debug', 'dark'));
    await releasePage(tester);
  });
}
