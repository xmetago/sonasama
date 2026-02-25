/// Sekiz Hüküm sayfasına taşınacak dava verilerini modelleyen yardımcı sınıf.
///
/// Bu sınıf, seçilen davaya ait kimlik, taraf bilgileri ve kalan süre gibi
/// alanları kapsar. Yeni özellikler eklenmesi gerektiğinde bu dosya üzerinden
/// genişletilebilir.
class SekizHukumArguments {
  final String? davaId;
  final String davaAdi;
  final String davaDavali;
  final String davaDavaci;
  final String davaGorev;
  final String kalanSure;
  final DateTime? openedAt;

  const SekizHukumArguments({
    this.davaId,
    required this.davaAdi,
    required this.davaDavali,
    required this.davaDavaci,
    required this.davaGorev,
    required this.kalanSure,
    this.openedAt,
  });
}

