import 'package:flutter/foundation.dart';

/// Yayın derlemesinde sessiz kalan günlük. Yeni paket gerektirmez.
///
/// [debugPrint] çıktıyı kısar; mevcut testler ve debug akışı `print` hızında
/// kalsın diye burada doğrudan yazılır.
void appLog(Object? message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(message);
  }
}
