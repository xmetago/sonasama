import '../models/dava_model.dart';
import '../models/dava.dart';

/// Dava ve DavaModel'i Map<String, dynamic> formatına çeviren adapter fonksiyonları
/// Bu sayede farklı veri tipleriyle çalışan widget'lar aynı formatta veri alabilir
class DavaAdapter {
  /// DavaModel'i Map<String, dynamic>'e çevir
  static Map<String, dynamic> toDavaMap(DavaModel model) {
    return {
      'id': model.id,
      'adi': model.adi,
      'davaAdi': model.davaAdi,
      'davaci': model.davaci,
      'davali': model.davali,
      'mevkii': model.mevkii,
      'kalanSure': model.kalanSure,
      'profilResmi': model.profilResmi,
      'createdAt': model.createdAt.toIso8601String(),
      'acceptedAt': model.acceptedAt?.toIso8601String(),
      'kategori': model.kategori,
      'altKategori': model.altKategori,
      'aciklama': model.aciklama,
      'likeCount': model.likeCount,
      'dislikeCount': model.dislikeCount,
      'commentCount': model.commentCount,
      'isActive': model.isActive,
      'userId': model.userId,
      'isOpened': model.isOpened,
      'remainingHours': model.remainingHours,
    };
  }

  /// Dava (basit class) objesini Map<String, dynamic>'e çevir
  static Map<String, dynamic> toDavaMapFromDava(Dava dava) {
    return {
      'id': dava.id,
      'adi': dava.davaAdi,
      'davaAdi': dava.davaAdi,
      'davaci': dava.davaci,
      'davali': dava.davali,
      'mevkii': dava.mevkii,
      'kalanSure': dava.kalanSure,
      'profilResmi': dava.profilResmi,
      'davaKonusu': dava.davaKonusu,
      'isOpened': dava.isOpened,
      // Dava class'ında olmayan alanlar için varsayılan değerler
      'createdAt': DateTime.now().toIso8601String(),
      'kategori': '',
      'altKategori': '',
      'aciklama': '',
      'likeCount': 0,
      'dislikeCount': 0,
      'commentCount': 0,
      'isActive': true,
      'userId': '',
      'remainingHours': 76,
    };
  }

  /// Map<String, dynamic>'i Dava objesine çevir
  static Dava toDavaFromMap(Map<String, dynamic> map) {
    return Dava(
      id: map['id']?.toString() ?? '',
      davaAdi: map['davaAdi']?.toString() ?? map['adi']?.toString() ?? '',
      kategori: map['kategori']?.toString() ?? '',
      davaci: map['davaci']?.toString() ?? '',
      davali: map['davali']?.toString() ?? '',
      mevkii: map['mevkii']?.toString() ?? '',
      kalanSure: map['kalanSure']?.toString() ?? '',
      profilResmi: map['profilResmi']?.toString() ?? 'lib/icons/03_davala_ana_icon.png',
      davaKonusu: map['davaKonusu']?.toString() ?? map['aciklama']?.toString() ?? '',
      isOpened: map['isOpened'] == true,
    );
  }
}

