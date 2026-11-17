import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';

/// Admin panosundaki istatistik kutusu.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final accent = palette.isDark ? SeyirTokens.brand : const Color(0xFF059669);
    return Container(
      padding: const EdgeInsets.all(SeyirTokens.space3),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: SeyirTokens.radiusSmAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            value,
            style: palette.display(color: accent),
          ),
          Text(
            title,
            style: palette.body(
              color: palette.textSecondary,
              weight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
