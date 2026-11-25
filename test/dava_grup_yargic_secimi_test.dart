import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:its19/models/friendship_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/services/hive_database_service.dart';

const _hiveDir = '/tmp/dava-grup-yargic-hive';

const _grup19Emails = <String>[
  'testyargic1@gmail.com',
  'testyargic2@gmail.com',
  'testyargic5@gmail.com',
  'testyargic8@gmail.com',
  'testyargic9@gmail.com',
  'testyargic10@gmail.com',
  'testyargic11@gmail.com',
];

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
  });

  setUp(() async {
    await HiveDatabaseService.clearAllData();
  });

  test('her grup kendi havuzundan 7 yargıç seçer', () async {
    for (final group in const [
      'Grup19',
      'Grup-19',
      'Arkadaşlar',
      'arkadaslar',
      'Takipçiler',
      'takipciler',
      'Tanımadıklarım',
      'tanimadiklarim',
    ]) {
      await HiveDatabaseService.clearAllData();
      final world = await _seedFullPool(group);
      final judges = await HiveDatabaseService.pickGroupRecipients(
        world.opener.email,
        group,
        count: 7,
        defendantEmail: world.defendant.judgeName,
        sameCountryOnly: true,
      );
      final emails = judges.map((judge) => judge.email).toSet();

      expect(emails, hasLength(7), reason: group);
      expect(emails, isNot(contains(world.opener.email)), reason: group);
      expect(emails, isNot(contains(world.defendant.email)), reason: group);
      expect(
        emails.every(world.pool.contains),
        isTrue,
        reason: '$group yargıçları kendi havuzundan seçilmeli',
      );
      expect(
        emails.intersection(world.outside),
        isEmpty,
        reason: group,
      );

      final byEmail = await HiveDatabaseService.pickGroupRecipients(
        world.opener.email,
        group,
        count: 7,
        defendantEmail: world.defendant.email,
        sameCountryOnly: true,
      );
      expect(
        byEmail.map((judge) => judge.email),
        isNot(contains(world.defendant.email)),
        reason: group,
      );

      final inbox = HiveDatabaseService.hukumInboxEmails(
        judgeEmails: emails,
        openerEmail: world.opener.email,
        defendant: world.defendant.judgeName,
      );
      expect(inbox, hasLength(9), reason: group);
      expect(inbox, containsAll(emails));
      expect(inbox, contains(world.opener.email));
      expect(inbox, contains(world.defendant.email));

      final davaId = 'dava-hukum-$group';
      for (final email in inbox) {
        HiveDatabaseService.addIncomingDava(email, {
          'id': davaId,
          'adi': 'Hüküm',
          'davali': world.defendant.judgeName,
          'davaliEmail': world.defendant.email,
        });
      }
      for (final email in inbox.where((email) => email != world.opener.email)) {
        final incoming = HiveDatabaseService.getIncomingDavalar(email);
        expect(
          incoming.any((dava) => dava['id'] == davaId),
          isTrue,
          reason: '$group gelen dava $email',
        );
      }
    }
  });

  test('farklı ülkedeki grup üyeleri de 7 yargıca girer', () async {
    final opener = await _user(
      id: 'opener',
      name: 'Davacı',
      email: 'opener@example.com',
      country: 'Türkiye',
    );
    final defendant = await _user(
      id: 'davali',
      name: 'Davalı Yargıç',
      email: 'davali@example.com',
      country: 'Türkiye',
    );
    final friends = <String>{};
    for (var i = 0; i < 8; i++) {
      final email = 'friend-$i@example.com';
      friends.add(email);
      await _user(
        id: 'friend-$i',
        name: 'Arkadaş $i',
        email: email,
        country: i < 3 ? 'Türkiye' : 'Almanya',
      );
      await _accept(opener.id, 'friend-$i');
    }
    await _accept(opener.id, defendant.id);

    final judges = await HiveDatabaseService.pickGroupRecipients(
      opener.email,
      'Arkadaşlar',
      defendantEmail: defendant.judgeName,
      sameCountryOnly: true,
    );
    final emails = judges.map((judge) => judge.email).toSet();
    expect(emails, hasLength(7));
    expect(emails.every(friends.contains), isTrue);
    expect(emails, isNot(contains(defendant.email)));
    expect(
      emails.where((email) => !email.startsWith('friend-0') &&
          !email.startsWith('friend-1') &&
          !email.startsWith('friend-2')),
      isNotEmpty,
    );
  });

  test('havuz 7den kısaysa eksik yargıçlar Grup-19 zinciriyle tamamlanır', () async {
    final opener = await _user(
      id: 'opener',
      name: 'Davacı',
      email: 'opener@example.com',
    );
    final defendant = await _user(
      id: 'davali',
      name: 'Davalı Yargıç',
      email: 'davali@example.com',
    );
    final friends = <String>{};
    for (var i = 0; i < 3; i++) {
      friends.add('friend-$i@example.com');
      await _user(
        id: 'friend-$i',
        name: 'Arkadaş $i',
        email: 'friend-$i@example.com',
      );
      await _accept(opener.id, 'friend-$i');
    }
    final strangers = <String>{};
    for (var i = 0; i < 6; i++) {
      strangers.add('stranger-$i@example.com');
      await _user(
        id: 'stranger-$i',
        name: 'Yabancı $i',
        email: 'stranger-$i@example.com',
        country: 'Almanya',
      );
    }

    final judges = await HiveDatabaseService.pickGroupRecipients(
      opener.email,
      'Arkadaşlar',
      defendantEmail: 'Davalı Yargıç',
      sameCountryOnly: true,
    );
    final emails = judges.map((judge) => judge.email).toSet();
    expect(emails, hasLength(7));
    expect(emails, containsAll(friends));
    expect(emails, isNot(contains(opener.email)));
    expect(emails, isNot(contains(defendant.email)));
    expect(emails.difference(friends), hasLength(4));
    expect(emails.difference(friends).every(strangers.contains), isTrue);
  });

  test('uygun kişi 7den azsa mevcut düşük kadro korunur', () async {
    final opener = await _user(
      id: 'opener',
      name: 'Davacı',
      email: 'opener@example.com',
    );
    final defendant = await _user(
      id: 'davali',
      name: 'Davalı Yargıç',
      email: 'davali@example.com',
    );
    await _user(id: 'friend-0', name: 'Arkadaş 0', email: 'friend-0@example.com');
    await _user(id: 'friend-1', name: 'Arkadaş 1', email: 'friend-1@example.com');
    await _accept(opener.id, 'friend-0');
    await _accept(opener.id, 'friend-1');
    await _accept(opener.id, defendant.id);

    final judges = await HiveDatabaseService.pickGroupRecipients(
      opener.email,
      'Arkadaşlar',
      defendantEmail: defendant.email,
    );
    final emails = judges.map((judge) => judge.email).toSet();
    expect(emails, {'friend-0@example.com', 'friend-1@example.com'});

    final inbox = HiveDatabaseService.hukumInboxEmails(
      judgeEmails: emails,
      openerEmail: opener.email,
      defendant: defendant.judgeName,
    );
    expect(inbox, hasLength(4));
    expect(inbox, contains(defendant.email));
    expect(inbox, contains(opener.email));
  });

  test('dava ve 7-yargıç gizliliği kapalı olanlar yargıç olamaz', () async {
    final opener = await _user(
      id: 'opener',
      name: 'Davacı',
      email: 'opener@example.com',
    );
    final defendant = await _user(
      id: 'davali',
      name: 'Davalı Yargıç',
      email: 'davali@example.com',
    );
    final eligibleFriends = <String>{};
    for (var i = 0; i < 8; i++) {
      final email = 'friend-$i@example.com';
      await _user(id: 'friend-$i', name: 'Arkadaş $i', email: email);
      await _accept(opener.id, 'friend-$i');
      if (i == 0) {
        await HiveDatabaseService.updatePrivacySetting(
          email,
          'genel_davaacilsin',
          false,
        );
      } else if (i == 1) {
        await HiveDatabaseService.updatePrivacySetting(
          email,
          'davet_7yargic',
          false,
        );
      } else {
        eligibleFriends.add(email);
      }
    }
    for (var i = 0; i < 3; i++) {
      await _user(
        id: 'stranger-$i',
        name: 'Yabancı $i',
        email: 'stranger-$i@example.com',
      );
    }

    final friendJudges = await HiveDatabaseService.pickGroupRecipients(
      opener.email,
      'Arkadaşlar',
      defendantEmail: defendant.judgeName,
    );
    final emails = friendJudges.map((judge) => judge.email).toSet();
    expect(emails, hasLength(7));
    expect(emails, containsAll(eligibleFriends));
    expect(emails, isNot(contains('friend-0@example.com')));
    expect(emails, isNot(contains('friend-1@example.com')));
    expect(emails, isNot(contains(defendant.email)));
  });
}

class _World {
  const _World({
    required this.opener,
    required this.defendant,
    required this.pool,
    required this.outside,
  });

  final RegistrationModel opener;
  final RegistrationModel defendant;
  final Set<String> pool;
  final Set<String> outside;
}

Future<_World> _seedFullPool(String group) async {
  final normalized = group.toLowerCase().replaceAll('-', '').trim();
  final opener = await _user(
    id: 'opener',
    name: 'Davacı',
    email: 'opener@example.com',
  );
  final defendant = await _user(
    id: 'davali',
    name: 'Davalı Yargıç',
    email: 'davali@example.com',
  );
  final pool = <String>{};
  final outside = <String>{};

  if (normalized == 'grup19') {
    for (var i = 0; i < _grup19Emails.length; i++) {
      final email = _grup19Emails[i];
      pool.add(email);
      await _user(id: 'g$i', name: 'Grup $i', email: email);
    }
    for (var i = 0; i < 4; i++) {
      final email = 'outsider-$i@example.com';
      outside.add(email);
      await _user(id: 'out-$i', name: 'Dışarı $i', email: email);
      await _accept(opener.id, 'out-$i');
    }
    return _World(
      opener: opener,
      defendant: defendant,
      pool: pool,
      outside: outside,
    );
  }

  Future<void> addPeople({
    required String prefix,
    required int count,
    required Future<void> Function(String id) relate,
    required Set<String> target,
  }) async {
    for (var i = 0; i < count; i++) {
      final id = '$prefix-$i';
      final email = '$id@example.com';
      target.add(email);
      await _user(id: id, name: '$prefix $i', email: email);
      await relate(id);
    }
  }

  if (normalized == 'arkadaşlar' || normalized == 'arkadaslar') {
    await addPeople(
      prefix: 'friend',
      count: 8,
      relate: (id) => _accept(opener.id, id),
      target: pool,
    );
    await _accept(opener.id, defendant.id);
    await addPeople(
      prefix: 'outsider',
      count: 4,
      relate: (id) => _follow(id, opener.id),
      target: outside,
    );
  } else if (normalized == 'takipçiler' || normalized == 'takipciler') {
    await addPeople(
      prefix: 'follower',
      count: 8,
      relate: (id) => _follow(id, opener.id),
      target: pool,
    );
    await _follow(defendant.id, opener.id);
    await addPeople(
      prefix: 'outsider',
      count: 4,
      relate: (id) => _accept(opener.id, id),
      target: outside,
    );
  } else {
    await addPeople(
      prefix: 'stranger',
      count: 8,
      relate: (_) async {},
      target: pool,
    );
    await addPeople(
      prefix: 'friend',
      count: 3,
      relate: (id) => _accept(opener.id, id),
      target: outside,
    );
    await addPeople(
      prefix: 'follower',
      count: 2,
      relate: (id) => _follow(id, opener.id),
      target: outside,
    );
  }

  return _World(
    opener: opener,
    defendant: defendant,
    pool: pool,
    outside: outside,
  );
}

Future<RegistrationModel> _user({
  required String id,
  required String name,
  required String email,
  String country = 'Türkiye',
}) async {
  final user = RegistrationModel(
    id: id,
    judgeName: name,
    email: email,
    password: 'test',
    country: country,
    oath: true,
    createdAt: DateTime(2024, 1, 1),
    lastLoginAt: DateTime(2024, 6, 1),
  );
  await HiveDatabaseService.addRegistration(user);
  return user;
}

Future<void> _accept(String openerId, String otherId) {
  return HiveDatabaseService.sendFriendshipRequest(
    FriendshipModel(
      id: 'friend-$openerId-$otherId',
      requesterId: openerId,
      recipientId: otherId,
      status: FriendshipStatus.accepted,
      createdAt: DateTime(2024, 2, 1),
    ),
  );
}

Future<void> _follow(String followerId, String openerId) {
  return HiveDatabaseService.sendFriendshipRequest(
    FriendshipModel(
      id: 'follow-$followerId-$openerId',
      requesterId: followerId,
      recipientId: openerId,
      status: FriendshipStatus.following,
      createdAt: DateTime(2024, 3, 1),
    ),
  );
}
