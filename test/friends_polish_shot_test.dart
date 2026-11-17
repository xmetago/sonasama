import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:its19/models/friend_category_model.dart';
import 'package:its19/models/friendship_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/chat_detail_page.dart';
import 'package:its19/screens/davetler_page.dart';
import 'package:its19/screens/delilleri_incele_page.dart';
import 'package:its19/screens/friendship_management_page.dart';
import 'package:its19/screens/uyarilar_page.dart';
import 'package:its19/services/friend_category_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/services/user_session_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/utils/timeago_helper.dart';
import 'package:its19/widgets/delil_surface.dart';
import 'package:provider/provider.dart';

/// Kişiler, davetler ve uyarılar ekran görüntüsü.
///
/// FRIENDS_SHOT_DIR set ise `*-after-*.png` yazar. Before kareleri cila
/// öncesi aynı sahte veriyle alınmıştır.
const _shotFont = 'cocon';
const _fallbackFont = 'FriendsFallback';
const _email = 'ayse.demir@example.com';
const _emptyEmail = 'bos.liste@example.com';
const _adminEmail = 'admin@example.com';

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

RegistrationModel _user({
  required String id,
  required String name,
  required String email,
  bool isAdmin = false,
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
    isAdmin: isAdmin,
  );
}

Future<void> _seed() async {
  Future<void> register(RegistrationModel user) async {
    if (HiveDatabaseService.getRegistrationByEmail(user.email) != null) return;
    await HiveDatabaseService.addRegistration(user);
  }

  final ayse = _user(id: 'shot-ayse', name: 'Ayşe Demir', email: _email);
  final mehmet = _user(
    id: 'shot-mehmet',
    name: 'Mehmet Kaya',
    email: 'mehmet.kaya@example.com',
  );
  final selim = _user(
    id: 'shot-selim',
    name: 'Selim Aras',
    email: 'selim.aras@example.com',
  );
  final bos = _user(id: 'shot-bos', name: 'Boş Liste', email: _emptyEmail);
  final admin = _user(
    id: 'shot-admin',
    name: 'Yönetici',
    email: _adminEmail,
    isAdmin: true,
  );
  await register(ayse);
  await register(mehmet);
  await register(selim);
  await register(bos);
  await register(admin);
  UserSessionService.setCurrentUser(ayse);
  await FriendCategoryService.initialize();
  if (FriendCategoryService.getByOwnerAndTarget(ayse.id, mehmet.id) == null) {
    await FriendCategoryService.upsert(FriendCategoryModel(
      id: 'shot-ayse_shot-mehmet',
      ownerUserId: ayse.id,
      targetUserId: mehmet.id,
      category: 'Arkadaş',
      createdAt: DateTime(2024, 6, 2),
    ));
  }
  if (HiveDatabaseService.getFriendship('pending-selim-ayse') == null) {
    await HiveDatabaseService.sendFriendshipRequest(FriendshipModel(
      id: 'pending-selim-ayse',
      requesterId: selim.id,
      recipientId: ayse.id,
      status: FriendshipStatus.pending,
      createdAt: DateTime(2024, 6, 3),
    ));
  }
  HiveDatabaseService.addInvitation(_email, <String, dynamic>{
    'id': 'davet-gece',
    'davaId': 'dava-gece',
    'userEmail': 'mehmet.kaya@example.com',
    'displayName': 'Mehmet Kaya',
    'davaAdi': 'Gece lambası',
    'davaKategori': 'Komşuluk',
    'davaKonusu': 'Sokak lambası günlerdir yanmıyor.',
    'davaci': 'Ayşe Demir',
    'davali': 'Mehmet Kaya',
    'isOpened': false,
  });
  final existing = HiveDatabaseService.getBildirimler(_email);
  if (existing.isEmpty) {
    await HiveDatabaseService.appendGelenDavaBildirimi(_email, <String, dynamic>{
      'id': 'dava-gece',
      'davaAdi': 'Gece lambası',
    });
    await HiveDatabaseService.appendDurtmeBildirimi(
      receiverEmail: _email,
      senderName: 'Mehmet Kaya',
      senderEmail: 'mehmet.kaya@example.com',
      kelime: 'Merhaba',
    );
  }
  if (!Hive.isBoxOpen('notifications')) {
    await Hive.openBox('notifications');
  }
  final notes = Hive.box('notifications');
  if (notes.get('notification_7') == null) {
    await notes.put('notification_7', <String, dynamic>{
      'id': 7,
      'title': 'Yeni mesaj',
      'body': 'Mehmet Kaya bir mesaj gönderdi',
      'payload': 'chat_mehmet.kaya@example.com',
      'channelId': 'mesaj_bildirimleri',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      'isRead': false,
      'isScheduled': false,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    TimeAgoHelper.initialize();
    final hiveDir = Directory('/tmp/friends-polish-hive');
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

  void signInAyse() {
    final session = HiveDatabaseService.getRegistrationByEmail(_email);
    if (session != null) UserSessionService.setCurrentUser(session);
  }

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
      ChangeNotifierProvider(
        create: (_) => DavaProvider(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          builder: (context, child) {
            return RepaintBoundary(
              key: const Key('friends-shot'),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: page,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['FRIENDS_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('friends-shot')),
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

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  }

  Text textOf(String data) => find.text(data).evaluate().first.widget as Text;

  testWidgets('friends after light', (tester) async {
    signInAyse();
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const FriendshipManagementPage(userEmail: _email),
    );
    expect(find.text('|| KİŞİLER ||'), findsOneWidget);
    expect(find.text('Selim Aras'), findsOneWidget);
    expect(textOf('|| KİŞİLER ||').style?.fontSize, SeyirTokens.typeHeadline);
    final request = tester.getSize(find.byTooltip('Gelen istekler'));
    expect(request.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(request.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    final chip = find.ancestor(
      of: find.text('Kategorisiz'),
      matching: find.byType(InkWell),
    ).first;
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(find.byTooltip('Test Sayfası'), findsNothing);
    await saveShot(tester, 'friends-after-light.png');
    await releasePage(tester);
  });

  testWidgets('friends after dark', (tester) async {
    signInAyse();
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const FriendshipManagementPage(userEmail: _email),
    );
    expect(find.text('Selim Aras'), findsOneWidget);
    final header = textOf('|| KİŞİLER ||').style?.color;
    expect(header, isNotNull);
    expect(ThemeData.estimateBrightnessForColor(header!), Brightness.light);
    await saveShot(tester, 'friends-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('friends empty after light', (tester) async {
    signInAyse();
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const FriendshipManagementPage(userEmail: _email),
      size: const Size(430, 900),
    );
    await tester.tap(find.text('Grup-19').first);
    await tester.pump();
    expect(find.text('Henüz kullanıcı bulunamadı'), findsOneWidget);
    expect(find.byType(DelilSoftEmpty), findsOneWidget);
    await saveShot(tester, 'friends-empty-after-light.png');
    await releasePage(tester);
  });

  testWidgets('friends error after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const FriendshipManagementPage(userEmail: _email, forceLoadError: true),
      size: const Size(430, 900),
    );
    expect(find.text('Kişiler yüklenemedi'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.byType(DelilLoadError), findsOneWidget);
    final retry = tester.getSize(find.byType(OutlinedButton));
    expect(retry.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    await saveShot(tester, 'friends-error-after-light.png');
    await releasePage(tester);
  });

  testWidgets('friends login required after light', (tester) async {
    UserSessionService.clearCurrentUser();
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const FriendshipManagementPage(userEmail: 'yok@example.com'),
      size: const Size(430, 900),
    );
    expect(find.text('Giriş gerekli'), findsOneWidget);
    expect(find.text('Henüz kullanıcı bulunamadı'), findsNothing);
    expect(find.byType(DelilSoftEmpty), findsOneWidget);
    await saveShot(tester, 'friends-login-required-after-light.png');
    await releasePage(tester);
    signInAyse();
  });

  testWidgets('invites after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DavetlerPage(userEmail: _email),
    );
    expect(find.text('GELEN DAVETLER'), findsOneWidget);
    expect(find.text('Gece lambası'), findsWidgets);
    expect(textOf('GELEN DAVETLER').style?.fontSize, SeyirTokens.typeHeadline);
    final refresh = tester.getSize(find.byTooltip('Davetleri Yenile'));
    expect(refresh.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(refresh.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    await saveShot(tester, 'invites-after-light.png');
    await releasePage(tester);
  });

  testWidgets('invites after dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const DavetlerPage(userEmail: _email),
    );
    expect(find.text('Gece lambası'), findsWidgets);
    final header = textOf('GELEN DAVETLER').style?.color;
    expect(ThemeData.estimateBrightnessForColor(header!), Brightness.light);
    final cardFinder = find.byType(Container);
    expect(cardFinder, findsWidgets);
    await saveShot(tester, 'invites-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('invites empty after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DavetlerPage(userEmail: _emptyEmail),
      size: const Size(430, 900),
    );
    expect(find.text('Henüz davet almadınız'), findsOneWidget);
    expect(find.byType(DelilSoftEmpty), findsOneWidget);
    await saveShot(tester, 'invites-empty-after-light.png');
    await releasePage(tester);
  });

  testWidgets('invites error after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DavetlerPage(userEmail: _email, forceLoadError: true),
      size: const Size(430, 900),
    );
    expect(find.text('Davetler yüklenemedi'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    await saveShot(tester, 'invites-error-after-light.png');
    await releasePage(tester);
  });

  testWidgets('invites login required after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const DavetlerPage(),
      size: const Size(430, 900),
    );
    expect(find.text('Giriş gerekli'), findsOneWidget);
    expect(find.text('Henüz davet almadınız'), findsNothing);
    await saveShot(tester, 'invites-login-required-after-light.png');
    await releasePage(tester);
  });

  testWidgets('warnings after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const UyarilarPage(userEmail: _email),
    );
    expect(find.text('UYARILAR'), findsOneWidget);
    expect(find.textContaining('Uygulama uyarıları'), findsOneWidget);
    expect(find.textContaining('Cihaz bildirimleri'), findsOneWidget);
    expect(find.text('Hive Bildirimleri'), findsNothing);
    expect(find.text('Henüz Hive uyarısı yok'), findsNothing);
    expect(textOf('UYARILAR').style?.fontSize, SeyirTokens.typeHeadline);
    expect(find.byTooltip('Test Sayfası'), findsNothing);
    final tab = find.ancestor(
      of: find.textContaining('Uygulama uyarıları'),
      matching: find.byType(InkWell),
    ).first;
    expect(tester.getSize(tab).height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    final close = tester.getSize(find.byTooltip('Sil').first);
    expect(close.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(close.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(find.text('Dikkat! Gelen DAVA var.'), findsOneWidget);
    await saveShot(tester, 'warnings-after-light.png');
    await releasePage(tester);
  });

  testWidgets('warnings after dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const UyarilarPage(userEmail: _email),
    );
    final header = textOf('UYARILAR').style?.color;
    expect(ThemeData.estimateBrightnessForColor(header!), Brightness.light);
    final card = tester.widget<Card>(find.byType(Card).first);
    expect(card.color, isNot(Colors.white));
    await saveShot(tester, 'warnings-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('warnings empty after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const UyarilarPage(userEmail: _emptyEmail),
      size: const Size(430, 900),
    );
    expect(find.text('Henüz uygulama uyarısı yok'), findsOneWidget);
    expect(find.byType(DelilSoftEmpty), findsOneWidget);
    await saveShot(tester, 'warnings-empty-after-light.png');
    await releasePage(tester);
  });

  testWidgets('warnings device after dark', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const UyarilarPage(userEmail: _email),
    );
    await tester.tap(find.textContaining('Cihaz bildirimleri'));
    await tester.pump();
    expect(find.text('Yeni mesaj'), findsOneWidget);
    expect(find.text('Mesaj'), findsWidgets);
    expect(find.textContaining('MESAJ BILDIRIMLERI'), findsNothing);
    await saveShot(tester, 'warnings-device-after-dark.png');
    await releasePage(tester);
  });

  testWidgets('warnings admin test page light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const UyarilarPage(userEmail: _adminEmail),
      size: const Size(430, 900),
    );
    expect(find.byTooltip('Test Sayfası'), findsOneWidget);
    final tube = tester.getSize(find.byTooltip('Test Sayfası'));
    expect(tube.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(tube.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    await saveShot(tester, 'warnings-admin-after-light.png');
    await releasePage(tester);
  });

  testWidgets('warnings delete confirm after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const UyarilarPage(userEmail: _email),
    );
    expect(find.text('Dikkat! Gelen DAVA var.'), findsOneWidget);
    await tester.tap(find.byTooltip('Sil').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Silmek istediğine emin misin?'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sil'), findsOneWidget);
    await saveShot(tester, 'warnings-delete-confirm-after-light.png');
    await tester.tap(find.text('İptal'));
    await tester.pump();
    expect(find.text('Dikkat! Gelen DAVA var.'), findsOneWidget);
    await releasePage(tester);
  });

  testWidgets('warnings tap opens case not delete', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const UyarilarPage(userEmail: _email),
      size: const Size(430, 1200),
    );
    await tester.tap(find.text('Dikkat! Gelen DAVA var.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DelilleriIncelePage), findsOneWidget);
    expect(find.text('Silmek istediğine emin misin?'), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dikkat! Gelen DAVA var.'), findsOneWidget);
    await releasePage(tester);
  });

  testWidgets('warnings tap opens chat', (tester) async {
    signInAyse();
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const UyarilarPage(userEmail: _email),
      size: const Size(430, 1200),
    );
    await tester.tap(find.text('Mehmet Kaya seni dürtüyor: Merhaba'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ChatDetailPage), findsOneWidget);
    expect(find.text('Silmek istediğine emin misin?'), findsNothing);
    await releasePage(tester);
  });

  testWidgets('warnings login required after light', (tester) async {
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const UyarilarPage(),
      size: const Size(430, 900),
    );
    expect(find.text('Giriş gerekli'), findsOneWidget);
    expect(find.text('Henüz uygulama uyarısı yok'), findsNothing);
    expect(find.byTooltip('Test Sayfası'), findsNothing);
    await saveShot(tester, 'warnings-login-required-after-light.png');
    await releasePage(tester);
  });
}
