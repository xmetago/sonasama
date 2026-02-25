import 'package:flutter/material.dart';

import 'ilgililerin_seyir_defteri_widgeti.dart';

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
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          initialChildSize: mediaQuery.size.height > 700 ? 0.75 : 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.only(
                    bottom: mediaQuery.viewInsets.bottom + 24,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: IlgililerinSeyirDefteriWidgeti(
                      davaId: davaId,
                      userEmail: userEmail,
                      davaAdi: davaAdi,
                      davaci: davaci,
                      davali: davali,
                      kategori: kategori,
                      davaKonusu: davaKonusu,
                      openedAt: openedAt,
                      onClose: () => Navigator.of(modalContext).maybePop(),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

