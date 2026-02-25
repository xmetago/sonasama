import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:its19/models/hukum_sentiment.dart';
import 'package:its19/services/dava_consensus_service.dart';
import 'package:its19/services/dava_seed_service.dart';
import 'package:its19/services/dava_timer_service.dart';
import 'package:its19/services/hive_database_service.dart';

class _InMemoryPathProvider extends PathProviderPlatform {
  Directory? _tempDirectory;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    _tempDirectory ??= Directory.systemTemp.createTempSync('its19_test_');
    return _tempDirectory!.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _InMemoryPathProvider();

  group('Expired accepted dava demo', () {
    setUpAll(() async {
      await HiveDatabaseService.initialize();
    });

    test('Seed expired accepted dava and verify withdrawal message', () async {
      final seedResult = await DavaSeedService.seedExpiredAcceptedDava(
        userEmail: 'testyargic1@gmail.com',
        judgeName: 'Nasrullah Keskin',
        mevki: '1.Jüri',
        davaAdi: 'Vicdani Problemler Davası',
      );

      final messages = await DavaTimerService.buildExpiredAcceptedMessages(
        davaId: seedResult['davaId']?.toString() ?? '',
        davaAdi: seedResult['davaAdi']?.toString() ?? '',
        referenceTime: DateTime.now(),
      );

      expect(messages, isNotEmpty);
      expect(
        messages.first,
        contains('"1.Jüri" "Nasrullah Keskin"'),
      );

      final String davaId = seedResult['davaId']?.toString() ?? '';

      await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: '1. Jüri Kararı',
        hukumText: 'Davacıyı destekliyorum.',
        userEmail: 'testyargic1@gmail.com',
        hukumSentiment: HukumSentiment.positive.storageValue,
      );
      await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: '2. Jüri Kararı',
        hukumText: 'Ben de olumlu düşünüyorum.',
        userEmail: 'testyargic2@gmail.com',
        hukumSentiment: HukumSentiment.positive.storageValue,
      );
      await HiveDatabaseService.saveHukum(
        davaId: davaId,
        userRole: 'Davalı Avukatı Kararı',
        hukumText: 'Karşı görüş bildiriyorum.',
        userEmail: 'testyargic5@gmail.com',
        hukumSentiment: HukumSentiment.negative.storageValue,
      );

      final DavaConsensusEvaluation evaluation =
          await DavaConsensusService.evaluateConsensus(
        davaId: davaId,
        referenceTime: DateTime.now(),
      );

      expect(evaluation.isFinal, isTrue);
      expect(evaluation.verdict, DavaConsensusVerdict.hakli);
      expect(evaluation.positiveCount, 2);
      expect(evaluation.negativeCount, 1);
    });
  });
}

