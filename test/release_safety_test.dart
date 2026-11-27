import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:its19/models/evidence_model.dart';
import 'package:its19/models/friend_category_model.dart';
import 'package:its19/models/friendship_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/models/settings_model.dart';
import 'package:its19/services/account_deletion_service.dart';
import 'package:its19/services/friend_category_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/services/star_purchase_credit.dart';
import 'package:its19/utils/debug_seed_gate.dart';

RegistrationModel _user({
  required String id,
  required String email,
  required String name,
}) {
  return RegistrationModel(
    id: id,
    judgeName: name,
    email: email,
    password: 'secret',
    country: 'Türkiye',
    oath: true,
    createdAt: DateTime.utc(2024, 1, 1),
    lastLoginAt: DateTime.utc(2024, 6, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final hiveDir = Directory('/tmp/release-safety-hive');
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

  setUp(() async {
    await HiveDatabaseService.clearAllData();
  });

  test('release derlemesinde test hesapları eklenmez', () {
    expect(shouldSeedDebugData(debugMode: false), isFalse);
    expect(shouldSeedDebugData(debugMode: true), isTrue);
  });

  test('başarısız veya yinelenen satın alma yıldız yazmaz', () {
    final credited = <String>{};

    StarCreditDecision failed(PurchaseStatus status) {
      return decideStarCredit(
        status: status,
        currentBalance: 10,
        starAmount: 50,
        purchaseId: 'order-1',
        alreadyCreditedIds: credited,
      );
    }

    expect(failed(PurchaseStatus.canceled).credit, isFalse);
    expect(failed(PurchaseStatus.error).credit, isFalse);
    expect(failed(PurchaseStatus.pending).credit, isFalse);
    expect(failed(PurchaseStatus.canceled).balance, 10);
    expect(credited, isEmpty);

    final first = decideStarCredit(
      status: PurchaseStatus.purchased,
      currentBalance: 10,
      starAmount: 50,
      purchaseId: 'order-1',
      alreadyCreditedIds: credited,
    );
    expect(first.credit, isTrue);
    expect(first.balance, 60);

    final duplicate = decideStarCredit(
      status: PurchaseStatus.purchased,
      currentBalance: first.balance,
      starAmount: 50,
      purchaseId: 'order-1',
      alreadyCreditedIds: credited,
    );
    expect(duplicate.credit, isFalse);
    expect(duplicate.balance, 60);
  });

  test('kayıt önbelleği ekleme, güncelleme ve silme ile güncel kalır', () async {
    final user = _user(
      id: 'cache-user',
      email: 'cache@example.com',
      name: 'Önbellek',
    );
    await HiveDatabaseService.addRegistration(user);
    expect(
      HiveDatabaseService.getRegistrationByEmail(user.email)?.judgeName,
      'Önbellek',
    );

    final updated = user.copyWith(
      email: 'cache-new@example.com',
      judgeName: 'Güncel',
    );
    await HiveDatabaseService.updateRegistration(updated);
    expect(HiveDatabaseService.getRegistrationByEmail(user.email), isNull);
    expect(
      HiveDatabaseService.getRegistrationByEmail(updated.email)?.judgeName,
      'Güncel',
    );

    await HiveDatabaseService.deleteRegistration(user.id);
    expect(HiveDatabaseService.getRegistrationByEmail(updated.email), isNull);
  });

  test('hesap silme kullanıcının Hive verisini kaldırır', () async {
    final user = _user(
      id: 'delete-user',
      email: 'silinecek@example.com',
      name: 'Silinecek Yargıç',
    );
    final other = _user(
      id: 'keep-user',
      email: 'kalacak@example.com',
      name: 'Kalacak Yargıç',
    );
    await HiveDatabaseService.addRegistration(user);
    await HiveDatabaseService.addRegistration(other);
    await HiveDatabaseService.saveSettings(SettingsModel(userEmail: user.email));
    await HiveDatabaseService.saveSettings(SettingsModel(userEmail: other.email));
    HiveDatabaseService.saveOpenedDava(<String, dynamic>{
      'id': 'owned-dava',
      'userEmail': user.email,
      'davaci': user.judgeName,
      'openedAt': DateTime.utc(2024, 1, 1).toIso8601String(),
      'davaAdi': 'Benim davam',
    });
    HiveDatabaseService.saveOpenedDava(<String, dynamic>{
      'id': 'other-dava',
      'userEmail': other.email,
      'davaci': other.judgeName,
      'openedAt': DateTime.utc(2024, 1, 2).toIso8601String(),
      'davaAdi': 'Başkasının davası',
    });
    await Hive.box<EvidenceModel>('evidence_box').put(
      'ev-owned',
      EvidenceModel(
        id: 'ev-owned',
        davaId: 'owned-dava',
        type: 'text',
        title: 'Delil',
        description: 'Açıklama',
        createdAt: DateTime.utc(2024, 1, 1),
        userId: user.id,
      ),
    );
    await Hive.box<EvidenceModel>('evidence_box').put(
      'ev-other',
      EvidenceModel(
        id: 'ev-other',
        davaId: 'other-dava',
        type: 'text',
        title: 'Diğer delil',
        description: 'Açıklama',
        createdAt: DateTime.utc(2024, 1, 2),
        userId: other.id,
      ),
    );
    await HiveDatabaseService.sendFriendshipRequest(
      FriendshipModel(
        id: 'friend-owned',
        requesterId: user.id,
        recipientId: other.id,
        status: FriendshipStatus.accepted,
        createdAt: DateTime.utc(2024, 1, 1),
      ),
    );
    await HiveDatabaseService.sendFriendshipRequest(
      FriendshipModel(
        id: 'friend-other',
        requesterId: 'stranger',
        recipientId: 'another',
        status: FriendshipStatus.pending,
        createdAt: DateTime.utc(2024, 1, 2),
      ),
    );
    await FriendCategoryService.upsert(
      FriendCategoryModel(
        id: 'cat-owned',
        ownerUserId: user.id,
        targetUserId: other.id,
        category: 'Takipçi',
        createdAt: DateTime.utc(2024, 1, 1),
      ),
    );

    await AccountDeletionService.deleteHiveData(
      userId: user.id,
      email: user.email,
    );

    expect(HiveDatabaseService.getRegistrationByEmail(user.email), isNull);
    expect(HiveDatabaseService.getRegistrationByEmail(other.email)?.id, other.id);
    expect(HiveDatabaseService.getSettings(user.email), isNull);
    expect(HiveDatabaseService.getSettings(other.email), isNotNull);
    final opened = HiveDatabaseService.getOpenedDavalar();
    expect(opened.any((dava) => dava['id'] == 'owned-dava'), isFalse);
    expect(opened.any((dava) => dava['id'] == 'other-dava'), isTrue);
    final evidence = Hive.box<EvidenceModel>('evidence_box');
    expect(evidence.get('ev-owned'), isNull);
    expect(evidence.get('ev-other'), isNotNull);
    expect(HiveDatabaseService.getFriendship('friend-owned'), isNull);
    expect(HiveDatabaseService.getFriendship('friend-other'), isNotNull);
    expect(FriendCategoryService.listByOwner(user.id), isEmpty);
  });
}
