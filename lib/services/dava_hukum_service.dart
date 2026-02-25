import 'hive_database_service.dart';

/// Dava hüküm servisi
/// 
/// 76 gün dolduğunda otomatik olarak hüküm hesaplar:
/// - Destek >= Kına ise → Başarılı
/// - Aksi halde → Başarısız
class DavaHukumService {
  /// 76 gün süresi (gün cinsinden)
  static const int hukumSuresiGun = 76;

  /// Dava açıldığında (acceptedAt) tarihinden itibaren 76 gün geçti mi kontrol et
  static bool isHukumSuresiDoldu(DateTime? acceptedAt) {
    if (acceptedAt == null) {
      return false;
    }
    
    final now = DateTime.now();
    final fark = now.difference(acceptedAt).inDays;
    
    return fark >= hukumSuresiGun;
  }

  /// Dava için kalan gün sayısını hesapla
  static int getKalanGunSayisi(DateTime? acceptedAt) {
    if (acceptedAt == null) {
      return hukumSuresiGun;
    }
    
    final now = DateTime.now();
    final fark = now.difference(acceptedAt).inDays;
    final kalan = hukumSuresiGun - fark;
    
    return kalan > 0 ? kalan : 0;
  }

  /// Dava için hüküm hesapla ve kaydet
  /// 
  /// Destek >= Kına ise → 'basarili'
  /// Aksi halde → 'basarisiz'
  static Future<Map<String, dynamic>?> calculateAndSaveHukum(String davaId) async {
    try {
      // Dava verilerini al
      final rawOpenedDava = HiveDatabaseService.getOpenedDavaById(davaId);
      final rawAcceptedDava = rawOpenedDava == null
          ? await HiveDatabaseService.getAcceptedDavaById(davaId)
          : null;
      final rawDavaData = rawOpenedDava ?? rawAcceptedDava;
      
      if (rawDavaData == null) {
        print('⚠️ Dava bulunamadı: $davaId');
        return null;
      }

      final Map<String, dynamic> davaData = Map<String, dynamic>.from(
        rawDavaData as Map,
      );

      // Zaten hüküm verilmişse tekrar hesaplama
      if (davaData['hukumSonucu'] != null && davaData['hukumTarihi'] != null) {
        print('ℹ️ Dava için zaten hüküm verilmiş: $davaId');
        return {
          'hukumSonucu': davaData['hukumSonucu'],
          'hukumTarihi': davaData['hukumTarihi'],
          'hukumAciklamasi': davaData['hukumAciklamasi'],
        };
      }

      // AcceptedAt tarihini al
      final acceptedAtStr = davaData['acceptedAt']?.toString();
      if (acceptedAtStr == null || acceptedAtStr.isEmpty) {
        print('⚠️ Dava için acceptedAt tarihi bulunamadı: $davaId');
        return null;
      }

      final acceptedAt = DateTime.tryParse(acceptedAtStr);
      if (acceptedAt == null) {
        print('⚠️ Dava için geçersiz acceptedAt tarihi: $davaId');
        return null;
      }

      // 76 gün doldu mu kontrol et
      if (!isHukumSuresiDoldu(acceptedAt)) {
        print('ℹ️ Dava için henüz 76 gün dolmadı: $davaId');
        return null;
      }

      // Destek ve Kına sayılarını al
      final stats = HiveDatabaseService.getDavaActionStats(davaId);
      final totalLikes = stats['totalLikes'] ?? 0;
      final totalDislikes = stats['totalDislikes'] ?? 0;

      // Hüküm hesapla
      final hukumSonucu = totalLikes >= totalDislikes ? 'basarili' : 'basarisiz';
      final hukumTarihi = DateTime.now();

      // Hüküm açıklaması oluştur
      final hukumAciklamasi = _generateHukumAciklamasi(
        hukumSonucu: hukumSonucu,
        totalLikes: totalLikes,
        totalDislikes: totalDislikes,
      );

      // Hüküm verisini kaydet
      final hukumVerisi = {
        'hukumSonucu': hukumSonucu,
        'hukumTarihi': hukumTarihi.toIso8601String(),
        'hukumAciklamasi': hukumAciklamasi,
        'totalLikes': totalLikes,
        'totalDislikes': totalDislikes,
      };

      // Dava verilerini güncelle
      final updatedDavaData = Map<String, dynamic>.from(davaData);
      updatedDavaData['hukumSonucu'] = hukumSonucu;
      updatedDavaData['hukumTarihi'] = hukumTarihi.toIso8601String();
      updatedDavaData['hukumAciklamasi'] = hukumAciklamasi;

      // Veritabanına kaydet
      await HiveDatabaseService.saveDavaHukumVerisi(davaId, hukumVerisi);
      
      // Açılmış davalar listesinde güncelle
      if ((davaData['isOpened'] ?? false) == true) {
        await HiveDatabaseService.updateOpenedDava(davaId, updatedDavaData);
      } else {
        await HiveDatabaseService.updateAcceptedDava(davaId, updatedDavaData);
      }

      print('✅ Hüküm hesaplandı ve kaydedildi: $davaId, sonuç: $hukumSonucu');
      
      return hukumVerisi;
    } catch (e) {
      print('❌ Hüküm hesaplanırken hata: $e');
      return null;
    }
  }

  /// Hüküm açıklaması oluştur
  static String _generateHukumAciklamasi({
    required String hukumSonucu,
    required int totalLikes,
    required int totalDislikes,
  }) {
    if (hukumSonucu == 'basarili') {
      return 'Dava başarılı olarak sonuçlandı. Destek sayısı ($totalLikes) kına sayısından ($totalDislikes) fazla veya eşit.';
    } else {
      return 'Dava başarısız olarak sonuçlandı. Kına sayısı ($totalDislikes) destek sayısından ($totalLikes) fazla.';
    }
  }

  /// Dava için hüküm verisini getir
  static Map<String, dynamic>? getDavaHukumVerisi(String davaId) {
    try {
      return HiveDatabaseService.getDavaHukumVerisi(davaId);
    } catch (e) {
      print('❌ Hüküm verisi alınırken hata: $e');
      return null;
    }
  }

  /// Tüm açılmış davalar için hüküm kontrolü yap ve gerekirse hesapla
  static Future<void> checkAndCalculateAllDavalarHukum() async {
    try {
      final openedDavalar = HiveDatabaseService.getOpenedDavalar();
      
      for (final dava in openedDavalar) {
        final davaId = dava['id']?.toString() ?? dava['davaId']?.toString() ?? '';
        if (davaId.isEmpty) continue;

        final acceptedAtStr = dava['acceptedAt']?.toString();
        if (acceptedAtStr == null || acceptedAtStr.isEmpty) continue;

        final acceptedAt = DateTime.tryParse(acceptedAtStr);
        if (acceptedAt == null) continue;

        // 76 gün dolduysa hüküm hesapla
        if (isHukumSuresiDoldu(acceptedAt)) {
          await calculateAndSaveHukum(davaId);
        }
      }
    } catch (e) {
      print('❌ Tüm davalar için hüküm kontrolü yapılırken hata: $e');
    }
  }
}

