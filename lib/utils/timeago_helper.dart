import 'package:timeago/timeago.dart' as timeago;

/// Timeago yardımcı fonksiyonları
/// "2 dakika önce" formatı için kullanılır
/// ✅ Otomatik dil desteği
/// ✅ Performanslı tarih formatlaması
class TimeAgoHelper {
  /// Timeago'yu Türkçe olarak başlat
  /// Uygulama başlangıcında bir kez çağrılmalı
  static void initialize() {
    // Türkçe locale ayarla
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    timeago.setDefaultLocale('tr');
  }

  /// Tarihi "2 dakika önce" formatına çevir
  /// [date] Formatlanacak tarih
  /// [locale] Dil kodu (varsayılan: 'tr')
  /// [allowFromNow] Gelecek tarihler için de çalışsın mı (varsayılan: false)
  static String format(DateTime date, {String? locale, bool allowFromNow = false}) {
    try {
      return timeago.format(
        date,
        locale: locale ?? 'tr',
        allowFromNow: allowFromNow,
      );
    } catch (e) {
      // Hata durumunda basit format döndür
      return _fallbackFormat(date);
    }
  }

  /// Tarihi "2 dakika önce" formatına çevir (String tarih için)
  /// [dateString] ISO 8601 formatında tarih string'i
  static String formatFromString(String dateString, {String? locale, bool allowFromNow = false}) {
    try {
      final date = DateTime.parse(dateString);
      return format(date, locale: locale, allowFromNow: allowFromNow);
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }

  /// Gelecek tarihler için format (örn: "2 dakika sonra")
  static String formatFuture(DateTime date, {String? locale}) {
    return format(date, locale: locale, allowFromNow: true);
  }

  /// Fallback format (timeago çalışmazsa)
  static String _fallbackFormat(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  /// Tarihi kısa formatla göster (örn: "2dk önce")
  static String formatShort(DateTime date, {String? locale}) {
    try {
      final formatted = format(date, locale: locale);
      // Kısa format için özelleştirme
      return formatted
          .replaceAll(' dakika', 'dk')
          .replaceAll(' saat', 'sa')
          .replaceAll(' gün', 'g')
          .replaceAll(' hafta', 'h')
          .replaceAll(' ay', 'a')
          .replaceAll(' yıl', 'y');
    } catch (e) {
      return _fallbackFormat(date);
    }
  }
}

