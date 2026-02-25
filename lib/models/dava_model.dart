import 'package:hive/hive.dart';

part 'dava_model.g.dart';

@HiveType(typeId: 0)
class DavaModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String adi;

  @HiveField(2)
  String davali;

  @HiveField(3)
  String mevkii;

  @HiveField(4)
  String kalanSure;

  @HiveField(5)
  String profilResmi;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String kategori;

  @HiveField(8)
  String altKategori;

  @HiveField(9)
  String aciklama;

  @HiveField(10)
  int likeCount;

  @HiveField(11)
  int dislikeCount;

  @HiveField(12)
  int commentCount;

  @HiveField(13)
  bool isActive;

  @HiveField(14)
  String userId;

  @HiveField(15)
  String davaAdi; // Dava adı alanı eklendi

  @HiveField(16)
  String davaci; // Davacı bilgisi alanı eklendi

  @HiveField(17)
  bool isOpened; // Dava açıldı mı? alanı eklendi

  @HiveField(18)
  DateTime? acceptedAt; // Dava kabul edilme tarihi

  @HiveField(19)
  int? remainingHours; // Kalan süre (saat cinsinden, varsayılan 76 saat)

  @HiveField(20)
  String? hukumSonucu; // Hüküm sonucu: 'basarili' veya 'basarisiz'

  @HiveField(21)
  DateTime? hukumTarihi; // Hüküm verilme tarihi

  @HiveField(22)
  String? hukumAciklamasi; // Hüküm açıklaması/notu

  DavaModel({
    required this.id,
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    required this.createdAt,
    required this.kategori,
    required this.altKategori,
    required this.aciklama,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.commentCount = 0,
    this.isActive = true,
    required this.userId,
    this.davaAdi = '', // Varsayılan boş değer
    this.davaci = '', // Varsayılan boş değer
    this.isOpened = false, // Varsayılan false değer
    this.acceptedAt, // Kabul edilme tarihi
    this.remainingHours = 76, // Varsayılan 76 saat
    this.hukumSonucu, // Hüküm sonucu
    this.hukumTarihi, // Hüküm tarihi
    this.hukumAciklamasi, // Hüküm açıklaması
  });

  // JSON'dan model oluşturma
  factory DavaModel.fromJson(Map<String, dynamic> json) {
    return DavaModel(
      id: json['id'] ?? '',
      adi: json['adi'] ?? '',
      davali: json['davali'] ?? '',
      mevkii: json['mevkii'] ?? '',
      kalanSure: json['kalanSure'] ?? '',
      profilResmi: json['profilResmi'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      kategori: json['kategori'] ?? '',
      altKategori: json['altKategori'] ?? '',
      aciklama: json['aciklama'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      dislikeCount: json['dislikeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      userId: json['userId'] ?? '',
      davaAdi: json['davaAdi'] ?? '',
      davaci: json['davaci'] ?? '',
      isOpened: json['isOpened'] ?? false,
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      remainingHours: json['remainingHours'] ?? 76,
      hukumSonucu: json['hukumSonucu'],
      hukumTarihi: json['hukumTarihi'] != null ? DateTime.parse(json['hukumTarihi']) : null,
      hukumAciklamasi: json['hukumAciklamasi'],
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adi': adi,
      'davali': davali,
      'mevkii': mevkii,
      'kalanSure': kalanSure,
      'profilResmi': profilResmi,
      'createdAt': createdAt.toIso8601String(),
      'kategori': kategori,
      'altKategori': altKategori,
      'aciklama': aciklama,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'commentCount': commentCount,
      'isActive': isActive,
      'userId': userId,
      'davaAdi': davaAdi,
      'davaci': davaci,
      'isOpened': isOpened,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'remainingHours': remainingHours,
      'hukumSonucu': hukumSonucu,
      'hukumTarihi': hukumTarihi?.toIso8601String(),
      'hukumAciklamasi': hukumAciklamasi,
    };
  }

  // Kopyalama metodu
  DavaModel copyWith({
    String? id,
    String? adi,
    String? davali,
    String? mevkii,
    String? kalanSure,
    String? profilResmi,
    DateTime? createdAt,
    String? kategori,
    String? altKategori,
    String? aciklama,
    int? likeCount,
    int? dislikeCount,
    int? commentCount,
    bool? isActive,
    String? userId,
    String? davaAdi,
    String? davaci,
    bool? isOpened,
    DateTime? acceptedAt,
    int? remainingHours,
    String? hukumSonucu,
    DateTime? hukumTarihi,
    String? hukumAciklamasi,
  }) {
    return DavaModel(
      id: id ?? this.id,
      adi: adi ?? this.adi,
      davali: davali ?? this.davali,
      mevkii: mevkii ?? this.mevkii,
      kalanSure: kalanSure ?? this.kalanSure,
      profilResmi: profilResmi ?? this.profilResmi,
      createdAt: createdAt ?? this.createdAt,
      kategori: kategori ?? this.kategori,
      altKategori: altKategori ?? this.altKategori,
      aciklama: aciklama ?? this.aciklama,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      commentCount: commentCount ?? this.commentCount,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      davaAdi: davaAdi ?? this.davaAdi,
      davaci: davaci ?? this.davaci,
      isOpened: isOpened ?? this.isOpened,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      remainingHours: remainingHours ?? this.remainingHours,
      hukumSonucu: hukumSonucu ?? this.hukumSonucu,
      hukumTarihi: hukumTarihi ?? this.hukumTarihi,
      hukumAciklamasi: hukumAciklamasi ?? this.hukumAciklamasi,
    );
  }
} 