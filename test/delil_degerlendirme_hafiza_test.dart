import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:its19/models/evidence_model.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/screens/delil_detay_page.dart';
import 'package:its19/services/evidence_service.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/widgets/evidence_viewer_widget.dart';

const _email = 'ada@example.com';
const _other = 'berk@example.com';

Finder _selectedVote(String label) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Semantics) return false;
    return widget.properties.selected == true && widget.properties.label == label;
  });
}

Finder _voteInCard(String title, String label, {required bool selected}) {
  final card = find.ancestor(
    of: find.text(title),
    matching: find.byType(Card),
  );
  return find.descendant(
    of: card,
    matching: find.byWidgetPredicate((widget) {
      if (widget is! Semantics) return false;
      return widget.properties.label == label &&
          widget.properties.selected == selected;
    }),
  );
}

Future<void> _pump(WidgetTester tester, [Duration step = const Duration(milliseconds: 400)]) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
  await tester.pump();
  await tester.pump(step);
}

Future<void> _untilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await _pump(tester, const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<EvidenceModel> _addEvidence({
  required String davaId,
  required String title,
}) async {
  final result = await EvidenceService().addEvidence(
    EvidenceModel(
      id: 'gecici',
      davaId: davaId,
      type: 'image',
      title: title,
      description: 'Kayit testi icin aciklama',
      createdAt: DateTime(2026, 11, 2),
      userId: _email,
    ),
  );
  expect(result['isValid'], isTrue, reason: '${result['error']}');
  return result['evidence'] as EvidenceModel;
}

EvidenceModel _staleCopy(EvidenceModel saved) {
  return EvidenceModel(
    id: saved.id,
    davaId: saved.davaId,
    type: saved.type,
    title: saved.title,
    description: saved.description,
    createdAt: saved.createdAt,
    userId: saved.userId,
  );
}

late EvidenceModel _detaySaved;
late EvidenceModel _detayOther;
late EvidenceModel _listeFirst;
late EvidenceModel _listeSecond;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EvidenceService service;

  setUpAll(() async {
    final hiveDir = Directory('/tmp/delil-degerlendirme-hive');
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
    hiveDir.createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => '/tmp/delil-degerlendirme-hive',
    );
    await HiveDatabaseService.initialize();
    service = EvidenceService();
    await service.initialize();
    if (HiveDatabaseService.getRegistrationByEmail(_email) == null) {
      await HiveDatabaseService.addRegistration(
        RegistrationModel(
          id: 'ada-test',
          judgeName: 'Ada',
          email: _email,
          password: 'test',
          country: 'Türkiye',
          oath: true,
          createdAt: DateTime(2024, 1, 1),
          lastLoginAt: DateTime(2024, 6, 1),
        ),
      );
    }
    _detaySaved = await _addEvidence(davaId: 'detay-dava', title: 'Detay delili');
    _detayOther = await _addEvidence(davaId: 'detay-dava', title: 'Baska delil');
    await service.setUserVote(_detaySaved.id, _email, 'neutral');
    _listeFirst = await _addEvidence(davaId: 'liste-dava', title: 'Liste birinci');
    _listeSecond = await _addEvidence(davaId: 'liste-dava', title: 'Liste ikinci');
    await service.setUserVote(_listeFirst.id, _email, 'neutral');
  });

  test('nötr oy kullanıcı, dava ve delil bazında kalır', () async {
    const davaId = 'hafiza-dava';
    final first = await _addEvidence(davaId: davaId, title: 'Birinci delil');
    final second = await _addEvidence(davaId: davaId, title: 'Ikinci delil');

    await service.setUserVote(first.id, '  Ada@Example.com  ', 'neutral');

    expect(service.getEvidenceById(first.id)!.getUserVote(_email), 'neutral');
    expect(service.getEvidenceById(first.id)!.hasUserNeutral(_email), isTrue);
    expect(service.getEvidenceById(first.id)!.neutralCount, 1);
    expect(service.getEvidenceById(second.id)!.getUserVote(_email), isNull);
    expect(service.getEvidenceById(second.id)!.neutralCount, 0);

    await Hive.box<EvidenceModel>('evidence_box').close();
    await service.initialize();

    final reopened = service.getEvidenceById(first.id)!;
    expect(reopened.getUserVote('ada@example.com'), 'neutral');
    expect(service.getEvidenceById(second.id)!.getUserVote(_email), isNull);

    await service.setUserVote(first.id, _email, 'like');
    expect(service.getEvidenceById(first.id)!.getUserVote(_email), 'like');
    expect(service.getEvidenceById(first.id)!.neutralCount, 0);
    expect(service.getEvidenceById(first.id)!.likeCount, 1);
    expect(service.getEvidenceById(second.id)!.getUserVote(_email), isNull);

    await service.toggleNeutral(first.id, _email);
    expect(service.getEvidenceById(first.id)!.getUserVote(_email), 'neutral');

    await service.applyDefaultLikesForUsers(davaId, [_email, _other]);
    expect(
      service.getEvidenceById(first.id)!.getUserVote(_email),
      'neutral',
      reason: 'Yargı süresi dolunca kayıtlı nötr oy varsayılan beğeniye dönmemeli',
    );
    expect(service.getEvidenceById(second.id)!.getUserVote(_email), 'like');
    expect(service.getEvidenceById(second.id)!.getUserVote(_other), 'like');
    expect(service.getEvidenceById(first.id)!.getUserVote(_other), 'like');
    expect(service.getEvidenceById(first.id)!.hasUserNeutral(_other), isFalse);
  });

  testWidgets('detay sayfası kayıtlı nötr oyu gösterir ve geri oku yoktur', (tester) async {
    final saved = _detaySaved;
    final other = _detayOther;

    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> openDetail(EvidenceModel evidence) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DelilDetayPage(
                        userEmail: _email,
                        evidence: evidence,
                      ),
                    ),
                  );
                },
                child: const Text('Delili aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Delili aç'));
      await _pump(tester, const Duration(milliseconds: 400));
      await tester.ensureVisible(find.textContaining('Delili Değerlendirdim'));
      await tester.pump();
    }

    await openDetail(_staleCopy(saved));

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byTooltip('Geri'), findsNothing);
    expect(find.text('DELİL DETAYI'), findsOneWidget);
    final title = tester.getRect(find.text('DELİL DETAYI'));
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect((title.center.dx - width / 2).abs(), lessThan(8));
    expect(_selectedVote('Nötr'), findsOneWidget);
    expect(_selectedVote('Geçerli'), findsNothing);
    expect(service.getEvidenceById(other.id)!.getUserVote(_email), isNull);

    await tester.ensureVisible(find.text('Geçerli'));
    await tester.tap(find.text('Geçerli'));
    await _untilFound(tester, _selectedVote('Geçerli'));

    expect(service.getEvidenceById(saved.id)!.getUserVote(_email), 'like');
    expect(service.getEvidenceById(other.id)!.getUserVote(_email), isNull);
    expect(_selectedVote('Geçerli'), findsOneWidget);
    expect(_selectedVote('Nötr'), findsNothing);

    Navigator.of(tester.element(find.text('DELİL DETAYI'))).pop();
    await _pump(tester);
    expect(find.text('Delili aç'), findsOneWidget);

    await openDetail(_staleCopy(saved));
    expect(_selectedVote('Geçerli'), findsOneWidget);
    expect(service.getEvidenceById(saved.id)!.getUserVote(_email), 'like');
  });

  testWidgets('liste ve detay aynı delilin kayıtlı oyunu gösterir', (tester) async {
    const davaId = 'liste-dava';
    final first = _listeFirst;
    final second = _listeSecond;

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EvidenceViewerWidget(
            davaId: davaId,
            userEmail: _email,
          ),
        ),
      ),
    );
    await _pump(tester, const Duration(milliseconds: 400));
    expect(find.text('Resim'), findsOneWidget);
    await tester.tap(find.text('Resim'));
    await _pump(tester, const Duration(milliseconds: 400));

    expect(find.text('Resim Delilleri'), findsOneWidget);
    expect(_voteInCard('Liste birinci', 'Nötr', selected: true), findsOneWidget);
    expect(_voteInCard('Liste birinci', 'Geçerli', selected: true), findsNothing);
    expect(_voteInCard('Liste ikinci', 'Nötr', selected: true), findsNothing);
    expect(_voteInCard('Liste ikinci', 'Geçerli', selected: true), findsNothing);

    await tester.tap(find.text('Liste birinci'));
    await _pump(tester, const Duration(milliseconds: 500));
    await tester.ensureVisible(find.textContaining('Delili Değerlendirdim'));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(_selectedVote('Nötr'), findsOneWidget);

    await tester.ensureVisible(find.text('Geçersiz'));
    await tester.tap(find.text('Geçersiz'));
    await _untilFound(tester, _selectedVote('Geçersiz'));
    expect(service.getEvidenceById(first.id)!.getUserVote(_email), 'dislike');
    expect(service.getEvidenceById(second.id)!.getUserVote(_email), isNull);

    Navigator.of(tester.element(find.text('DELİL DETAYI'))).pop();
    await _untilFound(tester, _voteInCard('Liste birinci', 'Geçersiz', selected: true));
    expect(_voteInCard('Liste birinci', 'Nötr', selected: true), findsNothing);
    expect(_voteInCard('Liste ikinci', 'Geçersiz', selected: true), findsNothing);
    expect(service.getEvidenceById(second.id)!.getUserVote(_email), isNull);

    Navigator.of(tester.element(find.text('Resim Delilleri'))).pop();
    await _pump(tester);
    await tester.tap(find.text('Resim'));
    await _untilFound(tester, _voteInCard('Liste birinci', 'Geçersiz', selected: true));
    expect(_voteInCard('Liste ikinci', 'Nötr', selected: true), findsNothing);
  });
}
