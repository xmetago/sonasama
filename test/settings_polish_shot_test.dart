import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/services/firebase_password_gateway.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/forgot_password_page.dart';
import 'package:its19/screens/hesap_gizlilik_ayarlari_page.dart';
import 'package:its19/screens/privacy_policy_page.dart';
import 'package:its19/screens/terms_conditions_page.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/delil_surface.dart';
import 'package:its19/widgets/privacy_terms_text.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ayarlar, gizlilik, şifre ve sözleşmeler ekran görüntüsü.
///
/// SETTINGS_SHOT_DIR ve SETTINGS_SHOT_PHASE (before | after) set ise
/// `settings-<sayfa>-<phase>-<brightness>.png` yazar. Firebase yok; veriler Hive'da.
const _shotFont = 'cocon';
const _fallbackFont = 'SettingsFallback';
const _email = 'ayse.demir@example.com';
const _philosophy = 'Adalet, sabır ve kahkaha.';
const _address = 'Galata Postanesi, kutu 19';
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

bool get _after =>
    (Platform.environment['SETTINGS_SHOT_PHASE'] ?? 'after') != 'before';

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
    appBarTheme: base.appBarTheme,
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

RegistrationModel _person() {
  return RegistrationModel(
    id: 'shot-ayse',
    judgeName: 'Ayşe Demir',
    email: _email,
    password: 'EskiSifre1!',
    country: 'Türkiye',
    oath: true,
    isEmailVerified: true,
    createdAt: DateTime(2024, 3, 1),
    lastLoginAt: DateTime(2026, 11, 1),
  );
}

Future<void> _seed() async {
  if (HiveDatabaseService.getRegistrationByEmail(_email) == null) {
    await HiveDatabaseService.addRegistration(_person());
  }
  final settings = await HiveDatabaseService.getOrCreateSettings(_email);
  settings.philosophy = _philosophy;
  settings.postrestantAddress = _address;
  settings.country = 'Türkiye';
  settings.language = 'Türkçe';
  settings.profileImageUrl = 'data:image/png;base64,$_pngBase64';
  settings.privacySettings['seyir_herkes'] = false;
  await HiveDatabaseService.saveSettings(settings);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final hiveDir = Directory('/tmp/settings-hive');
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
    hiveDir.createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/settings-hive',
    );
    await HiveDatabaseService.initialize();
    await _seed();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ThemeData theme,
    Widget page, {
    Size size = const Size(420, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('settings-shot'),
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
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    Object? error;
    while ((error = tester.takeException()) != null) {
      final text = error.toString();
      final imageNoise = text.contains('NetworkImage') ||
          text.contains('HTTP request failed') ||
          text.contains('statusCode: 400') ||
          text.contains('Image provider') ||
          text.contains('Multiple exceptions');
      if (_after || !imageNoise) {
        fail('Beklenmeyen hata: $text');
      }
    }
  }

  void drainImageErrors(WidgetTester tester) {
    if (_after) return;
    Object? error;
    while ((error = tester.takeException()) != null) {
      final text = error.toString();
      if (!text.contains('NetworkImage') &&
          !text.contains('HTTP request failed') &&
          !text.contains('statusCode: 400') &&
          !text.contains('Multiple exceptions') &&
          !text.contains('Image provider')) {
        fail('Beklenmeyen hata: $text');
      }
    }
  }

  Future<void> waitForText(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump();
      drainImageErrors(tester);
    }
    if (find.text(text).evaluate().isEmpty) {
      final texts = find
          .byType(Text)
          .evaluate()
          .map((element) => (element.widget as Text).data)
          .whereType<String>()
          .take(24)
          .join(' | ');
      fail('Metin bulunamadı: $text. Görünenler: $texts');
    }
  }

  Future<void> releasePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    drainImageErrors(tester);
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['SETTINGS_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('settings-shot')),
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
      'settings-$page-${_after ? 'after' : 'before'}-$brightness.png';

  Future<void> shotSettings(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const HesapGizlilikAyarlariPage(userEmail: _email),
      size: const Size(420, 3600),
    );
    await waitForText(tester, 'PROFİL RESMİNİZ');
    expect(find.text(_philosophy), findsOneWidget);
    expect(find.text(_address), findsOneWidget);
    expect(find.text('Türkiye'), findsOneWidget);
    expect(find.text('Davalılarım'), findsOneWidget);

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    final country = tester.widget<Text>(find.text('Türkiye'));
    if (_after) {
      expect(find.text('Davalarım'), findsNWidgets(2));
      expect(find.text('Davalllarım'), findsNothing);
      expect(find.text('Postrestant Adres'), findsOneWidget);
      expect(find.text('Postrestant Adress:'), findsNothing);
      expect(find.text('Dil'), findsOneWidget);
      expect(find.text('Türkçe'), findsWidgets);
      expect(find.text('ŞİFRE DEĞİŞTİR'), findsOneWidget);
      expect(avatar.backgroundImage, isA<MemoryImage>());
      expect(country.style?.fontSize, SeyirTokens.typeTitle);
      expect(country.style?.color, isNot(Colors.black87));
      final section = tester.widget<Text>(find.text('SEYİR DEFTERİMİ GÖRSÜN'));
      expect(section.style?.fontSize, SeyirTokens.typeTitle);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.padding, const EdgeInsets.all(SeyirTokens.space3));
      for (final tooltip in ['Kaydet', 'Varsayılanlara Sıfırla', 'Önizle', 'Resim Ekle']) {
        expect(
          tester.getSize(find.byTooltip(tooltip)).height,
          greaterThanOrEqualTo(SeyirTokens.tapTarget),
        );
      }
      expect(
        tester.getSize(find.byType(Switch).first).height,
        greaterThanOrEqualTo(SeyirTokens.tapTarget),
      );
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tüm Değişiklikleri Kaydet'),
      );
      expect(
        save.style?.minimumSize?.resolve(const <WidgetState>{}),
        isNotNull,
      );
    } else {
      expect(find.text('Davalllarım'), findsNWidgets(2));
      expect(find.text('Postrestant Adress:'), findsOneWidget);
      expect(find.text('Dil'), findsNothing);
      expect(find.text('ŞİFRE DEĞİŞTİR'), findsNothing);
      expect(avatar.backgroundImage, isA<NetworkImage>());
      expect(country.style?.color, Colors.black87);
      expect(country.style?.fontSize, 16);
    }
    await saveShot(tester, shot('form', brightness.name));
    await releasePage(tester);
  }

  testWidgets('settings form light', (tester) async {
    await shotSettings(tester, Brightness.light);
  });

  testWidgets('settings form dark', (tester) async {
    await shotSettings(tester, Brightness.dark);
  });

  Future<void> shotLogin(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const HesapGizlilikAyarlariPage(),
      size: const Size(420, 720),
    );
    if (_after) {
      await waitForText(tester, 'Giriş gerekli');
      expect(find.byType(DelilSoftEmpty), findsOneWidget);
      expect(find.text('Ayarlar yüklenemedi'), findsNothing);
      expect(find.text('Tekrar dene'), findsNothing);
    } else {
      await waitForText(tester, 'Ayarlar yüklenemedi');
      expect(find.byType(DelilLoadError), findsNothing);
      expect(find.text('Giriş gerekli'), findsNothing);
    }
    await saveShot(tester, shot('login', brightness.name));
    if (!_after) {
      await saveShot(tester, shot('error', brightness.name));
    }
    await releasePage(tester);
  }

  testWidgets('settings login light', (tester) async {
    await shotLogin(tester, Brightness.light);
  });

  testWidgets('settings login dark', (tester) async {
    await shotLogin(tester, Brightness.dark);
  });

  Future<void> shotForgot(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const ForgotPasswordPage(),
      size: const Size(420, 760),
    );
    await waitForText(tester, 'Şifre Sıfırlama');
    expect(find.text('Sıfırlama Linki Gönder'), findsOneWidget);
    final description = tester.widget<Text>(
      find.textContaining('Kayıtlı e-posta adresinizi girin'),
    );
    final button = find.widgetWithText(ElevatedButton, 'Sıfırlama Linki Gönder');
    if (_after) {
      expect(description.style?.fontSize, SeyirTokens.typeBody);
      expect(description.style?.color, isNot(Colors.black87));
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(SeyirTokens.tapTarget),
      );
      expect(find.text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'), findsNothing);
    }
    await saveShot(tester, shot('forgot', brightness.name));
    await releasePage(tester);
  }

  testWidgets('forgot light', (tester) async {
    await shotForgot(tester, Brightness.light);
  });

  testWidgets('forgot dark', (tester) async {
    await shotForgot(tester, Brightness.dark);
  });

  Future<void> shotLegal(
    WidgetTester tester,
    Brightness brightness,
    Widget page,
    String needle,
    String stem,
  ) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      page,
      size: const Size(420, 980),
    );
    final richFinder = find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText().contains(needle),
    );
    expect(richFinder, findsOneWidget);
    final rich = tester.widget<RichText>(richFinder);
    expect(rich.text.toPlainText(), contains(needle));
    if (_after) {
      expect(rich.text.style?.fontSize, SeyirTokens.typeTitle);
      expect(rich.text.style?.color, isNot(Colors.black));
      final palette = SeyirPalette.of(tester.element(richFinder));
      expect(rich.text.style?.color, palette.textPrimary);
    } else {
      expect(rich.text.style?.color, Colors.black);
    }
    await saveShot(tester, shot(stem, brightness.name));
    await releasePage(tester);
  }

  testWidgets('privacy light', (tester) async {
    await shotLegal(
      tester,
      Brightness.light,
      const PrivacyPolicyPage(),
      'WhoBoom Gizlilik Politikası',
      'privacy',
    );
  });

  testWidgets('privacy dark', (tester) async {
    await shotLegal(
      tester,
      Brightness.dark,
      const PrivacyPolicyPage(),
      'WhoBoom Gizlilik Politikası',
      'privacy',
    );
  });

  testWidgets('terms light', (tester) async {
    await shotLegal(
      tester,
      Brightness.light,
      const TermsConditionsPage(),
      'WhoBoom Kullanım Koşulları',
      'terms',
    );
  });

  testWidgets('terms dark', (tester) async {
    await shotLegal(
      tester,
      Brightness.dark,
      const TermsConditionsPage(),
      'WhoBoom Kullanım Koşulları',
      'terms',
    );
  });

  Future<void> shotAgreements(WidgetTester tester, Brightness brightness) async {
    await pumpPage(
      tester,
      _shotTheme(brightness),
      const Scaffold(body: PrivacyTermsText()),
      size: const Size(420, 220),
    );
    await waitForText(tester, 'Kaydolarak ');
    expect(find.text('gizlilik'), findsOneWidget);
    expect(find.text('koşullarınızı'), findsOneWidget);
    if (_after) {
      final lead = tester.widget<Text>(find.text('Kaydolarak '));
      expect(lead.style?.fontSize, SeyirTokens.typeBody);
      expect(lead.style?.color, isNot(Colors.black));
      final link = tester.widget<Text>(find.text('gizlilik'));
      expect(link.style?.color, isNot(Colors.blue));
    }
    await saveShot(tester, shot('agreements', brightness.name));
    await releasePage(tester);
  }

  testWidgets('agreements light', (tester) async {
    await shotAgreements(tester, Brightness.light);
  });

  testWidgets('agreements dark', (tester) async {
    await shotAgreements(tester, Brightness.dark);
  });

  Future<void> shotError(WidgetTester tester, Brightness brightness) async {
    if (!_after) return;
    await pumpPage(
      tester,
      _shotTheme(brightness),
      HesapGizlilikAyarlariPage(
        userEmail: _email,
        settingsLoader: (_) async => throw StateError('ayarlar'),
      ),
      size: const Size(420, 720),
    );
    await waitForText(tester, 'Ayarlar yüklenemedi');
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.byType(DelilLoadError), findsOneWidget);
    expect(find.text('Giriş gerekli'), findsNothing);
    await saveShot(tester, shot('error', brightness.name));
    await releasePage(tester);
  }

  testWidgets('settings error light', (tester) async {
    await shotError(tester, Brightness.light);
  });

  testWidgets('settings error dark', (tester) async {
    await shotError(tester, Brightness.dark);
  });

  Future<void> pumpAuthPage(
    WidgetTester tester,
    AuthProvider auth,
    Widget page, {
    Size size = const Size(420, 3600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => DavaProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _shotTheme(Brightness.light),
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

  testWidgets('reset asks before wiping settings', (tester) async {
    final auth = AuthProvider();
    await pumpAuthPage(
      tester,
      auth,
      const HesapGizlilikAyarlariPage(userEmail: _email),
      size: const Size(420, 900),
    );
    await waitForText(tester, _philosophy);
    final herkes = tester.widgetList<Switch>(find.byType(Switch)).elementAt(3);
    expect(herkes.value, isFalse);

    Future<void> pressReset() {
      return tester.runAsync(() async {
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Varsayılanlara Sıfırla'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed!
            .call();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    }

    await pressReset();
    await tester.pump();
    expect(
      find.text('Tüm ayarlar varsayılan değerlere sıfırlanacak. Emin misiniz?'),
      findsOneWidget,
    );
    await tester.runAsync(() async {
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Vazgeç')).onPressed!.call();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(find.text(_philosophy), findsOneWidget);

    await pressReset();
    await tester.pump();
    await tester.runAsync(() async {
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Sıfırla')).onPressed!.call();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    expect(find.text(_philosophy), findsNothing);
    final resetHerkes = tester.widgetList<Switch>(find.byType(Switch)).elementAt(3);
    expect(resetHerkes.value, isTrue);
    await tester.runAsync(_seed);
  });

  testWidgets('language selection is saved', (tester) async {
    final auth = AuthProvider();
    await pumpAuthPage(
      tester,
      auth,
      const HesapGizlilikAyarlariPage(userEmail: _email),
      size: const Size(420, 900),
    );
    await waitForText(tester, 'Dil');
    final dropdown = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const Key('settings-language')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    dropdown.onChanged!('English');
    await tester.pump();
    await tester.runAsync(() async {
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Kaydet'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed!
          .call();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    expect(HiveDatabaseService.getSettings(_email)?.language, 'English');
    await tester.runAsync(_seed);
  });

  testWidgets('change password reports turkish results', (tester) async {
    String? seenEmail;
    final auth = AuthProvider(
      passwordAuthClient: PasswordAuthClient(
        reauthenticateAndUpdate: ({
          required String email,
          required String currentPassword,
          required String newPassword,
        }) async {
          seenEmail = email;
        },
      ),
    );
    await tester.runAsync(() => auth.login(_email, 'EskiSifre1!'));
    await pumpAuthPage(
      tester,
      auth,
      const HesapGizlilikAyarlariPage(userEmail: _email),
      size: const Size(420, 900),
    );
    await waitForText(tester, 'ŞİFRE DEĞİŞTİR');

    Future<void> fill(String current, String next, String confirm) async {
      tester.widget<TextField>(find.byKey(const Key('password-current'))).controller!.text =
          current;
      tester.widget<TextField>(find.byKey(const Key('password-new'))).controller!.text = next;
      tester.widget<TextField>(find.byKey(const Key('password-confirm'))).controller!.text =
          confirm;
      await tester.runAsync(() async {
        tester.widget<ElevatedButton>(find.byKey(const Key('password-submit'))).onPressed!.call();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
    }

    await fill('EskiSifre1!', 'YeniSifre2!', 'BaskaSifre3!');
    expect(find.text('Yeni şifreler eşleşmiyor.'), findsOneWidget);

    await fill('EskiSifre1!', 'zayif', 'zayif');
    expect(find.textContaining('Şifre çok zayıf'), findsOneWidget);

    await fill('YanlisSifre1!', 'YeniSifre2!', 'YeniSifre2!');
    expect(find.text('Mevcut şifre hatalı.'), findsOneWidget);

    await fill('EskiSifre1!', 'YeniSifre2!', 'YeniSifre2!');
    expect(find.text('Şifre başarıyla değiştirildi.'), findsOneWidget);
    expect(seenEmail, _email);
    expect(auth.currentUser?.password, 'YeniSifre2!');
    await tester.runAsync(() => auth.changePassword('YeniSifre2!', 'EskiSifre1!'));
  });

  testWidgets('forgot password sends and reports errors', (tester) async {
    final completer = Completer<void>();
    final emails = <String>[];
    final auth = AuthProvider(
      passwordAuthClient: PasswordAuthClient(
        sendResetEmail: (email) {
          emails.add(email);
          return completer.future;
        },
      ),
    );
    await pumpAuthPage(
      tester,
      auth,
      const ForgotPasswordPage(),
      size: const Size(420, 760),
    );
    await waitForText(tester, 'Şifre Sıfırlama');
    expect(
      tester.getSize(find.byType(ElevatedButton)).height,
      greaterThanOrEqualTo(SeyirTokens.tapTarget),
    );

    tester.widget<TextField>(find.byType(TextField)).controller!.text = 'gecersiz';
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sıfırlama Linki Gönder'))
        .onPressed!
        .call();
    await tester.pump();
    expect(find.text('Geçerli bir e-posta adresi giriniz.'), findsOneWidget);
    expect(emails, isEmpty);

    tester.widget<TextField>(find.byType(TextField)).controller!.text = _email;
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sıfırlama Linki Gönder'))
        .onPressed!
        .call();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete();
    await tester.pump();
    expect(emails, [_email]);
    expect(
      find.text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'),
      findsOneWidget,
    );

    final failing = AuthProvider(
      passwordAuthClient: PasswordAuthClient(
        sendResetEmail: (_) async => throw PasswordAuthException('user-not-found'),
      ),
    );
    await pumpAuthPage(
      tester,
      failing,
      const ForgotPasswordPage(),
      size: const Size(420, 760),
    );
    await waitForText(tester, 'Şifre Sıfırlama');
    tester.widget<TextField>(find.byType(TextField)).controller!.text = _email;
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sıfırlama Linki Gönder'))
        .onPressed!
        .call();
    await tester.pump();
    expect(find.text('Bu e-posta ile kayıtlı bir hesap bulunamadı.'), findsOneWidget);
  });
}
