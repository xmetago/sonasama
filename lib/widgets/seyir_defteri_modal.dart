import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';
import 'ilgililerin_seyir_defteri_widgeti.dart';
import 'seyir_defteri/seyir_sheet_chrome.dart';

/// Ilgililerin seyir defteri widget'ını modern bir alt sayfada gösterir.
class SeyirDefteriModal {
  const SeyirDefteriModal._();

  /// Belirtilen dava verileri ile seyir defterini açar.
  static Future<void> showForDava({
    required BuildContext context,
    required String davaId,
    String? userEmail,
    String? davaAdi,
    String? davaci,
    String? davali,
    String? kategori,
    String? davaKonusu,
    DateTime? openedAt,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        final mediaQuery = MediaQuery.of(modalContext);
        final palette = SeyirPalette.of(modalContext);
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          initialChildSize: mediaQuery.size.height > 700 ? 0.75 : 0.9,
          builder: (_, controller) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: SeyirTokens.sheetTop,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: SeyirTokens.sheetTop,
                child: Column(
                  children: [
                    const SeyirDragHandle(),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: EdgeInsets.fromLTRB(
                          SeyirTokens.space4,
                          SeyirTokens.space2,
                          SeyirTokens.space4,
                          mediaQuery.viewInsets.bottom + SeyirTokens.space6,
                        ),
                        children: [
                          IlgililerinSeyirDefteriWidgeti(
                            davaId: davaId,
                            userEmail: userEmail,
                            davaAdi: davaAdi,
                            davaci: davaci,
                            davali: davali,
                            kategori: kategori,
                            davaKonusu: davaKonusu,
                            openedAt: openedAt,
                            onClose: () =>
                                Navigator.of(modalContext).maybePop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
