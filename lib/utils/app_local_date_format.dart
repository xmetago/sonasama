import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Evrensel (locale-aware) tarih/saat gösterimi.
///
/// - **Gösterim**: Cihazın yerel saat dilimi ([DateTime.toLocal]) + uygulama dili
///   ([Localizations.localeOf]) ile uyumludur.
/// - **Depolama**: Kalıcı veri için tercihen UTC ISO-8601 kullanın; gösterimde bu
///   yardımcıları veya `toLocal()` ile biçimlendirin.
class AppLocalDateFormat {
  AppLocalDateFormat._();

  static String _localeName(Locale locale) => locale.toString();

  static DateFormat _shortDate(Locale locale) {
    final name = _localeName(locale);
    try {
      return DateFormat.yMd(name);
    } catch (_) {
      try {
        return DateFormat.yMd(locale.languageCode);
      } catch (_) {
        return DateFormat.yMd('en');
      }
    }
  }

  static DateFormat _shortDateTime(Locale locale) {
    final name = _localeName(locale);
    try {
      return DateFormat.yMd(name).add_Hm();
    } catch (_) {
      try {
        return DateFormat.yMd(locale.languageCode).add_Hm();
      } catch (_) {
        return DateFormat.yMd('en').add_Hm();
      }
    }
  }

  /// Kısa tarih (ör. tr: 24.03.2026, en_US: 3/24/2026).
  static String formatShortDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return _shortDate(locale).format(date.toLocal());
  }

  /// [BuildContext] olmadan (ör. isolate / test) — mümkünse [formatShortDate] tercih edin.
  static String formatShortDateForLocale(Locale locale, DateTime date) {
    return _shortDate(locale).format(date.toLocal());
  }

  /// Tarih + saat, [Locale] ile (async sonrası [Localizations] kullanılamadığında).
  static String formatShortDateTimeForLocale(Locale locale, DateTime date) {
    return _shortDateTime(locale).format(date.toLocal());
  }

  /// Tarih + saat (aynı locale kuralları).
  static String formatShortDateTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return _shortDateTime(locale).format(date.toLocal());
  }
}
