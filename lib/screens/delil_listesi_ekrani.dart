import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delil Listesi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
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
