import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/registration_model.dart';
import '../services/hive_database_service.dart';

/// UI thread'i bloklamadan test kullanıcılarını eklemek için compute() kullanan yardımcılar
/// Kullanım (örnek):
/// await addTestJudgesWithCompute(count: 50, countryByIndex: (i) => countries[i % countries.length]);

/// Top-level: Isolate içinde çalışacak saf üretim fonksiyonu
List<Map<String, dynamic>> _generateTestJudges(Map<String, dynamic> args) {
  final int count = args['count'] as int;
  final String emailPrefix = args['emailPrefix'] as String;
  final String judgeNamePrefix = args['judgeNamePrefix'] as String;
  final String defaultCountry = args['defaultCountry'] as String;
  final List<String>? countries = (args['countries'] as List?)?.cast<String>();

  const uuid = Uuid();
  final List<Map<String, dynamic>> result = [];
  for (int i = 1; i <= count; i++) {
    final email = '$emailPrefix$i@gmail.com';
    final judgeName = 'Test Yargıç $i';
    final country = countries != null && countries.isNotEmpty
        ? countries[(i - 1) % countries.length]
        : defaultCountry;

    result.add({
      'id': uuid.v4(),
      'email': email,
      'password': '123456',
      'judgeName': judgeName,
      'country': country,
      'isActive': true,
      'isEmailVerified': true,
      'canLogin': true,
      'isAdmin': false,
    });
  }
  return result;
}

/// Ana isolate: compute ile üret, sonra Hive'a batched olarak yaz
Future<void> addTestJudgesWithCompute({
  required int count,
  String emailPrefix = 'testyargic',
  String judgeNamePrefix = 'Test Yargıç',
  String defaultCountry = 'Türkiye',
  List<String> countries = const [],
  int batchSize = 10,
  Duration batchDelay = const Duration(milliseconds: 50),
}) async {
  // Liste üretimini arka izolete taşı
  final generated = await compute(_generateTestJudges, {
    'count': count,
    'emailPrefix': emailPrefix,
    'judgeNamePrefix': judgeNamePrefix,
    'defaultCountry': defaultCountry,
    'countries': countries,
  });

  // Hive'a parça parça yaz (UI thread'i yormamak için gecikme ile)
  int index = 0;
  while (index < generated.length) {
    final slice = generated.sublist(
      index,
      (index + batchSize > generated.length) ? generated.length : index + batchSize,
    );

    await Future.wait(slice.map((m) async {
      final now = DateTime.now();
      final model = RegistrationModel(
        id: m['id'] as String,
        email: m['email'] as String,
        password: m['password'] as String,
        judgeName: m['judgeName'] as String,
        country: m['country'] as String,
        oath: true, // Varsayılan olarak true
        createdAt: now,
        lastLoginAt: now,
        isActive: m['isActive'] as bool,
        isEmailVerified: m['isEmailVerified'] as bool,
        isAdmin: m['isAdmin'] as bool,
      );
      await HiveDatabaseService.addRegistration(model);
    }));

    index += batchSize;
    if (index < generated.length) {
      await Future.delayed(batchDelay);
    }
  }
}
