import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/gelen_davalar_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:provider/provider.dart';

const _email = 'ayse.demir@example.com';
const _other = 'mehmet.kaya@example.com';
const _konu =
    'Duvar sınırı komşunun bahçesine taşıyor ve geçişi kapatıyor. İkinci cümle de kartta kesilmeden önce görünür.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Directory('/tmp/gelen-davalar-hive').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/gelen-davalar-hive',
    );
    await HiveDatabaseService.initialize();
    await _register(_email, 'Ayşe Demir', 'polish-ayse');
    await _register(_other, 'Mehmet Kaya', 'polish-mehmet');
    await HiveDatabaseService.getOrCreateSettings(_email);
    await HiveDatabaseService.getOrCreateSettings(_other);
    await HiveDatabaseService.purgeLegacyKatildigimTestRows(_email);
    await HiveDatabaseService.purgeLegacyKatildigimTestRows(_other);
    await HiveDatabaseService.saveHukum(
      davaId: 'warmup-box',
      userRole: 'warmup',
      hukumText: 'warmup',
      userEmail: _email,
    );
  });

  setUp(() async {
    HiveDatabaseService.clearIncomingDavalar(_email);
    HiveDatabaseService.clearIncomingDavalar(_other);
    for (final id in const [
      'polish-konu-1',
      'polish-reject-1',
      'polish-commit-1',
      'polish-dispose-1',
      'polish-urgent-1',
      'polish-live-1',
      'polish-live-2',
    ]) {
      await HiveDatabaseService.removeKatildigimDava(_email, id);
      await HiveDatabaseService.removeKatildigimDava(_other, id);
    }
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    Brightness brightness = Brightness.light,
    Size size = const Size(480, 2800),
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ThemeData base =
        brightness == Brightness.dark ? WhoBoomTheme.dark : WhoBoomTheme.light;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DavaProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: base,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(disableAnimations: disableAnimations),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: page,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
  }

  Future<void> waitForText(WidgetTester tester, String text) async {
    for (var i = 0; i < 20 && find.text(text).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
    }
  }

  Future<void> flush(WidgetTester tester, {int ticks = 8}) async {
    for (var i = 0; i < ticks; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> release(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  }

  /// Snackbar süresi, giriş animasyonu bitince başlar.
  Future<void> letRejectSnackBarExpire(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
  }

  testWidgets('kart konusu, tek dokunuş ve görev onayı', (tester) async {
    const id = 'polish-konu-1';
    _seedPair(id);
    await pumpPage(
      tester,
      const GelenDavalarPage(userEmail: _email),
      brightness: Brightness.dark,
    );
    await waitForText(tester, 'Bahçe duvarı');

    final konu = tester.widget<Text>(find.text(_konu));
    expect(konu.maxLines, 2);
    expect(konu.overflow, TextOverflow.ellipsis);
    expect(find.text('Çift tıkla'), findsNothing);
    expect(find.textContaining('çift tıkla'), findsNothing);

    final redSize = tester.getSize(find.byKey(const Key('gelen-reddet')));
    expect(redSize.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(redSize.width, greaterThanOrEqualTo(SeyirTokens.tapTarget));
    expect(
      tester.widget<Text>(find.text('RED ET')).style?.fontSize,
      SeyirTokens.typeTitle,
    );
    expect(
      tester.widget<Text>(find.text('KABUL ET')).style?.fontSize,
      SeyirTokens.typeTitle,
    );

    await tester.ensureVisible(find.text('KABUL ET'));
    await tester.tap(find.text('KABUL ET'));
    await flush(tester);
    expect(find.text('Yargıç'), findsOneWidget);
    expect(find.text('Görevi onayla'), findsOneWidget);

    ElevatedButton confirmButton() {
      return tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('gorevi-onayla')),
          matching: find.byType(ElevatedButton),
        ),
      );
    }

    expect(confirmButton().onPressed, isNull);

    await tester.ensureVisible(find.text('Yargıç'));
    await tester.tap(find.text('Yargıç'));
    await tester.pump();

    expect(confirmButton().onPressed, isNotNull);
    expect(
      tester.widget<Text>(find.text('Görevi onayla')).style?.fontSize,
      SeyirTokens.typeTitle,
    );
    final confirmSize = tester.getSize(find.byKey(const Key('gorevi-onayla')));
    expect(confirmSize.height, greaterThanOrEqualTo(SeyirTokens.tapTarget));

    final roleFill = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('gelen-role-Yargıç')),
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .first
        .color;
    final palette = SeyirPalette(WhoBoomTheme.dark.colorScheme, Brightness.dark);
    expect(roleFill, palette.brandSoft);
    expect(roleFill, isNot(Colors.white));
    expect(roleFill, isNot(const Color(0xFFE8F5E9)));

    await tester.ensureVisible(find.byKey(const Key('gorevi-onayla')));
    await tester.tap(find.byKey(const Key('gorevi-onayla')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await waitForText(tester, 'Dava kabul edildi');

    expect(find.text('Gelen Davalar'), findsOneWidget);
    expect(find.text('Dava kabul edildi'), findsOneWidget);
    expect(find.text('Yargıla’ya git'), findsOneWidget);
    expect(find.text('Bahçe duvarı'), findsNothing);
    await release(tester);
  });

  testWidgets('red onayı yalnızca bu kullanıcıyı siler, geri al yazmaz', (tester) async {
    const id = 'polish-reject-1';
    _seedPair(id);
    await pumpPage(
      tester,
      const GelenDavalarPage(userEmail: _email),
      size: const Size(480, 1200),
    );
    await waitForText(tester, 'Bahçe duvarı');

    await tester.ensureVisible(find.text('RED ET'));
    await tester.tap(find.text('RED ET'));
    await tester.pump();
    expect(
      find.text('Bu davayı reddetmek istediğine emin misin?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Vazgeç'));
    await tester.pump();
    expect(find.text('Bahçe duvarı'), findsOneWidget);
    expect(_hasIncoming(_email, id), isTrue);
    expect(_hasIncoming(_other, id), isTrue);

    await tester.tap(find.text('RED ET'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('gelen-reddet-onay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Bahçe duvarı'), findsNothing);
    expect(find.text('Geri al'), findsOneWidget);
    expect(_hasIncoming(_email, id), isTrue);
    expect(_hasIncoming(_other, id), isTrue);

    await tester.tap(find.byType(SnackBarAction));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();

    expect(find.text('Bahçe duvarı'), findsOneWidget);
    expect(_hasIncoming(_email, id), isTrue);
    expect(_hasIncoming(_other, id), isTrue);
    expect(_joined(_email, id), isFalse);
    await release(tester);
  });

  testWidgets('süre dolunca red yalnızca mevcut kullanıcının kutusundan düşer', (tester) async {
    const id = 'polish-commit-1';
    _seedPair(id);
    await pumpPage(
      tester,
      const GelenDavalarPage(userEmail: _email),
      size: const Size(480, 1200),
    );
    await waitForText(tester, 'Bahçe duvarı');

    await tester.tap(find.text('RED ET'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('gelen-reddet-onay')));
    await tester.pump();
    await letRejectSnackBarExpire(tester);

    expect(_hasIncoming(_email, id), isFalse);
    expect(_hasIncoming(_other, id), isTrue);
    expect(_joined(_email, id), isTrue);
    final opened = HiveDatabaseService.getOpenedDavaById(id);
    expect(opened?['davaOverallStatus'], 'Reddedildi/Çekildi');
    final notes = opened?['withdrawalNarratives'];
    expect(notes, isA<List>());
    expect((notes as List).isNotEmpty, isTrue);
    await release(tester);
  });

  testWidgets('sayfa kapanınca bekleyen red yazılır', (tester) async {
    const id = 'polish-dispose-1';
    _seedPair(id);
    await pumpPage(tester, const GelenDavalarPage(userEmail: _email));
    await waitForText(tester, 'Bahçe duvarı');

    await tester.tap(find.text('RED ET'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('gelen-reddet-onay')));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump(const Duration(seconds: 6));

    expect(_hasIncoming(_email, id), isFalse);
    expect(_hasIncoming(_other, id), isTrue);
  });

  testWidgets('yakın süre metni animasyon kapalıyken de durur', (tester) async {
    const id = 'polish-urgent-1';
    _seedPair(
      id,
      createdAt: DateTime.now().subtract(const Duration(hours: 100)),
    );
    await pumpPage(
      tester,
      const GelenDavalarPage(userEmail: _email),
      disableAnimations: true,
    );
    await waitForText(tester, 'Bahçe duvarı');
    expect(find.textContaining(RegExp(r'Karar için \d+ saat kaldı')), findsOneWidget);
    await release(tester);
  });

  testWidgets('yükleme, hata ve canlı liste', (tester) async {
    await pumpPage(
      tester,
      const GelenDavalarPage(
        key: Key('gelen-loading'),
        userEmail: _email,
        forceLoading: true,
      ),
      size: const Size(480, 1400),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pumpPage(
      tester,
      const GelenDavalarPage(
        key: Key('gelen-error'),
        userEmail: _email,
        forceLoadError: true,
      ),
      size: const Size(480, 1600),
    );
    await waitForText(tester, 'Tekrar dene');
    expect(find.text('Gelen davalar yüklenemedi', skipOffstage: false), findsOneWidget);
    expect(find.text('Tekrar dene', skipOffstage: false), findsOneWidget);

    const id = 'polish-live-1';
    _seedPair(id);
    await pumpPage(tester, const GelenDavalarPage(userEmail: _email));
    await waitForText(tester, 'Bahçe duvarı');
    expect(find.text('1'), findsWidgets);

    HiveDatabaseService.addIncomingDava(_email, <String, dynamic>{
      'id': 'polish-live-2',
      'davaId': 'polish-live-2',
      'adi': 'Yeni gelen',
      'davaAdi': 'Yeni gelen',
      'davali': 'Selim Aras',
      'davaci': 'Ayşe Demir',
      'mevkii': '',
      'kalanSure': '100 saat',
      'profilResmi': 'lib/icons/03_davala_ana_icon.png',
      'davaKonusu': 'Taze konu satırı',
      'createdAt': DateTime.now().toIso8601String(),
      'openedAt': DateTime.now().toIso8601String(),
      'lifecycleStatus': 'AwaitingRole',
    });
    await waitForText(tester, 'Yeni gelen');
    expect(find.text('Yeni gelen'), findsOneWidget);
    expect(find.text('Taze konu satırı'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    await release(tester);
  });
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

void _seedPair(String id, {DateTime? createdAt}) {
  final at = (createdAt ?? DateTime.now().subtract(const Duration(hours: 3))).toIso8601String();
  final row = <String, dynamic>{
    'id': id,
    'davaId': id,
    'adi': 'Bahçe duvarı',
    'davaAdi': 'Bahçe duvarı',
    'davali': 'Selim Aras',
    'davaci': 'Ayşe Demir',
    'mevkii': '',
    'kalanSure': '117 saat',
    'profilResmi': 'lib/icons/03_davala_ana_icon.png',
    'davaKonusu': _konu,
    'createdAt': at,
    'openedAt': at,
    'lifecycleStatus': 'AwaitingRole',
  };
  HiveDatabaseService.addIncomingDava(_email, Map<String, dynamic>.from(row));
  HiveDatabaseService.addIncomingDava(_other, Map<String, dynamic>.from(row));
  HiveDatabaseService.saveOpenedDava(<String, dynamic>{
    'id': id,
    'userEmail': _email,
    'davaciEmail': _email,
    'davaAdi': 'Bahçe duvarı',
    'adi': 'Bahçe duvarı',
    'davaci': 'Ayşe Demir',
    'davali': 'Selim Aras',
    'kategori': 'Komşuluk',
    'davaKonusu': _konu,
    'openedAt': at,
    'createdAt': at,
    'isOpened': true,
  });
}

bool _hasIncoming(String email, String id) {
  return HiveDatabaseService.getIncomingDavalar(email).any((dava) {
    final itemId = (dava['id'] ?? '').toString();
    final davaId = (dava['davaId'] ?? '').toString();
    return itemId == id || davaId == id;
  });
}

bool _joined(String email, String id) {
  return HiveDatabaseService.getKatildigimDavalar(email).any((dava) {
    final itemId = (dava['id'] ?? '').toString();
    final davaId = (dava['davaId'] ?? '').toString();
    return itemId == id || davaId == id;
  });
}
