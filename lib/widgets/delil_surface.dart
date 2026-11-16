import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';

/// Dava listelerindeki yumuşak boş kart: 64px ikon, başlık 15, gövde 13, 24px.
class DelilSoftEmpty extends StatelessWidget {
  const DelilSoftEmpty({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
      padding: const EdgeInsets.all(SeyirTokens.space6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusLgAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: palette.textMuted),
          const SizedBox(height: SeyirTokens.space4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: palette.title(
              weight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: palette.body(
              weight: FontWeight.w400,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yükleme hatası. Boş liste yerine mesaj ve yeniden deneme.
class DelilLoadError extends StatelessWidget {
  const DelilLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
      padding: const EdgeInsets.all(SeyirTokens.space6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusLgAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 64, color: palette.textMuted),
          const SizedBox(height: SeyirTokens.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: palette.title(
              weight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: SeyirTokens.space4),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              foregroundColor: palette.textPrimary,
              side: BorderSide(color: palette.border),
            ),
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

ButtonStyle delilIconButtonStyle({Color? foreground}) {
  return IconButton.styleFrom(
    minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
    tapTargetSize: MaterialTapTargetSize.padded,
    foregroundColor: foreground,
  );
}
