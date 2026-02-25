import 'package:flutter/widgets.dart';

import 'package:its19/services/dava_seed_service.dart';
import 'package:its19/services/dava_timer_service.dart';
import 'package:its19/services/hive_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabaseService.initialize();

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

  if (messages.isEmpty) {
    print('Gösterilecek süre aşımı mesajı bulunamadı.');
  } else {
    for (final message in messages) {
      print(message);
    }
  }
}

