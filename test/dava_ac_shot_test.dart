import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/widgets/dava_ac_case_card.dart';
import 'package:its19/widgets/shared/app_page_header.dart';

/// Renders the Dava Aç header and form with fixture data.
/// When DAVA_AC_SHOT_DIR is set, writes the after screenshots.
const _shotFont = 'DavaAcShot';

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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Future<void> loadFamily(String family, List<String> paths) async {
      final files = paths.map(File.new).where((file) => file.existsSync());
      if (files.isEmpty) return;
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
      await loader.load();
    }

    await loadFamily(_shotFont, const [
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
        '${Platform.environment['HOME']}/sdk/flutter';
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
  });

  Future<void> openForm(
    WidgetTester tester,
    ThemeData theme, {
    required TextEditingController davaAdi,
    required TextEditingController davali,
    required TextEditingController detay,
    required List<String> filteredUsers,
    required bool showUserSuggestions,
    required bool canDavala,
    required bool showDavaAdiError,
    required String? davaAdiErrorText,
    required bool showDavaliError,
    required String? davaliErrorText,
    String? davalaDisabledReason,
    bool isWhoboomUser = true,
    VoidCallback? onSaveDava,
    VoidCallback? onOpenDava,
    ValueChanged<String>? onSelectUser,
    ValueChanged<bool?>? onCheckboxChanged,
  }) async {
    tester.view.physicalSize = const Size(430, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dava = Dava(
      id: 'dava_shot',
      adi: davaAdi.text.isEmpty ? 'Ad  ver ' : davaAdi.text,
      davali: davali.text.isEmpty ? 'Davalı  adını gir ' : davali.text,
      mevkii: 'Davalı',
      kalanSure: '.../.../.....',
      profilResmi: 'lib/icons/03_davala_ana_icon.png',
      davaKategorisi: 'İlişkiler > Komşu',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: const Key('davaac-shot'),
              child: Column(
                children: [
                  AppPageHeader(
                    title: 'Dava Aç',
                    userEmail: null,
                    profileEmail: null,
                    isCollapsed: false,
                    onToggleCollapse: () {},
                    onToggleMenu: () {},
                    menuButton: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        MdiIcons.menuOpen,
                        size: 34,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: FiveCardCaseInformation(
                      dava: dava,
                      isExpanded: true,
                      onTap: () {},
                      davaliController: davali,
                      filteredUsers: filteredUsers,
                      showUserSuggestions: showUserSuggestions,
                      onSelectUser: onSelectUser ?? (_) {},
                      isWhoboomUser: isWhoboomUser,
                      userEmail: null,
                      davaDetayController: detay,
                      davaAdiController: davaAdi,
                      canDavala: canDavala,
                      onSaveDava: onSaveDava ?? () {},
                      onOpenDava: onOpenDava ?? () {},
                      onCheckboxChanged: onCheckboxChanged ?? (_) {},
                      showDavaAdiError: showDavaAdiError,
                      davaAdiErrorText: davaAdiErrorText,
                      showDavaliError: showDavaliError,
                      davaliErrorText: davaliErrorText,
                      davaliFocusNode: FocusNode(),
                      davalaDisabledReason: davalaDisabledReason,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> saveShot(WidgetTester tester, String filename) async {
    final dir = Platform.environment['DAVA_AC_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('davaac-shot')),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File('$dir/$filename');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  const detail = 'Gece yüksek ses komşuyu uyutmadı. ';

  testWidgets('dava ac after light', (tester) async {
    final davaAdi = TextEditingController(text: 'Komşu gürültüsü');
    final davali = TextEditingController(text: 'Ayşe Yılmaz');
    final detay = TextEditingController(text: detail * 9);
    addTearDown(davaAdi.dispose);
    addTearDown(davali.dispose);
    addTearDown(detay.dispose);

    await openForm(
      tester,
      _shotTheme(Brightness.light),
      davaAdi: davaAdi,
      davali: davali,
      detay: detay,
      filteredUsers: const ['Ayşe Yılmaz'],
      showUserSuggestions: false,
      canDavala: true,
      showDavaAdiError: false,
      davaAdiErrorText: null,
      showDavaliError: false,
      davaliErrorText: null,
    );
    expect(find.text('Dava Aç'), findsOneWidget);
    expect(find.text('Davalı seçimi'), findsOneWidget);
    expect(find.text('Dava adı & kategori'), findsOneWidget);
    expect(find.text('Dava detayı'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    expect(find.text('${detay.text.length} / 285'), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);
    expect(find.text('Davayı Aç'), findsOneWidget);
    expect(find.text('İlişkiler > Komşu'), findsOneWidget);
    await saveShot(tester, 'davaac-after-light.png');
  });

  testWidgets('dava ac after dark', (tester) async {
    final davaAdi = TextEditingController(text: 'Komşu gürültüsü');
    final davali = TextEditingController(text: 'Ayşe Yılmaz');
    final detay = TextEditingController(text: detail * 9);
    addTearDown(davaAdi.dispose);
    addTearDown(davali.dispose);
    addTearDown(detay.dispose);

    await openForm(
      tester,
      _shotTheme(Brightness.dark),
      davaAdi: davaAdi,
      davali: davali,
      detay: detay,
      filteredUsers: const ['Ayşe Yılmaz'],
      showUserSuggestions: false,
      canDavala: true,
      showDavaAdiError: false,
      davaAdiErrorText: null,
      showDavaliError: false,
      davaliErrorText: null,
    );
    expect(find.text('Dava Aç'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('Davayı Aç'), findsOneWidget);
    await saveShot(tester, 'davaac-after-dark.png');
  });

  testWidgets('dava ac after errors', (tester) async {
    final davaAdi = TextEditingController();
    final davali = TextEditingController();
    final detay = TextEditingController();
    addTearDown(davaAdi.dispose);
    addTearDown(davali.dispose);
    addTearDown(detay.dispose);
    const nameError =
        'Davaya bir başlık vermelisin. Dava adını en az 6 karakter olacak şekilde doldur.';
    const partyError =
        'Davalı bilgisini doldurmalısın. Davalı adını girmeden kaydedemezsin.';

    await openForm(
      tester,
      _shotTheme(Brightness.light),
      davaAdi: davaAdi,
      davali: davali,
      detay: detay,
      filteredUsers: const [],
      showUserSuggestions: false,
      canDavala: false,
      showDavaAdiError: true,
      davaAdiErrorText: nameError,
      showDavaliError: true,
      davaliErrorText: partyError,
    );
    expect(find.text('0/3'), findsOneWidget);
    expect(find.text(nameError), findsWidgets);
    expect(find.text(partyError), findsOneWidget);
    expect(find.text('0 / 285'), findsOneWidget);
    await saveShot(tester, 'davaac-after-errors.png');
  });

  testWidgets('dava ac after suggestions', (tester) async {
    final davaAdi = TextEditingController();
    final davali = TextEditingController(text: 'Ayş');
    final detay = TextEditingController();
    addTearDown(davaAdi.dispose);
    addTearDown(davali.dispose);
    addTearDown(detay.dispose);
    String? selected;
    bool? member;

    await openForm(
      tester,
      _shotTheme(Brightness.light),
      davaAdi: davaAdi,
      davali: davali,
      detay: detay,
      filteredUsers: const ['Ayşe Yılmaz', 'Ahmet Demir', 'Mehmet Kaya'],
      showUserSuggestions: true,
      canDavala: false,
      showDavaAdiError: false,
      davaAdiErrorText: null,
      showDavaliError: false,
      davaliErrorText: null,
      onSelectUser: (name) => selected = name,
      onCheckboxChanged: (value) => member = value,
    );
    expect(find.text('Önerilen Üyeler (3)'), findsOneWidget);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    expect(find.text('Ahmet Demir'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('üye ara... (en az 4 karakter)'), findsOneWidget);
    await saveShot(tester, 'davaac-after-suggestions.png');

    await tester.tap(find.text('Ayşe Yılmaz'));
    expect(selected, 'Ayşe Yılmaz');

    await tester.tap(find.byType(Checkbox));
    expect(member, isFalse);
  });

  testWidgets('kaydet and davayı aç keep their callbacks', (tester) async {
    final davaAdi = TextEditingController(text: 'Komşu gürültüsü');
    final davali = TextEditingController(text: 'Ayşe Yılmaz');
    final detay = TextEditingController(text: detail * 9);
    addTearDown(davaAdi.dispose);
    addTearDown(davali.dispose);
    addTearDown(detay.dispose);
    var saves = 0;
    var opens = 0;

    await openForm(
      tester,
      _shotTheme(Brightness.light),
      davaAdi: davaAdi,
      davali: davali,
      detay: detay,
      filteredUsers: const ['Ayşe Yılmaz'],
      showUserSuggestions: false,
      canDavala: false,
      showDavaAdiError: false,
      davaAdiErrorText: null,
      showDavaliError: false,
      davaliErrorText: null,
      davalaDisabledReason:
          'Mavi tikli ünlülere yalnızca mavi tikli kullanıcılar dava açabilir.',
      onSaveDava: () => saves++,
      onOpenDava: () => opens++,
    );
    expect(
      find.text(
        'Mavi tikli ünlülere yalnızca mavi tikli kullanıcılar dava açabilir.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    expect(saves, 1);
    expect(opens, 0);

    await tester.ensureVisible(find.text('Davayı Aç'));
    await tester.tap(find.text('Davayı Aç'));
    await tester.pump();
    expect(opens, 0);

    await openForm(
      tester,
      _shotTheme(Brightness.light),
      davaAdi: davaAdi,
      davali: davali,
      detay: detay,
      filteredUsers: const ['Ayşe Yılmaz'],
      showUserSuggestions: false,
      canDavala: true,
      showDavaAdiError: false,
      davaAdiErrorText: null,
      showDavaliError: false,
      davaliErrorText: null,
      onSaveDava: () => saves++,
      onOpenDava: () => opens++,
    );
    await tester.ensureVisible(find.text('Davayı Aç'));
    await tester.tap(find.text('Davayı Aç'));
    await tester.pump();
    expect(opens, 1);
  });
}
