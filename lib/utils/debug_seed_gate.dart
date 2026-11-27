import 'package:flutter/foundation.dart';

/// Test hesapları ve davet senaryoları yalnızca debug derlemesinde çalışır.
///
/// [debugMode] testlerin release kapısını doğrulaması içindir. Uygulama
/// çağrıları bu parametreyi vermez ve [kDebugMode] kullanılır.
bool shouldSeedDebugData({bool? debugMode}) {
  return debugMode ?? kDebugMode;
}
