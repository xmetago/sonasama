import 'package:flutter/material.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/evidence_viewer_widget.dart';

/// Ana Delil Listesi Ekranı
/// Seyir Defteri sayfasından "Delil Listesine Gözat" butonuna basınca açılır
/// Modern EvidenceViewerWidget kullanır
class DelilListesiEkrani extends StatelessWidget {
  final String davaId;
  final String? userEmail;
  
  const DelilListesiEkrani({
    super.key,
    required this.davaId,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    const barColor = Color(0xFF1565C0);
    final onBar = palette.onSolid(barColor);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(
          'Delil Listesi',
          style: palette.headline(color: onBar),
        ),
        backgroundColor: barColor,
        foregroundColor: onBar,
        iconTheme: IconThemeData(color: onBar),
        elevation: 0,
        toolbarHeight: SeyirTokens.tapTarget,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.tint(Colors.blue),
              palette.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: EvidenceViewerWidget(
            davaId: davaId,
            userEmail: userEmail,
            title: 'Delillerinizi İnceleyin',
          ),
        ),
      ),
    );
  }
}
