/// [CezalarPage] / [CezaYonetimWidget] için ortak dava özeti modeli.
class CezalarUnifiedDava {
  final String adi;
  final String davali;
  final String davaci;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;

  const CezalarUnifiedDava({
    required this.adi,
    required this.davali,
    this.davaci = '',
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
  });
}

