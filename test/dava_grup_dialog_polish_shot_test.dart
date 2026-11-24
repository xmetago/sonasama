import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/friendship_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/widgets/dava_gonderilecek_grup_dialog.dart';

const _email = 'ayse.demir@example.com';
const _openerId = 'shot-ayse';
const _hiveDir = '/tmp/dava-grup-dialog-hive';
const _pixel = 'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory(_hiveDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => _hiveDir,
    );
    await HiveDatabaseService.initialize();

    await _user(id: _openerId, name: 'Ayşe Demir', email: _email);

    await _user(
      id: 'g1',
      name: 'Grup Bir',
      email: 'testyargic1@gmail.com',
    );
    await _user(
      id: 'g2',
      name: 'Grup İki',
      email: 'testyargic2@gmail.com',
    );

    const friends = <(String, String)>[
      ('f1', 'Ali Yılmaz'),
      ('f2', 'Berk Demir'),
      ('f3', 'Cem Kaya'),
      ('f4', 'Deniz Aksoy'),
      ('f5', 'Ece Koç'),
      ('f6', 'Fatma Şen'),
      ('f7', 'Gül Arslan'),
      ('f8', 'Hakan Polat'),
    ];
    for (final friend in friends) {
      final email = '${friend.$1}@example.com';
      await _user(
        id: friend.$1,
        name: friend.$2,
        email: email,
        image: friend.$1 == 'f4' ? _pixel : null,
      );
      await HiveDatabaseService.sendFriendshipRequest(
        FriendshipModel(
          id: 'friend-${friend.$1}',
          requesterId: _openerId,
          recipientId: friend.$1,
          status: FriendshipStatus.accepted,
          createdAt: DateTime(2024, 2, 1),
        ),
      );
    }

    for (var i = 1; i <= 3; i++) {
      final id = 't$i';
      await _user(
        id: id,
        name: 'Takipçi $i',
        email: '$id@example.com',
      );
      await HiveDatabaseService.sendFriendshipRequest(
        FriendshipModel(
          id: 'follow-$id',
          requesterId: id,
          recipientId: _openerId,
          status: FriendshipStatus.following,
          createdAt: DateTime(2024, 3, 1),
        ),
      );
    }

    for (var i = 1; i <= 4; i++) {
      await _user(
        id: 's$i',
        name: 'Yabancı $i',
        email: 's$i@example.com',
      );
    }
  });

  testWidgets('dört kart sayıları, seçim, özet ve eksik havuz uyarısı',
      (tester) async {
    await _pumpDialog(tester);

    expect(find.text('Grup-19'), findsOneWidget);
    expect(find.text('Arkadaşlar'), findsOneWidget);
    expect(find.text('Takipçiler'), findsOneWidget);
    expect(find.text('Tanımadıklarım'), findsOneWidget);
    expect(find.text('Grup-19’dan 7 üye seç'), findsOneWidget);
    expect(find.text('Arkadaşlardan 7 üye seç'), findsOneWidget);
    expect(find.text('Takipçilerden 7 üye seç'), findsOneWidget);
    expect(find.text('Tanımadıklarından 7 üye seç'), findsOneWidget);
    expect(find.text('2 kişi'), findsOneWidget);
    expect(find.text('8 kişi'), findsOneWidget);
    expect(find.text('3 kişi'), findsOneWidget);
    expect(find.text('6 kişi'), findsOneWidget);
    expect(find.text('DAVA ATA'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const Key('dava-grup-Grup19')),
        matching: find.textContaining('Bu grupta yeterli kişi yok'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('dava-grup-Arkadaşlar')),
        matching: find.textContaining('Bu grupta yeterli kişi yok'),
      ),
      findsNothing,
    );
    expect(
      find.textContaining('Eksik yerler rastgele doldurulur.'),
      findsWidgets,
    );

    await tester.tap(find.byKey(const Key('dava-grup-Arkadaşlar')));
    await tester.pumpAndSettle();

    expect(find.text('Arkadaşlar’a ata'), findsOneWidget);
    expect(
      find.text('7 yargıç + sen + davalı, toplam 9 kişi alacak'),
      findsOneWidget,
    );
    expect(find.text('AY'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dava-grup-Takipçiler')));
    await tester.pumpAndSettle();

    expect(find.text('Takipçiler’e ata'), findsOneWidget);
    expect(
      find.text('3 yargıç + sen + davalı, toplam 5 kişi alacak'),
      findsOneWidget,
    );
    expect(find.text('7 yargıç + sen + davalı, toplam 9 kişi alacak'), findsNothing);

    await tester.tap(find.byKey(const Key('dava-grup-Grup19')));
    await tester.pumpAndSettle();

    expect(find.text('Grup-19’a ata'), findsOneWidget);
    expect(
      find.text('7 yargıç + sen + davalı, toplam 9 kişi alacak'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('dava-grup-Grup19')),
        matching: find.textContaining('Eksik yerler rastgele doldurulur.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('koyu tema ve dar ekranda seçim taşmadan güncellenir',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDialog(tester, theme: WhoBoomTheme.dark);
    final card = find.byKey(const Key('dava-grup-Tanımadıklarım'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Tanımadıklarım’a ata'), findsOneWidget);
    expect(
      find.text('6 yargıç + sen + davalı, toplam 8 kişi alacak'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('animasyon kapalıyken seçim yine güncellenir', (tester) async {
    await _pumpDialog(tester, disableAnimations: true);
    await tester.tap(find.byKey(const Key('dava-grup-Arkadaşlar')));
    await tester.pump();

    expect(find.text('Arkadaşlar’a ata'), findsOneWidget);
    expect(
      find.text('7 yargıç + sen + davalı, toplam 9 kişi alacak'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  ThemeData? theme,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? WhoBoomTheme.light,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(disableAnimations: disableAnimations),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const DavaGonderilecekGrupDialog(
        openerEmail: _email,
        defendant: 'Rakip Yargıç',
        onConfirm: _noop,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop(String _) {}

Future<void> _user({
  required String id,
  required String name,
  required String email,
  String? image,
}) {
  return HiveDatabaseService.addRegistration(
    RegistrationModel(
      id: id,
      judgeName: name,
      email: email,
      password: 'shot',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime(2024, 1, 1),
      lastLoginAt: DateTime(2024, 6, 1),
      profileImage: image,
    ),
  );
}
