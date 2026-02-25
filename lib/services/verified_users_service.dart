import 'package:hive_flutter/hive_flutter.dart';

/// Verified (mavi tik) kullanıcı yönetimi servisi
/// Yargıç adı bazlı kalıcı verified mekanizması
class VerifiedUsersService {
  static const String _verifiedUsersBoxName = 'verified_users_box';
  static Box? _verifiedUsersBox;

  /// Hive box'ı başlat (HiveDatabaseService.initialize() içinde çağrılmalı)
  static Future<void> initialize() async {
    _verifiedUsersBox = await Hive.openBox(_verifiedUsersBoxName);
  }

  /// Kullanıcının verified olup olmadığını kontrol et
  /// [judgeName] yargıç adı (kullanıcı adı olarak kullanılır)
  static bool isVerified(String judgeName) {
    if (judgeName.isEmpty) return false;
    if (_verifiedUsersBox == null) return false;
    
    final value = _verifiedUsersBox!.get(judgeName);
    return value == true;
  }

  /// Kullanıcıya verified durumu ver/iptal et
  /// [judgeName] yargıç adı (kullanıcı adı olarak kullanılır)
  /// [verified] true = mavi tik ver, false = mavi tik iptal et
  static Future<void> setVerified(String judgeName, bool verified) async {
    if (judgeName.isEmpty) return;
    if (_verifiedUsersBox == null) {
      await initialize();
    }
    
    if (verified) {
      await _verifiedUsersBox!.put(judgeName, true);
    } else {
      await _verifiedUsersBox!.delete(judgeName);
    }
  }

  /// Tüm verified kullanıcıların listesini döndür
  /// Returns: List<String> (yargıç adları listesi)
  static List<String> listVerified() {
    if (_verifiedUsersBox == null) return [];
    
    final verifiedList = <String>[];
    for (final key in _verifiedUsersBox!.keys) {
      final value = _verifiedUsersBox!.get(key);
      if (value == true) {
        verifiedList.add(key.toString());
      }
    }
    return verifiedList;
  }

  /// Tüm verified kullanıcıları temizle (geliştirici için)
  static Future<void> clearAll() async {
    if (_verifiedUsersBox == null) return;
    await _verifiedUsersBox!.clear();
  }
}

