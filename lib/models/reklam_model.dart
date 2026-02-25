/// Reklam Modeli
/// 
/// Basit Map yapısı ile reklam verilerini tutar
class ReklamModel {
  final String id;
  final String reklamAdi;
  final String reklamBasligi;
  final String reklamAciklamasi;
  final String reklamResmi;
  final String reklamKodu;
  final String reklamKategorisi;
  final String durum; // 'aktif', 'pasif', 'taslak'
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final String? hedefUrl;
  final int tiklanmaSayisi;
  final int gosterimSayisi;
  final double? maksimumButce;
  final double harcananButce;
  final DateTime olusturulmaTarihi;
  final DateTime guncellenmeTarihi;
  final String? olusturanKullaniciId;
  final Map<String, dynamic>? hedefKitlesi;
  final int priority;

  ReklamModel({
    required this.id,
    required this.reklamAdi,
    required this.reklamBasligi,
    required this.reklamAciklamasi,
    required this.reklamResmi,
    required this.reklamKodu,
    required this.reklamKategorisi,
    this.durum = 'aktif',
    this.baslangicTarihi,
    this.bitisTarihi,
    this.hedefUrl,
    this.tiklanmaSayisi = 0,
    this.gosterimSayisi = 0,
    this.maksimumButce,
    this.harcananButce = 0.0,
    DateTime? olusturulmaTarihi,
    DateTime? guncellenmeTarihi,
    this.olusturanKullaniciId,
    this.hedefKitlesi,
    this.priority = 1,
  })  : olusturulmaTarihi = olusturulmaTarihi ?? DateTime.now(),
        guncellenmeTarihi = guncellenmeTarihi ?? DateTime.now();

  /// Map'ten ReklamModel oluştur
  factory ReklamModel.fromMap(Map<String, dynamic> map) {
    return ReklamModel(
      id: map['id'] as String,
      reklamAdi: map['reklamAdi'] as String,
      reklamBasligi: map['reklamBasligi'] as String,
      reklamAciklamasi: map['reklamAciklamasi'] as String,
      reklamResmi: map['reklamResmi'] as String,
      reklamKodu: map['reklamKodu'] as String,
      reklamKategorisi: map['reklamKategorisi'] as String,
      durum: map['durum'] as String? ?? 'aktif',
      baslangicTarihi: map['baslangicTarihi'] != null
          ? DateTime.parse(map['baslangicTarihi'] as String)
          : null,
      bitisTarihi: map['bitisTarihi'] != null
          ? DateTime.parse(map['bitisTarihi'] as String)
          : null,
      hedefUrl: map['hedefUrl'] as String?,
      tiklanmaSayisi: map['tiklanmaSayisi'] as int? ?? 0,
      gosterimSayisi: map['gosterimSayisi'] as int? ?? 0,
      maksimumButce: map['maksimumButce'] != null
          ? (map['maksimumButce'] as num).toDouble()
          : null,
      harcananButce: (map['harcananButce'] as num?)?.toDouble() ?? 0.0,
      olusturulmaTarihi: map['olusturulmaTarihi'] != null
          ? DateTime.parse(map['olusturulmaTarihi'] as String)
          : null,
      guncellenmeTarihi: map['guncellenmeTarihi'] != null
          ? DateTime.parse(map['guncellenmeTarihi'] as String)
          : null,
      olusturanKullaniciId: map['olusturanKullaniciId'] as String?,
      hedefKitlesi: map['hedefKitlesi'] as Map<String, dynamic>?,
      priority: map['priority'] as int? ?? 1,
    );
  }

  /// ReklamModel'den Map oluştur
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reklamAdi': reklamAdi,
      'reklamBasligi': reklamBasligi,
      'reklamAciklamasi': reklamAciklamasi,
      'reklamResmi': reklamResmi,
      'reklamKodu': reklamKodu,
      'reklamKategorisi': reklamKategorisi,
      'durum': durum,
      'baslangicTarihi': baslangicTarihi?.toIso8601String(),
      'bitisTarihi': bitisTarihi?.toIso8601String(),
      'hedefUrl': hedefUrl,
      'tiklanmaSayisi': tiklanmaSayisi,
      'gosterimSayisi': gosterimSayisi,
      'maksimumButce': maksimumButce,
      'harcananButce': harcananButce,
      'olusturulmaTarihi': olusturulmaTarihi.toIso8601String(),
      'guncellenmeTarihi': guncellenmeTarihi.toIso8601String(),
      'olusturanKullaniciId': olusturanKullaniciId,
      'hedefKitlesi': hedefKitlesi,
      'priority': priority,
    };
  }

  /// Reklamın aktif olup olmadığını kontrol et
  bool get isActive {
    if (durum != 'aktif') return false;
    final now = DateTime.now();
    if (baslangicTarihi != null && now.isBefore(baslangicTarihi!)) return false;
    if (bitisTarihi != null && now.isAfter(bitisTarihi!)) return false;
    return true;
  }

  /// Reklamın süresinin dolup dolmadığını kontrol et
  bool get isExpired {
    if (bitisTarihi == null) return false;
    return DateTime.now().isAfter(bitisTarihi!);
  }

  /// Kopyalama metodu
  ReklamModel copyWith({
    String? id,
    String? reklamAdi,
    String? reklamBasligi,
    String? reklamAciklamasi,
    String? reklamResmi,
    String? reklamKodu,
    String? reklamKategorisi,
    String? durum,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    String? hedefUrl,
    int? tiklanmaSayisi,
    int? gosterimSayisi,
    double? maksimumButce,
    double? harcananButce,
    DateTime? olusturulmaTarihi,
    DateTime? guncellenmeTarihi,
    String? olusturanKullaniciId,
    Map<String, dynamic>? hedefKitlesi,
    int? priority,
  }) {
    return ReklamModel(
      id: id ?? this.id,
      reklamAdi: reklamAdi ?? this.reklamAdi,
      reklamBasligi: reklamBasligi ?? this.reklamBasligi,
      reklamAciklamasi: reklamAciklamasi ?? this.reklamAciklamasi,
      reklamResmi: reklamResmi ?? this.reklamResmi,
      reklamKodu: reklamKodu ?? this.reklamKodu,
      reklamKategorisi: reklamKategorisi ?? this.reklamKategorisi,
      durum: durum ?? this.durum,
      baslangicTarihi: baslangicTarihi ?? this.baslangicTarihi,
      bitisTarihi: bitisTarihi ?? this.bitisTarihi,
      hedefUrl: hedefUrl ?? this.hedefUrl,
      tiklanmaSayisi: tiklanmaSayisi ?? this.tiklanmaSayisi,
      gosterimSayisi: gosterimSayisi ?? this.gosterimSayisi,
      maksimumButce: maksimumButce ?? this.maksimumButce,
      harcananButce: harcananButce ?? this.harcananButce,
      olusturulmaTarihi: olusturulmaTarihi ?? this.olusturulmaTarihi,
      guncellenmeTarihi: guncellenmeTarihi ?? this.guncellenmeTarihi,
      olusturanKullaniciId: olusturanKullaniciId ?? this.olusturanKullaniciId,
      hedefKitlesi: hedefKitlesi ?? this.hedefKitlesi,
      priority: priority ?? this.priority,
    );
  }
}

