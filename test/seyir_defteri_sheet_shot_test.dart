import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/widgets/ilgililerin_seyir_defteri_widgeti.dart';
import 'package:its19/widgets/seyir_defteri/seyir_sheet_chrome.dart';

/// Renders the seyir defteri sheet with fixture data and, when SEYIR_SHOT_DIR
/// is set, writes light/dark PNGs there. The assertions stay valid for CI.
///
/// `davaId` stays empty so the sheet paints its chrome without opening Hive.
const _shotFont = 'SeyirShot';

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

ThemeData _sheetTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF34DFAE),
      brightness: brightness,
    ),
    fontFamily: _shotFont,
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
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    await loadFamily('MaterialIcons', [
      if (flutterRoot != null)
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      '/home/ubuntu/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
    final mdiRoot = _packageRoot('flutter_material_design_icons');
    await loadFamily(
      'packages/flutter_material_design_icons/Material Design Icons',
      [
        if (mdiRoot != null) '$mdiRoot/assets/materialdesignicons-webfont.ttf',
      ],
    );
  });

  final openedAt = DateTime.now().subtract(const Duration(days: 3, hours: 2));
  final absolute =
      '${openedAt.day.toString().padLeft(2, '0')}.${openedAt.month.toString().padLeft(2, '0')}.${openedAt.year}';

  Future<void> openSheet(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              key: const Key('seyir-shot'),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SizedBox(
                    height: 1480,
                    width: 430,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: _SeyirSheetFixture(openedAt: openedAt),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> saveShot(WidgetTester tester, String name) async {
    final dir = Platform.environment['SEYIR_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('seyir-shot')),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File('$dir/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  void expectSheetCopy() {
    expect(find.textContaining('Vicdani'), findsWidgets);
    expect(find.text('Davacı'), findsWidgets);
    expect(find.text('Davalı'), findsWidgets);
    expect(find.textContaining('Vicdan'), findsWidgets);
    expect(find.text(absolute), findsWidgets);
    expect(find.text('3 gün önce'), findsWidgets);
    expect(find.byKey(const Key('seyir-drag-handle')), findsOneWidget);
    expect(find.text('Dava Detayları'), findsOneWidget);
    expect(find.text('Dava Konusu'), findsOneWidget);
    expect(find.text('Rol Kararları ve Hükümleri'), findsOneWidget);
    expect(find.text('Deliller Hakkında'), findsOneWidget);
    expect(find.text('Uygun Görülen Cezalar'), findsOneWidget);
    expect(find.text('Ceza Onayı'), findsOneWidget);
    expect(find.text('Uygun Görülen Hediyeler'), findsOneWidget);
    expect(find.text('Hediye Onayı'), findsOneWidget);
    expect(
      find.text('Davayı Yorumlamayı Kabul ve Red Edenler'),
      findsOneWidget,
    );
  }

  testWidgets('seyir sheet light', (tester) async {
    await openSheet(tester, _sheetTheme(Brightness.light));
    expectSheetCopy();
    await saveShot(tester, 'seyir-sheet-light');
  });

  testWidgets('seyir sheet dark', (tester) async {
    await openSheet(tester, _sheetTheme(Brightness.dark));
    expectSheetCopy();
    await saveShot(tester, 'seyir-sheet-dark');
  });
}

class _SeyirSheetFixture extends StatelessWidget {
  const _SeyirSheetFixture({required this.openedAt});

  final DateTime openedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SeyirDragHandle(),
        IlgililerinSeyirDefteriWidgeti(
          davaId: '',
          davaAdi: 'Vicdani Problemler',
          davaci: 'Ayşe Yılmaz',
          davali: 'Mehmet Demir',
          kategori: 'Vicdan',
          davaKonusu:
              'Komşu bahçesindeki ağacın gölgesi yüzünden açılan örnek dava konusu.',
          openedAt: openedAt,
          onClose: () {},
        ),
      ],
    );
  }
}
