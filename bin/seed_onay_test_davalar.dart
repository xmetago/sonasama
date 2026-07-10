import 'package:flutter/widgets.dart';

import 'package:its19/services/dava_seed_service.dart';
import 'package:its19/services/hive_database_service.dart';

/// Davacı onay butonları test verisini Hive'a yazar.
///
/// Kullanım:
///   dart run bin/seed_onay_test_davalar.dart
///   dart run bin/seed_onay_test_davalar.dart "Nasrullah Keskin"
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabaseService.initialize();

  final String davaciName = args.isNotEmpty ? args.join(' ') : 'Test Davacı';

  final result = await DavaSeedService.seedDavaciOnayTestDavalar(
    davaciName: davaciName,
  );

  print('✅ KURAL SETİ — 4 onay senaryosu yüklendi (davacı: $davaciName)');
  print('   D1 → ${result['durum1Id']} — ${result['durum1Adi']}');
  print('        ${result['durum1Buton']}');
  print('   D2 → ${result['durum2Id']} — ${result['durum2Adi']}');
  print('        ${result['durum2Buton']}');
  print('   D3 → ${result['durum3Id']} — ${result['durum3Adi']}');
  print('        ${result['durum3Buton']}');
  print('   D4 → ${result['durum4Id']} — ${result['durum4Adi']}');
  print('        ${result['durum4Buton']}');
  print('');
  print('Uygulamada: Açtığım Davalar sayfasını açın veya yenileyin.');
}
