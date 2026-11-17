import 'package:flutter/material.dart';

import '../../theme/seyir_tokens.dart';

/// Liste boşken veya arama eşleşmediğinde gösterilen kart.
///
/// Sorgu doluysa başlık her zaman "Arama sonucuna ulaşılamadı" olur ve
/// altında `"sorgu" için eşleşme yok` yazılır. Sorgu boşsa [emptyMessage] gösterilir.
class AppEmptyResultCard extends StatelessWidget {
  const AppEmptyResultCard({
    super.key,
    required this.query,
    required this.emptyMessage,
    required this.icon,
  });

  final String query;
  final String emptyMessage;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final hasQuery = query.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: SeyirTokens.space6),
      padding: const EdgeInsets.all(SeyirTokens.space6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusLgAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: palette.textMuted,
          ),
          const SizedBox(height: SeyirTokens.space4),
          Text(
            hasQuery ? 'Arama sonucuna ulaşılamadı' : emptyMessage,
            textAlign: TextAlign.center,
            style: palette.title(
              weight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
          if (hasQuery) ...[
            const SizedBox(height: SeyirTokens.space2),
            Text(
              '"$query" için eşleşme yok',
              textAlign: TextAlign.center,
              style: palette.body(
                weight: FontWeight.w400,
                color: palette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
