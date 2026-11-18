import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:its19/models/friend_category_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:its19/screens/friendship_management_page.dart';
import 'package:its19/services/friend_category_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/services/user_session_service.dart';
import 'package:its19/theme/app_theme.dart';
import 'package:its19/utils/proximity_category_rules.dart';
import 'package:provider/provider.dart';

RegistrationModel _user({
  required String id,
  required String name,
  required String email,
}) {
  return RegistrationModel(
    id: id,
    judgeName: name,
    email: email,
    password: 'test',
    country: 'Türkiye',
    oath: true,
    createdAt: DateTime(2024, 1, 1),
    lastLoginAt: DateTime(2024, 6, 1),
  );
}

Future<void> _register(RegistrationModel user) async {
  if (HiveDatabaseService.getRegistrationByEmail(user.email) != null) return;
  await HiveDatabaseService.addRegistration(user);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final hiveDir = Directory('/tmp/takipci-merge-hive');
    if (hiveDir.existsSync()) hiveDir.deleteSync(recursive: true);
    hiveDir.createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => hiveDir.path,
    );
    await HiveDatabaseService.initialize();
    await FriendCategoryService.initialize();
  });

  test('Takipçi 114 kayıttan sonra da eklenir, Herkes Takipçi olur', () async {
    expect(ProximityCategoryRules.normalize('Herkes'), 'Takipçi');
    expect(ProximityCategoryRules.normalize('herkes'), 'Takipçi');
    expect(ProximityCategoryRules.normalize('Tanımadıklarım'), 'Takipçi');
    expect(ProximityCategoryRules.normalize('Tanimadiklarim'), 'Takipçi');
    expect(ProximityCategoryRules.limitFor('Takipçi'), lessThan(0));
    expect(ProximityCategoryRules.limitFor('Herkes'), lessThan(0));
    expect(ProximityCategoryRules.isUnlimited('Takipçi'), isTrue);
    expect(ProximityCategoryRules.limitFor('Grup-19'), 19);
    expect(ProximityCategoryRules.limitFor('Arkadaş'), 114);
    expect(ProximityCategoryRules.countsAsTakipci('Herkes'), isTrue);
    expect(ProximityCategoryRules.countsAsTakipci('Tanımadıklarım'), isTrue);
    expect(ProximityCategoryRules.countsAsTakipci('Arkadaş'), isFalse);
    expect(ProximityCategoryRules.countsAsTakipci('Grup-19'), isFalse);
    expect(ProximityCategoryRules.displayCategories, isNot(contains('Herkes')));

    const ownerId = 'limit-owner';
    for (var i = 0; i < 114; i++) {
      await FriendCategoryService.upsert(FriendCategoryModel(
        id: '${ownerId}_lim-$i',
        ownerUserId: ownerId,
        targetUserId: 'lim-$i',
        category: 'Takipçi',
        createdAt: DateTime(2024, 1, 1),
      ));
    }
    final added = await FriendCategoryService.assignCategory(
      ownerUserId: ownerId,
      targetUserId: 'lim-extra',
      category: 'Herkes',
    );
    expect(added.success, isTrue);
    expect(
      FriendCategoryService.getByOwnerAndTarget(ownerId, 'lim-extra')?.category,
      'Takipçi',
    );
    expect(
      FriendCategoryService.countInCategory(ownerId, 'Takipçi'),
      greaterThan(114),
    );

    final retired = FriendCategoryModel(
      id: '${ownerId}_tanimadik',
      ownerUserId: ownerId,
      targetUserId: 'tanimadik',
      category: 'Tanımadıklarım',
      createdAt: DateTime(2024, 2, 1),
    );
    await Hive.box<FriendCategoryModel>('friend_category_box').put(retired.id, retired);
    await FriendCategoryService.migrateHerkesToTakipci();
    expect(
      FriendCategoryService.getByOwnerAndTarget(ownerId, 'tanimadik')?.category,
      'Takipçi',
    );
    expect(
      FriendCategoryService.listByOwnerAndCategory(ownerId, 'Herkes').length,
      greaterThan(114),
    );
  });

  testWidgets('Herkes sekmesi yok, kayıt Takipçi altında ve kota engeli yok', (tester) async {
    final owner = _user(
      id: 'ui-owner',
      name: 'Ayşe Demir',
      email: 'ui-owner@example.com',
    );
    final eski = _user(
      id: 'ui-eski',
      name: 'Eski Herkes',
      email: 'ui-eski@example.com',
    );
    final yeni = _user(
      id: 'ui-yeni',
      name: 'Yeni Kişi',
      email: 'ui-yeni@example.com',
    );
    await tester.runAsync(() async {
      await _register(owner);
      await _register(eski);
      await _register(yeni);

      final categoryBox = Hive.box<FriendCategoryModel>('friend_category_box');
      await categoryBox.put(
        '${owner.id}_${eski.id}',
        FriendCategoryModel(
          id: '${owner.id}_${eski.id}',
          ownerUserId: owner.id,
          targetUserId: eski.id,
          category: 'Herkes',
          createdAt: DateTime(2024, 3, 1),
        ),
      );
      for (var i = 0; i < 114; i++) {
        await FriendCategoryService.upsert(FriendCategoryModel(
          id: '${owner.id}_ui-kisi-$i',
          ownerUserId: owner.id,
          targetUserId: 'ui-kisi-$i',
          category: 'Takipçi',
          createdAt: DateTime(2024, 3, 2),
        ));
      }
    });

    UserSessionService.setCurrentUser(owner);
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DavaProvider(),
        child: MaterialApp(
          theme: WhoBoomTheme.light,
          home: FriendshipManagementPage(userEmail: owner.email),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Herkes'), findsNothing);
    expect(find.text('Yeni Kişi'), findsOneWidget);
    expect(find.text('0/19'), findsOneWidget);
    expect(find.text('0/38'), findsOneWidget);
    expect(find.text('115'), findsOneWidget);
    expect(find.textContaining('/114'), findsNothing);
    expect(find.textContaining('6346'), findsNothing);
    expect(find.textContaining('dolu'), findsNothing);
    expect(
      FriendCategoryService.getByOwnerAndTarget(owner.id, eski.id)?.category,
      'Takipçi',
    );

    await tester.ensureVisible(find.text('Takipçi').last);
    await tester.tap(find.text('Takipçi').last);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.textContaining('dolu'), findsNothing);
    expect(find.textContaining('/114'), findsNothing);
    expect(find.text('116'), findsOneWidget);
    expect(
      FriendCategoryService.getByOwnerAndTarget(owner.id, yeni.id)?.category,
      'Takipçi',
    );

    await tester.tap(find.text('Takipçi').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Herkes'), findsNothing);
    expect(find.text('Eski Herkes'), findsOneWidget);
    expect(find.text('Takipçi'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 6));
  });

  test('eski Herkes kaydı Takipçiler davetine girer', () async {
    final owner = _user(
      id: 'davet-owner',
      name: 'Davet Sahibi',
      email: 'davet-owner@example.com',
    );
    final follower = _user(
      id: 'davet-follower',
      name: 'Eski Herkes Davet',
      email: 'davet-follower@example.com',
    );
    final stranger = _user(
      id: 'davet-stranger',
      name: 'Eski Tanıdık',
      email: 'davet-stranger@example.com',
    );
    await _register(owner);
    await _register(follower);
    await _register(stranger);
    await Hive.box('friend_group_box').put(owner.email, <String, String>{
      follower.email: 'Herkes',
      stranger.email: 'Tanımadıklarım',
    });

    expect(
      HiveDatabaseService.getFriendCategory(
        ownerEmail: owner.email,
        friendEmail: follower.email,
      ),
      'Takipçi',
    );
    expect(
      HiveDatabaseService.getFriendCategory(
        ownerEmail: owner.email,
        friendEmail: stranger.email,
      ),
      'Takipçi',
    );

    final recipients = await HiveDatabaseService.pickInvitationRecipients(
      owner.email,
      'Takipçiler',
      excludedEmails: const <String>[],
    );
    final emails = recipients.map((user) => user.email).toSet();
    expect(emails, contains(follower.email));
    expect(emails, contains(stranger.email));

    final global = await HiveDatabaseService.pickInvitationRecipients(
      owner.email,
      'Herkes',
      excludedEmails: const <String>[],
    );
    expect(global, isNotEmpty);

    await HiveDatabaseService.migrateRetiredHerkesCategories();
    final stored = Map<String, String>.from(
      (Hive.box('friend_group_box').get(owner.email) as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
    expect(stored[follower.email], 'Takipçi');
    expect(stored[stranger.email], 'Takipçi');
  }, timeout: const Timeout(Duration(seconds: 20)));
}
