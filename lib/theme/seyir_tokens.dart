import 'package:flutter/material.dart';

/// Seyir defteri görsel dili.
///
/// Renk, yazı, boşluk ve köşe ölçüleri burada toplanır. Kabul ve red
/// dışında yeşil/kırmızı kullanılmaz.
abstract final class SeyirTokens {
  static const Color brand = Color(0xFF34DFAE);
  static const Color brandDeep = Color(0xFF0C7A54);

  /// Yalnızca kabul / olumlu sonuç.
  static const Color accept = Color(0xFF15803D);

  /// Yalnızca red / olumsuz sonuç.
  static const Color reject = Color(0xFFDC2626);

  static const Color warning = Color(0xFFC2410C);

  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF7F8F8);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral900 = Color(0xFF1A1A1A);

  static const Color sectionPeople = Color(0xFF2563EB);
  static const Color sectionEvidence = Color(0xFF7C3AED);
  static const Color sectionPenalty = Color(0xFF4F46E5);
  static const Color sectionPenaltyVote = Color(0xFF0F766E);
  static const Color sectionGift = Color(0xFFB45309);
  static const Color sectionGiftVote = Color(0xFF0E7490);
  static const Color sectionVerdict = Color(0xFF4338CA);
  static const Color sectionAppeal = Color(0xFF8A5FBF);

  static const Color engageComment = Color(0xFF1D9BF0);
  static const Color engageRetweet = Color(0xFF00BA7C);
  static const Color engageLike = Color(0xFFF91880);
  static const Color engageSave = Color(0xFF7856FF);
  static const Color engageIdle = Color(0xFF71767B);

  static const double typeCaption = 11;
  static const double typeBody = 13;
  static const double typeTitle = 15;
  static const double typeHeadline = 18;
  static const double typeDisplay = 22;

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static const double tapTarget = 44;

  static const Duration motion = Duration(milliseconds: 280);

  static const BorderRadius radiusSmAll =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius radiusMdAll =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius radiusLgAll =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(radiusXl));
}

/// Tema parlaklığına göre yüzey ve metin renkleri.
class SeyirPalette {
  const SeyirPalette(this.scheme, this.brightness);

  final ColorScheme scheme;
  final Brightness brightness;

  factory SeyirPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    return SeyirPalette(theme.colorScheme, theme.brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  Color get surface => scheme.surface;

  Color get surfaceMuted => Color.alphaBlend(
        scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.04),
        scheme.surface,
      );

  Color get card => Color.alphaBlend(
        scheme.onSurface.withValues(alpha: isDark ? 0.06 : 0.0),
        scheme.surface,
      );

  Color get border => scheme.outlineVariant;

  Color get textPrimary => scheme.onSurface;

  Color get textSecondary => scheme.onSurfaceVariant;

  Color get textMuted => scheme.onSurfaceVariant.withValues(alpha: 0.85);

  Color get shadow => scheme.shadow.withValues(alpha: isDark ? 0.45 : 0.10);

  Color get brandSoft =>
      SeyirTokens.brand.withValues(alpha: isDark ? 0.20 : 0.14);

  Color tint(Color accent) => accent.withValues(alpha: isDark ? 0.22 : 0.10);

  Color tintBorder(Color accent) =>
      accent.withValues(alpha: isDark ? 0.55 : 0.32);

  Color foreground(Color accent) => isDark
      ? Color.lerp(accent, SeyirTokens.neutral0, 0.45)!
      : Color.lerp(accent, SeyirTokens.neutral900, 0.35)!;

  Color onSolid(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? SeyirTokens.neutral0
        : SeyirTokens.neutral900;
  }

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  TextStyle caption({
    Color? color,
    FontWeight weight = FontWeight.w500,
    FontStyle? fontStyle,
    double height = 1.35,
  }) {
    return TextStyle(
      fontSize: SeyirTokens.typeCaption,
      fontWeight: weight,
      color: color ?? textSecondary,
      fontStyle: fontStyle,
      height: height,
    );
  }

  TextStyle body({
    Color? color,
    FontWeight weight = FontWeight.w500,
    FontStyle? fontStyle,
    double height = 1.45,
  }) {
    return TextStyle(
      fontSize: SeyirTokens.typeBody,
      fontWeight: weight,
      color: color ?? textPrimary,
      fontStyle: fontStyle,
      height: height,
    );
  }

  TextStyle title({
    Color? color,
    FontWeight weight = FontWeight.w700,
    double height = 1.3,
  }) {
    return TextStyle(
      fontSize: SeyirTokens.typeTitle,
      fontWeight: weight,
      color: color ?? textPrimary,
      height: height,
    );
  }

  TextStyle headline({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) {
    return TextStyle(
      fontSize: SeyirTokens.typeHeadline,
      fontWeight: weight,
      color: color ?? textPrimary,
      height: 1.25,
    );
  }

  TextStyle display({
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) {
    return TextStyle(
      fontSize: SeyirTokens.typeDisplay,
      fontWeight: weight,
      color: color ?? textPrimary,
      height: 1.2,
      letterSpacing: -0.3,
    );
  }
}

/// Açılış tarihini Türkçe göreli anlatır. Mutlak tarih ayrıca gösterilir.
String seyirRelativeTime(DateTime date, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(date);
  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Az önce';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes} dakika önce';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours} saat önce';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} gün önce';
  }
  if (difference.inDays < 30) {
    return '${difference.inDays ~/ 7} hafta önce';
  }
  if (difference.inDays < 365) {
    return '${difference.inDays ~/ 30} ay önce';
  }
  return '${difference.inDays ~/ 365} yıl önce';
}

String seyirAbsoluteDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
