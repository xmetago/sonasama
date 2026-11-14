import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/widgets/dava_sayilari_card.dart';
import 'package:its19/widgets/haykir_card_shell.dart';
import 'package:its19/widgets/home_feed_card_shell.dart';
import 'package:its19/widgets/home_page_chrome.dart';

/// Renders the home header and feed with fixture data.
/// When HOME_SHOT_DIR is set, writes `home-after-light.png` and
/// `home-after-dark.png`. Assertions stay valid without that variable.
const _shotFont = 'HomeShot';

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

ThemeData _homeTheme(Brightness brightness) {
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

  final createdAt = DateTime.now().subtract(const Duration(hours: 2));

  Future<void> openHome(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(430, 1680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: RepaintBoundary(
            key: const Key('home-shot'),
            child: HomePageChrome(
              userEmail: null,
              profileEmail: null,
              targetUserEmail: null,
              feed: SingleChildScrollView(
                child: Column(
                  children: [
                    const DavaSayilariCard(
                      katildigim: 12,
                      hakli: 7,
                      haksiz: 3,
                      banaAcilan: 4,
                    ),
                    HaykirCardShell(
                      variant: HaykirCardShellVariant.feed,
                      isExpanded: true,
                      isExpired: false,
                      adi: 'Sokak lambaları',
                      slogan: 'Mahalle karanlıkta kalmasın.',
                      direme: 'Işık hakkı',
                      createdAt: createdAt.toIso8601String(),
                      authorDisplayName: 'Ayşe Yılmaz',
                      authorSubtitle: '2 sa önce yayınlandı',
                      expandedChildren: const [
                        _ShotActionRow(),
                      ],
                    ),
                    DavaWatchFeedCard(
                      name: 'Vicdan davası',
                      timeLabel: '2 saat önce',
                      isWatching: true,
                      stateLabel: 'ON',
                      avatar: const CircleAvatar(radius: 18, child: Text('A')),
                      onClose: () {},
                      onToggle: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> saveShot(WidgetTester tester, String suffix) async {
    final dir = Platform.environment['HOME_SHOT_DIR'];
    if (dir == null || dir.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('home-shot')),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File('$dir/home-after-$suffix.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  void expectHomeCopy() {
    expect(find.text('Seyir Defteri'), findsOneWidget);
    expect(find.text('Dava Sayıları'), findsOneWidget);
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    expect(find.text('Sokak lambaları'), findsOneWidget);
    expect(find.text('Vicdan davası'), findsOneWidget);
    expect(find.text('2 saat önce'), findsWidgets);
    expect(find.text('ON'), findsOneWidget);
    expect(find.text('12'), findsWidgets);
  }

  testWidgets('home page light', (tester) async {
    await openHome(tester, _homeTheme(Brightness.light));
    expectHomeCopy();
    await saveShot(tester, 'light');
  });

  testWidgets('home page dark', (tester) async {
    await openHome(tester, _homeTheme(Brightness.dark));
    expectHomeCopy();
    await saveShot(tester, 'dark');
  });

  testWidgets('feed error, empty and skeleton', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: _homeTheme(Brightness.light),
        home: Scaffold(
          body: ListView(
            children: [
              HomeFeedErrorCard(onRetry: () => retries++),
              const HomeEmptyCases(),
              const HomeFeedSkeletonCard(),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Veriler yüklenirken bir hata oluştu'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Henüz Dava Açmadınız'), findsOneWidget);
    expect(find.text('Açtığınız davalar burada görünecek.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Tekrar dene'));
    expect(retries, 1);
  });

  testWidgets('header collapses when scrolling down and the toggle still works',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _homeTheme(Brightness.light),
        home: Scaffold(
          body: HomePageChrome(
            userEmail: null,
            profileEmail: null,
            targetUserEmail: null,
            feed: ListView(
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 72, child: Text('satır $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Who'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Who'), findsNothing);
    expect(find.text('Seyir Defteri'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pump();
    expect(find.text('Who'), findsOneWidget);

    await tester.tap(find.byTooltip('Arayüzü Kapat'));
    await tester.pump();
    expect(find.text('Who'), findsNothing);

    await tester.tap(find.byTooltip('Arayüzü Aç'));
    await tester.pump();
    expect(find.text('Who'), findsOneWidget);
  });
}

class _ShotActionRow extends StatelessWidget {
  const _ShotActionRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(Icons.chat_bubble_outline, size: 22),
        Icon(Icons.repeat, size: 22),
        Icon(Icons.favorite_border, size: 22),
        Icon(Icons.bookmark_border, size: 22),
      ],
    );
  }
}
