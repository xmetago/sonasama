part of 'cezalar_ceza_unified_panel.dart';

/// Mahkeme renk paleti (mor tonları + kritik aksiyonda kırmızı)
class _MahkemeRenkler {
  static const Color koyu = Color(0xFF26215C); // Başlık şeritleri, koyu zemin
  static const Color ortaKahve = Color(0xFF534AB7); // Vurgu, seçili durumlar
  static const Color altin = Color(0xFFCECBF6); // Kenarlık, ikincil metin
  static const Color kirmizi = Color(0xFFA32D2D); // Yalnızca ceza onayı / kritik butonlar
  static const Color krem = Color(0xFFEEEDFE); // Panel zemini
  static const Color kemik = Color(0xFFF1EFE8); // Liste yüzeyleri, nötr alan
  // ignore: unused_field — palet rezervi (avukat / gizem vurguları için)
  static const Color yesil = Color(0xFF1B4D2E); // Koyu yeşil — avukat
  // ignore: unused_field
  static const Color mor = Color(0xFF2D0B4E); // Mor — gizem
  static const Color gri = Color(0xFF5C5C5C); // Gri — nötr
}

