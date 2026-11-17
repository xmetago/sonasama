import 'package:flutter/material.dart';

import '../../theme/seyir_tokens.dart';

/// Yuvarlatılmış, gölgeli arama alanı.
///
/// Kaydedilen haykırlar, kaydedilen widget'lar ve istatistik panosundaki
/// özel arama kutularının ortak görüntüsüdür. Kutu ve yazı renkleri
/// Seyir paletinden gelir; odak çizgisi marka yeşilidir.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.suffixIcon,
    this.focusNode,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  /// İstatistik ekranındaki filtre ikonu gibi isteğe bağlı sağ ikon.
  final Widget? suffixIcon;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: SeyirTokens.radiusLgAll,
        boxShadow: palette.cardShadow,
      ),
      child: TextField(
        focusNode: focusNode,
        style: palette.body(),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: palette.textSecondary,
          ),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: palette.body(
            weight: FontWeight.w400,
            color: palette.textMuted,
          ),
          filled: true,
          fillColor: palette.card,
          border: OutlineInputBorder(
            borderRadius: SeyirTokens.radiusLgAll,
            borderSide: BorderSide(color: palette.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: SeyirTokens.radiusLgAll,
            borderSide: BorderSide(color: palette.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: SeyirTokens.radiusLgAll,
            borderSide: BorderSide(
              color: palette.foreground(SeyirTokens.brand),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
