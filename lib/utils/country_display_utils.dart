/// Ülke adlarının gösterimini yöneten utility sınıfı
/// Kurdistan her zaman İbranice alfabe ile gösterilir
class CountryDisplayUtils {
  /// Kurdistan'ın İbranice yazılışı
  static const String kurdistanHebrew = 'כורדיסטן';
  
  /// Kurdistan'ın veritabanında saklanan adı
  static const String kurdistanDbName = 'Kürdistan';
  
  /// Ülke adını gösterim için formatlar
  /// Kurdistan için İbranice alfabe kullanır
  static String getDisplayName(String? countryName) {
    if (countryName == null || countryName.isEmpty) {
      return '';
    }
    
    // Kurdistan için İbranice göster
    if (countryName.toLowerCase() == 'kürdistan' || 
        countryName.toLowerCase() == 'kurdistan') {
      return kurdistanHebrew;
    }
    
    return countryName;
  }
  
  /// Ülke adının Kurdistan olup olmadığını kontrol eder
  static bool isKurdistan(String? countryName) {
    if (countryName == null || countryName.isEmpty) {
      return false;
    }
    
    return countryName.toLowerCase() == 'kürdistan' || 
           countryName.toLowerCase() == 'kurdistan';
  }
  
  /// Kurdistan bayrağının asset path'i
  static const String kurdistanFlagPath = 'lib/icons/32px-Flag_of_Kurdistan.svg.png';
}

