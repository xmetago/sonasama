import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';

/// Gelen arkadaşlık isteklerinin listesi. Satırlar [itemBuilder] ile kurulur.
class FriendshipIncomingRequestsDialog extends StatelessWidget {
  const FriendshipIncomingRequestsDialog({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
      ),
      title: Text(
        'Gelen Arkadaşlık İstekleri',
        style: palette.headline(),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
            foregroundColor: palette.textPrimary,
          ),
          child: Text(
            'Kapat',
            style: palette.title(weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
