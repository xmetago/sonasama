import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/widgets/durt_wheel_sheet.dart';

/// Dürtme çarkı: sahte kelimelerle sayfa açılır, çark, işaretçi ve Gönder
/// görünür; bir dilime dokununca o kelime seçilir.
const List<DurtWheelWord> _fakeWords = <DurtWheelWord>[
  DurtWheelWord(
    kelime: 'İyi',
    icon: Icons.thumb_up,
    color: Colors.green,
  ),
  DurtWheelWord(
    kelime: 'Kötü',
    icon: Icons.thumb_down,
    color: Colors.red,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Güzel',
    icon: Icons.favorite,
    color: Colors.pink,
  ),
  DurtWheelWord(
    kelime: 'Fena',
    icon: Icons.warning,
    color: Colors.orange,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Hoş',
    icon: Icons.mood,
    color: Colors.lightBlue,
    fontWeight: FontWeight.w500,
  ),
  DurtWheelWord(
    kelime: 'Belki',
    icon: Icons.help_outline,
    color: Colors.teal,
    fontWeight: FontWeight.w500,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
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

  testWidgets('çark, işaretçi ve Gönder görünür; dilim seçilir',
      (tester) async {
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
  });

  testWidgets('azaltılmış hareket dilimi bekletmeden seçer', (tester) async {
    await openSheet(
      tester,
      theme: WhoBoomTheme.light,
      disableAnimations: true,
    );
    expect(selectedWord(tester), 'İyi');

    await tester.tap(find.byKey(const Key('durt-segment-Belki')));
    await tester.pump();

    expect(selectedWord(tester), 'Belki');
  });
}
