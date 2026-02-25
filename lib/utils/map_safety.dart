/// Güvenli Map/List dönüştürücü yardımcıları
/// Var olan koda dokunmadan, dinamik kaynaklardan gelen verileri
/// `Map<String, dynamic>` ve `List<Map<String, dynamic>>` tiplerine
/// güvenle dönüştürmek için kullanılır.
library;

/// Dinamik değeri güvenle `Map<String, dynamic>`'e çevirir.
/// Dönüşüm başarısız olursa boş map döner.
Map<String, dynamic> asStringDynamicMap(dynamic value) {
  if (value == null) return <String, dynamic>{};
  // Zaten doğru türde ise kopyasını döndür
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  // Genel Map ise, anahtarları string'e çevir
  if (value is Map) {
    final Map<String, dynamic> result = <String, dynamic>{};
    value.forEach((key, val) {
      result[key?.toString() ?? ''] = val;
    });
    return result;
  }
  return <String, dynamic>{};
}

/// Dinamik listeyi güvenle `List<Map<String, dynamic>>`'e çevirir.
/// Map olmayan öğeler görmezden gelinir.
List<Map<String, dynamic>> asListOfStringDynamicMap(dynamic value) {
  if (value == null) return <Map<String, dynamic>>[];
  if (value is List) {
    return value
        .where((e) => e is Map || e is Map<String, dynamic>)
        .map((e) => asStringDynamicMap(e))
        .toList();
  }
  return <Map<String, dynamic>>[];
}


