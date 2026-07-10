/// Hive / Map kayıtlarında kategori alanı için ortak okuma ve yazma.
String resolveDavaKategoriFromMap(Map<String, dynamic> map) {
  for (final key in ['kategori', 'davaKategorisi', 'davaKategori']) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

/// Kayıt tutarlılığı için her iki anahtarı da doldurur.
Map<String, dynamic> withDavaKategoriFields(
  Map<String, dynamic> map,
  String kategori,
) {
  final normalized = kategori.trim();
  return {
    ...map,
    'kategori': normalized,
    'davaKategorisi': normalized,
    'davaKategori': normalized,
  };
}
