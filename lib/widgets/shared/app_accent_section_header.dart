import 'package:flutter/material.dart';

import '../../theme/seyir_tokens.dart';

/// Solunda ince renk çubuğu olan bölüm başlığı.
///
/// Kaydedilenler sayfalarında çubuk mor, istatistik panosunda tema ana rengidir.
/// Varsayılan mor, bu adımda taşınan iki sayfanın mevcut görünümünü korur.
class AppAccentSectionHeader extends StatelessWidget {
  const AppAccentSectionHeader({
    super.key,
    required this.title,
    this.accentColor = Colors.purple,
  });

  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: SeyirTokens.space3),
          Expanded(
            child: Text(
              title,
              style: palette.headline(),
            ),
          ),
        ],
      ),
    );
  }
}
