import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/theme/seyir_tokens.dart';
import 'package:its19/widgets/durt_wheel_sheet.dart';

/// Dürtme çarkı: sahte kelimelerle sayfa açılır, çark, işaretçi ve Gönder
/// görünür; bir dilime dokununca o kelime seçilir.
const List<DurtWheelWord> _fakeWords = <DurtWheelWord>[
  DurtWheelWord(kelime: 'İyi', icon: Icons.thumb_up_outlined),
  DurtWheelWord(
    kelime: 'Kötü',
    icon: Icons.thumb_down_outlined,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(kelime: 'Güzel', icon: Icons.favorite_outlined),
  DurtWheelWord(
    kelime: 'Fena',
    icon: Icons.warning_outlined,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Hoş',
    icon: Icons.mood_outlined,
    fontWeight: FontWeight.w500,
  ),
  DurtWheelWord(
    kelime: 'Belki',
    icon: Icons.help_outlined,
    fontWeight: FontWeight.w500,
  ),
];

const List<IconData> _outlineIcons = <IconData>[
  Icons.thumb_up_outlined,
  Icons.thumb_down_outlined,
  Icons.sentiment_very_dissatisfied_outlined,
  Icons.star_outlined,
  Icons.favorite_outlined,
  Icons.warning_outlined,
  Icons.mood_outlined,
  Icons.face_outlined,
  Icons.block_outlined,
  Icons.cancel_outlined,
  Icons.sentiment_dissatisfied_outlined,
  Icons.bolt_outlined,
  Icons.psychology_outlined,
  Icons.close_outlined,
  Icons.help_outlined,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> openSheet(
    WidgetTester tester, {
    required ThemeData theme,
    bool disableAnimations = false,
    Future<void> Function(String kelime)? onSend,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    final MediaQueryData media = MediaQuery.of(context);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (sheetContext) {
                        return MediaQuery(
                          data: media.copyWith(
                            disableAnimations: disableAnimations,
                          ),
                          child: DurtWheelSheet(
                            words: _fakeWords,
                            subtitle: 'Deneme yargıcına hızlı tepki gönder',
                            onSend: onSend ?? (_) async {},
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Aç'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
  }

  String selectedWord(WidgetTester tester) {
    return tester
        .widget<Text>(find.byKey(const Key('durt-selected-word')))
        .data!;
  }

  void expectCalmChrome(
    WidgetTester tester,
    ThemeData theme, {
    required bool settled,
  }) {
    final SeyirPalette palette = SeyirPalette(
      theme.colorScheme,
      theme.brightness,
    );

    final Icon header = tester.widget<Icon>(
      find.byIcon(Icons.touch_app_outlined),
    );
    expect(header.color, palette.textPrimary);

    final Icon slice = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('durt-segment-İyi')),
        matching: find.byType(Icon),
      ),
    );
    expect(slice.icon, Icons.thumb_up_outlined);
    expect(slice.color, palette.textPrimary);

    final Text sliceLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('durt-segment-İyi')),
        matching: find.text('İyi'),
      ),
    );
    expect(sliceLabel.style?.color, palette.textPrimary);

    final AnimatedContainer banner = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.byKey(const Key('durt-selected-word')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final BoxDecoration decoration = banner.decoration! as BoxDecoration;
    expect(decoration.color, palette.surfaceMuted);
    final BorderSide side = (decoration.border! as Border).top;
    expect(side.width, 1);
    expect(side.color, settled ? SeyirTokens.brand : palette.border);

    final FilledButton send = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Gönder'),
    );
    expect(
      send.style?.backgroundColor?.resolve(const <WidgetState>{}),
      SeyirTokens.brand,
    );

    final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('durt-wheel-sheet')),
        matching: find.byType(DecoratedBox),
      ),
    );
    var hubRing = false;
    for (final DecoratedBox box in boxes) {
      final Decoration decoration = box.decoration;
      if (decoration is! BoxDecoration) continue;
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
      if (decoration.shape != BoxShape.circle) continue;
      expect(decoration.color, isNot(SeyirTokens.brand));
      if (decoration.border != null) {
        expect(decoration.border!.top.color, palette.border);
        expect(decoration.border!.top.width, 1);
        hubRing = true;
      }
    }
    expect(hubRing, isTrue);
  }

  testWidgets('çark, işaretçi ve Gönder görünür; dilim seçilir', (
    tester,
  ) async {
    String? sent;
    await openSheet(
      tester,
      theme: WhoBoomTheme.light,
      onSend: (kelime) async {
        sent = kelime;
      },
    );

    expect(find.byKey(const Key('durt-wheel')), findsOneWidget);
    expect(find.byKey(const Key('durt-wheel-pointer')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Gönder'), findsOneWidget);
    expect(find.text('Çevir'), findsOneWidget);
    expect(selectedWord(tester), 'İyi');
    expect(durtmeWheelWords, hasLength(15));
    expect(durtmeWheelWords.map((word) => word.icon).toList(), _outlineIcons);
    expectCalmChrome(tester, WhoBoomTheme.light, settled: true);

    await tester.tap(find.byKey(const Key('durt-segment-Güzel')));
    await tester.pumpAndSettle();

    expect(selectedWord(tester), 'Güzel');

    await tester.tap(find.widgetWithText(FilledButton, 'Gönder'));
    await tester.pump();
    expect(sent, 'Güzel');
  });

  testWidgets('koyu temada çark, işaretçi ve Gönder görünür', (tester) async {
    await openSheet(tester, theme: WhoBoomTheme.dark);
    expect(find.byKey(const Key('durt-wheel')), findsOneWidget);
    expect(find.byKey(const Key('durt-wheel-pointer')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Gönder'), findsOneWidget);
    expect(selectedWord(tester), 'İyi');
    expectCalmChrome(tester, WhoBoomTheme.dark, settled: true);
  });

  testWidgets('dönüşte çerçeve nötr, durunca ince marka', (tester) async {
    await openSheet(tester, theme: WhoBoomTheme.light);
    expectCalmChrome(tester, WhoBoomTheme.light, settled: true);

    await tester.tap(find.text('Çevir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expectCalmChrome(tester, WhoBoomTheme.light, settled: false);

    await tester.pumpAndSettle();
    expectCalmChrome(tester, WhoBoomTheme.light, settled: true);
  });

  testWidgets('azaltılmış hareket dilimi bekletmeden seçer', (tester) async {
    await openSheet(tester, theme: WhoBoomTheme.light, disableAnimations: true);
    expect(selectedWord(tester), 'İyi');

    await tester.tap(find.byKey(const Key('durt-segment-Belki')));
    await tester.pump();

    expect(selectedWord(tester), 'Belki');
  });
}
