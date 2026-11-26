part of 'cezalar_ceza_unified_panel.dart';

/// Ceza yönetimi vurguları. Lacivert, bordo ve mor sabitleri yerine Seyir.
class _MahkemeRenkler {
  static SeyirPalette _palette(BuildContext context) => SeyirPalette.of(context);

  /// Karar belgesi başlığı. Koyu temada yüzey, açıkta marka yeşili.
  static Color header(BuildContext context) {
    final SeyirPalette palette = _palette(context);
    return palette.isDark ? palette.surfaceMuted : SeyirTokens.brandDeep;
  }

  static Color onHeader(BuildContext context) =>
      _palette(context).onSolid(header(context));

  /// Mühür ve seçim vurgusu. Koyu temada marka, açıkta koyu marka.
  static Color accent(BuildContext context) {
    final SeyirPalette palette = _palette(context);
    return palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep;
  }

  static Color onAccent(BuildContext context) =>
      _palette(context).onSolid(accent(context));

  static Color danger(BuildContext context) => SeyirTokens.reject;

  static Color warning(BuildContext context) => SeyirTokens.warning;
}
