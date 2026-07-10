import '../utils/dava_map_utils.dart';

/// Basit Dava sınıfı - dialog_utils.dart ve diğer yerlerde kullanım için
class Dava {
  final String id;
  final String davaAdi;
  final String kategori;
  final String davaci;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String davaKonusu; // Dava konusu alanı eklendi
  final bool isOpened;

  Dava({
    required this.id,
    required this.davaAdi,
    required this.kategori,
    this.davaci = '',
    this.davali = '',
    this.mevkii = '',
    this.kalanSure = '',
    this.profilResmi = '',
    this.davaKonusu = '', // Dava konusu varsayılan değeri
    this.isOpened = false,
  });

  // Map'ten Dava oluşturma
  factory Dava.fromMap(Map<String, dynamic> map) {
    return Dava(
      id: map['id'] ?? '',
      davaAdi: map['davaAdi'] ?? map['adi'] ?? '',
      kategori: resolveDavaKategoriFromMap(map),
      davaci: map['davaci'] ?? '',
      davali: map['davali'] ?? '',
      mevkii: map['mevkii'] ?? '',
      kalanSure: map['kalanSure'] ?? '',
      profilResmi: map['profilResmi'] ?? '',
      davaKonusu: map['davaKonusu'] ?? '', // Dava konusu alanı eklendi
      isOpened: map['isOpened'] ?? false,
    );
  }

  // Dava'dan Map oluşturma
  Map<String, dynamic> toMap() {
    return withDavaKategoriFields({
      'id': id,
      'davaAdi': davaAdi,
      'davaci': davaci,
      'davali': davali,
      'mevkii': mevkii,
      'kalanSure': kalanSure,
      'profilResmi': profilResmi,
      'davaKonusu': davaKonusu,
      'isOpened': isOpened,
    }, kategori);
  }
}
