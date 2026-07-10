import 'package:flutter/material.dart';

import 'hukum_gift_selection_page.dart';

/// Eski carousel tabanlı masraf seçim ekranı kaldırıldı.
/// Aynı giriş noktası adı korunur; doğrudan [HukumGiftSelectionPage] gösterilir.
class MasrafSelectionPage extends StatelessWidget {
  const MasrafSelectionPage({
    super.key,
    this.userEmail,
    this.davaId,
    this.davaAdi,
  });

  final String? userEmail;
  final String? davaId;
  final String? davaAdi;

  @override
  Widget build(BuildContext context) {
    return HukumGiftSelectionPage(
      userEmail: userEmail,
      davaId: davaId,
      davaAdi: davaAdi,
    );
  }
}
