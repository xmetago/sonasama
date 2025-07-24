/// Kategori verileri - Merkezi veri yönetimi için
class CategoryData {
  static const Map<String, List<String>> categories = {
    'İlişkiler': ['Sevgiline', 'Eşine', 'Ailene', 'Arkadaşlarına', 'Vefasızlara', 'Zalimlere'],
    'Aşk & Kadın': ['Kadınlara', 'Boşanma', 'Aşk', 'Evlilik', 'İlişki', 'Cinsellik'],
    'Erkeklere Özel': ['Erkeklere', 'Kıskançlığa', 'Anlayışsızlara'],
    'Spor & Taraftarlık': ['Futbolculara', 'Takımlara', 'Hakemlere', 'Kulüplere'],
    'Siyasi': ['Politikacılara', 'Siyasi Partilere', 'Devletlere'],
    'Kurumlar': ['Belediyelere', 'Bankalara', 'Özel Kuruluşlara', 'Kamu Kurumlarına', 'Ev Sahiplerine'],
    'Dini & İnanç': ['Tanrıya', 'Şeytana', 'Dini Liderlere', 'Cemaatlere', 'Kadere'],
    'İş & Patron': ['Patronlara', 'İş Arkadaşlarına', 'Yöneticilere', 'İşyeri Koşulları'],
    'Eğitim': ['Öğretmenlere', 'Öğrencilere', 'Okullara', 'Eğitim Sistemi','Sınav Sistemine', 'Zor Sorulara', 'Sonuçlara'],
    'Alışveriş': ['Marketlere', 'Mağazalara', 'Online Sitelere', 'Kargo Şirketlerine', 'Gıda'],
    'Felsefi & Düşünsel': ['Hayat', 'Ölüm', 'Varoluş', 'Anlam Arayışı', 'Fikirlere'],
    'Psikolojik': ['Kaygı', 'Anksiyete', 'Tembellik', 'Uyuyamama', 'Aşırı Düşünme'],
    'Teknoloji': ['Sosyal Medya', 'Web Siteleri', 'Reklamlar', 'Uygulamalar', 'Yapay Zeka'],
    'Sanat & Medya': ['Diziler', 'Filmler', 'Yazarlara', 'Sanatçılara', 'Kitap & Dergi', 'Moda & Magazin'],
    'Otomobil': ['Arabalar', 'Sürücüler', 'Trafik Canavarları', 'Markalar'],
    'Sağlık': ['Hastaneler', 'Doktorlar', 'Sağlık Sistemi'],
    'Hukuk & Adalet': ['Mahkemeye', 'Dava Sonucuna', 'Avukatlara'],
    'İlginç & Alakasız': ['Saçma ve Komik Şeyler', 'Tuhaf Deneyimler', 'Garip Tesadüfler'],
    'Kategori Yok': ['Belirsiz', 'Kararsızım'],
  };

  /// Toplam kategori sayısını döndürür
  static int get totalCategories => categories.length;

  /// Toplam alt kategori sayısını döndürür
  static int get totalSubCategories => 
      categories.values.expand((x) => x).length;

  /// Arama sorgusuna göre kategorileri filtreler
  static List<String> filterCategories(String query) {
    if (query.isEmpty) {
      return categories.keys.toList();
    }
    return categories.keys
        .where((category) =>
            category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Belirli bir kategorinin alt kategorilerini döndürür
  static List<String> getSubCategories(String category) {
    return categories[category] ?? [];
  }
} 