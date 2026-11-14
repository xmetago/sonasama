import 'package:flutter/material.dart';

import 'seyir_tokens.dart';

/// Seyir token'larının uygulama temasına taşınmış hali.
///
/// Renkler [SeyirTokens] ile aynıdır. Kabul ve red dışında yeşil/kırmızı yok.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brand,
    required this.brandDeep,
    required this.accept,
    required this.reject,
    required this.warning,
  });

  final Color brand;
  final Color brandDeep;
  final Color accept;
  final Color reject;
  final Color warning;

  static const AppTokens standard = AppTokens(
    brand: SeyirTokens.brand,
    brandDeep: SeyirTokens.brandDeep,
    accept: SeyirTokens.accept,
    reject: SeyirTokens.reject,
    warning: SeyirTokens.warning,
  );

  static AppTokens of(BuildContext context) {
    return Theme.of(context).extension<AppTokens>() ?? standard;
  }

  @override
  AppTokens copyWith({
    Color? brand,
    Color? brandDeep,
    Color? accept,
    Color? reject,
    Color? warning,
  }) {
    return AppTokens(
      brand: brand ?? this.brand,
      brandDeep: brandDeep ?? this.brandDeep,
      accept: accept ?? this.accept,
      reject: reject ?? this.reject,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      brand: Color.lerp(brand, other.brand, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      accept: Color.lerp(accept, other.accept, t)!,
      reject: Color.lerp(reject, other.reject, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

/// Açık ve koyu [ThemeData]. Seyir defteri [SeyirPalette.of] ile bu şemayı okur.
abstract final class WhoBoomTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    final ColorScheme seed = ColorScheme.fromSeed(
      seedColor: SeyirTokens.brand,
      brightness: brightness,
    );
    final Color primary = dark ? SeyirTokens.brand : SeyirTokens.brandDeep;
    final ColorScheme scheme = seed.copyWith(
      primary: primary,
      onPrimary: dark ? SeyirTokens.neutral900 : SeyirTokens.neutral0,
      secondary: SeyirTokens.brand,
      onSecondary: SeyirTokens.neutral900,
      error: SeyirTokens.reject,
      onError: SeyirTokens.neutral0,
      surface: dark ? seed.surface : SeyirTokens.neutral50,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'cocon',
      scaffoldBackgroundColor: scheme.surface,
      extensions: const <ThemeExtension<dynamic>>[AppTokens.standard],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
