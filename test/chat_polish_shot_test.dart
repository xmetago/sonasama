import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:its19/models/chat_message_model.dart';
import 'package:its19/models/friend_category_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/chat_detail_page.dart';
import 'package:its19/screens/chat_page.dart';
import 'package:its19/screens/friendship_management_page.dart';
import 'package:its19/services/chat_service.dart';
import 'package:its19/services/friend_category_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/services/user_session_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/delil_surface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sohbet listesi ve sohbet detayının ekran görüntüsü.
///
/// CHAT_SHOT_DIR ve CHAT_SHOT_PHASE (before | after) set ise
/// `chat-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'ChatFallback';
const _email = 'ayse.demir@example.com';
const _emptyEmail = 'bos.sohbet@example.com';
const _mehmetEmail = 'mehmet.kaya@example.com';
const _elifEmail = 'elif.yilmaz@example.com';

bool get _after =>
    (Platform.environment['CHAT_SHOT_PHASE'] ?? 'after') != 'before';

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

RegistrationModel _user({
  required String id,
  required String name,
  required String email,
  required DateTime lastLoginAt,
}) {
  return RegistrationModel(
    id: id,
    judgeName: name,
    email: email,
    password: 'shot',
    country: 'Türkiye',
    oath: true,
    createdAt: DateTime(2024, 1, 1),
    lastLoginAt: lastLoginAt,
  );
}

Future<void> _seed() async {
  final now = DateTime.now();
  final users = [
    _user(
      id: 'shot-ayse',
      name: 'Ayşe Demir',
      email: _email,
      lastLoginAt: now,
    ),
    _user(
      id: 'shot-mehmet',
      name: 'Mehmet Kaya',
      email: _mehmetEmail,
      lastLoginAt: now,
    ),
    _user(
      id: 'shot-elif',
      name: 'Elif Yılmaz',
      email: _elifEmail,
      lastLoginAt: now.subtract(const Duration(days: 3)),
    ),
    _user(
      id: 'shot-bos',
      name: 'Boş Sohbet',
      email: _emptyEmail,
      lastLoginAt: now,
    ),
  ];
  for (final user in users) {
    if (HiveDatabaseService.getRegistrationByEmail(user.email) == null) {
      await HiveDatabaseService.addRegistration(user);
    }
  }

  // Albüm modeli de typeId 21. Sohbet testi kategori yazar; albüm yazmaz.
  Hive.registerAdapter(FriendCategoryModelAdapter(), override: true);
  await FriendCategoryService.initialize();
  Future<void> link(String targetId) async {
    final id = 'shot-ayse_$targetId';
    final existing = FriendCategoryService.getByOwnerAndTarget('shot-ayse', targetId);
    if (existing != null) return;
    await FriendCategoryService.upsert(
      FriendCategoryModel(
        id: id,
        ownerUserId: 'shot-ayse',
        targetUserId: targetId,
        category: 'Grup-19',
        createdAt: DateTime(2026, 10, 1),
      ),
    );
  }

  await link('shot-mehmet');
  await link('shot-elif');

  await ChatService.initialize();
  final box = Hive.box<ChatMessageModel>('chat_message_box');
  final conversationId =
      ChatMessageModel.createConversationId('shot-ayse', 'shot-mehmet');
  if (box.values.where((m) => m.conversationId == conversationId).isEmpty) {
    await box.put(
      'shot-msg-1',
      ChatMessageModel(
        id: 'shot-msg-1',
        conversationId: conversationId,
        senderId: 'shot-mehmet',
        senderEmail: _mehmetEmail,
        senderName: 'Mehmet Kaya',
        receiverId: 'shot-ayse',
        receiverEmail: _email,
        text: 'Akşam lamba yanıyor mu?',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    );
    await box.put(
      'shot-msg-2',
      ChatMessageModel(
        id: 'shot-msg-2',
        conversationId: conversationId,
        senderId: 'shot-ayse',
        senderEmail: _email,
        senderName: 'Ayşe Demir',
        receiverId: 'shot-mehmet',
        receiverEmail: _mehmetEmail,
        text: 'Kontrol ettim, yanıyor.',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    );
  }
}

void _signIn(String email) {
  final user = HiveDatabaseService.getRegistrationByEmail(email);
  if (user == null) {
    UserSessionService.clearCurrentUser();
    return;
  }
  UserSessionService.setCurrentUser(user);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = _ShotHttpOverrides();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _loadFonts();
    Directory('/tmp/chat-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/chat-hive',
    );
    await HiveDatabaseService.initialize();
    await _seed();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    Widget page, {
    Size size = const Size(420, 1280),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('chat-shot'),
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
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> waitForText(WidgetTester tester, String text) async {
    for (var i = 0; i < 40 && find.text(text).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
    }
  }

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['CHAT_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('chat-shot')),
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
      'chat-$page-${_after ? 'after' : 'before'}-$brightness.png';

  void expectTap(WidgetTester tester, Finder finder) {
    final size = tester.getSize(finder);
    expect(size.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(size.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
  }

  Future<void> checkListChrome(WidgetTester tester) async {
    if (!_after) return;
    expectTap(tester, find.byTooltip('Menü'));
    expectTap(tester, find.byTooltip('Arkadaş ekle'));
    expectTap(tester, find.byTooltip('Yenile'));
    final title = tester.widget<Text>(find.textContaining('SOHBETLER'));
    expect(title.style?.fontSize, SeyirTokens.typeTitle);
    expect(title.style?.color, Colors.white);

    await tester.tap(find.byTooltip('Menü'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final IgnorePointer? campaign = tester
        .element(find.byIcon(Icons.campaign))
        .findAncestorWidgetOfExactType<IgnorePointer>();
    expect(campaign?.ignoring, isTrue);
    final IgnorePointer? edit = tester
        .element(find.byIcon(Icons.edit_document))
        .findAncestorWidgetOfExactType<IgnorePointer>();
    expect(edit?.ignoring, isTrue);
    expectTap(tester, find.byTooltip('Kayıtlı davalar'));
    await tester.ensureVisible(find.byTooltip('Kayıtlı davalar'));
    await tester.tap(find.byTooltip('Kayıtlı davalar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dava Düzenle'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Menü'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('chat list light', (tester) async {
    _signIn(_email);
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ChatPage(userEmail: _email),
    );
    await waitForText(tester, 'Mehmet Kaya');
    expect(find.textContaining('SOHBETLER'), findsOneWidget);
    expect(find.text('Kontrol ettim, yanıyor.'), findsOneWidget);
    await checkListChrome(tester);
    await saveShot(tester, shot('list', 'light'));
    await releasePage(tester);
  });

  testWidgets('chat list dark', (tester) async {
    _signIn(_email);
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const ChatPage(userEmail: _email),
    );
    await waitForText(tester, 'Mehmet Kaya');
    expect(find.text('Elif Yılmaz'), findsOneWidget);
    await saveShot(tester, shot('list', 'dark'));
    await releasePage(tester);
  });

  testWidgets('chat list empty light', (tester) async {
    _signIn(_emptyEmail);
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ChatPage(userEmail: _emptyEmail),
      size: const Size(420, 1100),
    );
    await waitForText(tester, 'Grup-19 kategorisinde henüz arkadaş yok');
    expect(find.text('Grup-19 kategorisinde henüz arkadaş yok'), findsOneWidget);
    if (_after) {
      expect(find.byType(DelilSoftEmpty), findsOneWidget);
    }
    await saveShot(tester, shot('list-empty', 'light'));
    await releasePage(tester);
  });

  testWidgets('chat list empty dark', (tester) async {
    _signIn(_emptyEmail);
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const ChatPage(userEmail: _emptyEmail),
      size: const Size(420, 1100),
    );
    await waitForText(tester, 'Grup-19 kategorisinde henüz arkadaş yok');
    await saveShot(tester, shot('list-empty', 'dark'));
    await releasePage(tester);
  });

  testWidgets('chat detail light', (tester) async {
    UserSessionService.clearCurrentUser();
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ChatDetailPage(
        receiverId: 'shot-mehmet',
        receiverEmail: _mehmetEmail,
        receiverName: 'Mehmet Kaya',
        userEmail: _email,
      ),
      size: const Size(420, 860),
    );
    await waitForText(tester, 'Kontrol ettim, yanıyor.');
    expect(find.text('Akşam lamba yanıyor mu?'), findsOneWidget);
    expect(find.text('Yükleniyor...'), findsNothing);
    expect(find.text('Giriş gerekli'), findsNothing);
    if (_after) {
      expectTap(tester, find.byTooltip('Sesli mesaj gönder'));
      expectTap(tester, find.byTooltip('Gönder'));
      expectTap(tester, find.byTooltip('Medya gönder'));
      expectTap(tester, find.byTooltip('Yenile'));
    }
    await saveShot(tester, shot('detail', 'light'));
    await releasePage(tester);
  });

  testWidgets('chat detail dark', (tester) async {
    _signIn(_email);
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const ChatDetailPage(
        receiverId: 'shot-mehmet',
        receiverEmail: _mehmetEmail,
        receiverName: 'Mehmet Kaya',
        userEmail: _email,
      ),
      size: const Size(420, 860),
    );
    await waitForText(tester, 'Kontrol ettim, yanıyor.');
    await saveShot(tester, shot('detail', 'dark'));
    await releasePage(tester);
  });

  testWidgets('chat detail empty light', (tester) async {
    _signIn(_email);
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ChatDetailPage(
        receiverId: 'shot-elif',
        receiverEmail: _elifEmail,
        receiverName: 'Elif Yılmaz',
        userEmail: _email,
      ),
      size: const Size(420, 860),
    );
    await waitForText(tester, 'Henüz mesaj yok');
    expect(find.text('Henüz mesaj yok'), findsOneWidget);
    expect(find.text('No messages here yet'), findsNothing);
    if (_after) {
      expect(find.byType(DelilSoftEmpty), findsOneWidget);
    }
    await saveShot(tester, shot('detail-empty', 'light'));
    await releasePage(tester);
  });

  testWidgets('chat detail empty dark', (tester) async {
    _signIn(_email);
    await pumpPage(
      tester,
      _shotTheme(Brightness.dark),
      const ChatDetailPage(
        receiverId: 'shot-elif',
        receiverEmail: _elifEmail,
        receiverName: 'Elif Yılmaz',
        userEmail: _email,
      ),
      size: const Size(420, 860),
    );
    await waitForText(tester, 'Henüz mesaj yok');
    await saveShot(tester, shot('detail-empty', 'dark'));
    await releasePage(tester);
  });

  testWidgets('chat list refreshes last message on return', (tester) async {
    if (!_after) return;
    _signIn(_email);
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ChatPage(userEmail: _email),
    );
    await waitForText(tester, 'Kontrol ettim, yanıyor.');
    await tester.tap(find.text('Mehmet Kaya').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await waitForText(tester, 'Kontrol ettim, yanıyor.');
    await tester.runAsync(
      () => ChatService.sendMessage(
        receiverId: 'shot-mehmet',
        receiverEmail: _mehmetEmail,
        text: 'Liste yenilendi.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await waitForText(tester, 'Liste yenilendi.');
    expect(find.text('Liste yenilendi.'), findsWidgets);
    await releasePage(tester);
  }, timeout: const Timeout(Duration(seconds: 30)));

  Future<void> shotError(
    WidgetTester tester,
    Brightness brightness,
    Widget page,
    String pageName,
    String needle,
  ) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      page,
      size: const Size(420, 1100),
    );
    await waitForText(tester, needle);
    expect(find.text(needle), findsWidgets);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Grup-19 kategorisinde henüz arkadaş yok'), findsNothing);
    expect(find.text('Yükleniyor...'), findsNothing);
    await saveShot(tester, shot(pageName, brightness.name));
    await releasePage(tester);
  }

  testWidgets('chat error retry light', (tester) async {
    if (!_after) return;
    _signIn(_email);
    await shotError(
      tester,
      Brightness.light,
      const ChatPage(userEmail: _email, forceLoadError: true),
      'error-retry',
      'Sohbetler yüklenemedi',
    );
  });

  testWidgets('chat error retry dark', (tester) async {
    if (!_after) return;
    _signIn(_email);
    await shotError(
      tester,
      Brightness.dark,
      const ChatPage(userEmail: _email, forceLoadError: true),
      'error-retry',
      'Sohbetler yüklenemedi',
    );
  });

  testWidgets('chat not signed in light', (tester) async {
    if (!_after) return;
    UserSessionService.clearCurrentUser();
    await shotError(
      tester,
      Brightness.light,
      const ChatPage(),
      'not-signed-in',
      'Giriş gerekli. Sohbetleri görmek için oturum aç.',
    );
  });

  testWidgets('chat not signed in dark', (tester) async {
    if (!_after) return;
    UserSessionService.clearCurrentUser();
    await shotError(
      tester,
      Brightness.dark,
      const ChatPage(),
      'not-signed-in',
      'Giriş gerekli. Sohbetleri görmek için oturum aç.',
    );
  });

  testWidgets('chat detail login required light', (tester) async {
    if (!_after) return;
    UserSessionService.clearCurrentUser();
    await shotError(
      tester,
      Brightness.light,
      const ChatDetailPage(
        receiverId: 'shot-elif',
        receiverEmail: _elifEmail,
        receiverName: 'Elif Yılmaz',
      ),
      'detail-login-required',
      'Giriş gerekli',
    );
  });

  testWidgets('chat detail login required dark', (tester) async {
    if (!_after) return;
    UserSessionService.clearCurrentUser();
    await shotError(
      tester,
      Brightness.dark,
      const ChatDetailPage(
        receiverId: 'shot-elif',
        receiverEmail: _elifEmail,
        receiverName: 'Elif Yılmaz',
      ),
      'detail-login-required',
      'Giriş gerekli',
    );
  });

  testWidgets('chat add friend nav light', (tester) async {
    if (!_after) return;
    _signIn(_email);
    await pumpPage(
      tester,
      _shotTheme(Brightness.light),
      const ChatPage(userEmail: _email),
      size: const Size(420, 1100),
    );
    await waitForText(tester, 'Mehmet Kaya');
    await tester.tap(find.byTooltip('Arkadaş ekle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FriendshipManagementPage), findsOneWidget);
    expect(
      find.text('Arkadaş ekleme sayfasına yönlendirilecek'),
      findsNothing,
    );
    await waitForText(tester, '|| KİŞİLER ||');
    expect(find.text('|| KİŞİLER ||'), findsOneWidget);
    await saveShot(tester, shot('add-friend-nav', 'light'));
    await releasePage(tester);
  });
}

class _ShotHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ShotHttpClient();
}

class _ShotHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ShotRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _ShotRequest();

  @override
  void close({bool force = false}) {}
}

class _ShotRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _ShotHeaders();

  @override
  Future<HttpClientResponse> close() async => _ShotResponse();
}

class _ShotHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _ShotResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _png.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _ShotHeaders();

  @override
  bool get persistentConnection => false;

  @override
  bool get isRedirect => false;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_png]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
