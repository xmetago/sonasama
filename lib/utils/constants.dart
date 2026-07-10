/// Uygulama genelinde kullanılan sabitler.
/// Kategoriler: Hive ilk açılışta boşsa bu liste ile doldurulur.
/// İleride Hive üzerinden isim/icon güncellenebilir; bu liste referans ve varsayılan değerdir.

/// İlk kurulumda Hive'a yüklenecek 30 kategori (id, name, icon adı).
/// [icon] Material Icons adı (String); UI'da gerekirse IconData'ya eşlenebilir.
const List<Map<String, dynamic>> initialCategories = [
  {'id': 1, 'name': 'Kategorisiz', 'icon': 'category'},
  {'id': 2, 'name': 'Ünlü birine', 'icon': 'star'},
  {'id': 3, 'name': 'Vefasızlara', 'icon': 'heart_broken'},
  {'id': 4, 'name': 'Sevgiline', 'icon': 'favorite'},
  {'id': 5, 'name': 'Eşine', 'icon': 'people'},
  {'id': 6, 'name': 'Ailene', 'icon': 'family_restroom'},
  {'id': 7, 'name': 'Arkadaşlarına', 'icon': 'group'},
  {'id': 8, 'name': 'Zalimlere', 'icon': 'warning'},
  {'id': 9, 'name': 'Kadınlara', 'icon': 'person'},
  {'id': 10, 'name': 'Erkeklere', 'icon': 'person'},
  {'id': 11, 'name': 'Politikacılara', 'icon': 'account_balance'},
  {'id': 12, 'name': 'Patronlara', 'icon': 'work'},
  {'id': 13, 'name': 'Öğretmenlere', 'icon': 'school'},
  {'id': 14, 'name': 'Tanrıya', 'icon': 'church'},
  {'id': 15, 'name': 'Belediyelere', 'icon': 'apartment'},
  {'id': 16, 'name': 'Bankalara', 'icon': 'account_balance'},
  {'id': 17, 'name': 'Futbolculara', 'icon': 'sports_soccer'},
  {'id': 18, 'name': 'Takımlara', 'icon': 'groups'},
  {'id': 19, 'name': 'Hastaneler', 'icon': 'local_hospital'},
  {'id': 20, 'name': 'Doktorlar', 'icon': 'medical_services'},
  {'id': 21, 'name': 'Sosyal Medya', 'icon': 'share'},
  {'id': 22, 'name': 'Aşk', 'icon': 'favorite'},
  {'id': 23, 'name': 'Evlilik', 'icon': 'favorite'},
  {'id': 24, 'name': 'İş Arkadaşlarına', 'icon': 'badge'},
  {'id': 25, 'name': 'Mahkemeye', 'icon': 'gavel'},
  {'id': 26, 'name': 'Hayat', 'icon': 'eco'},
  {'id': 27, 'name': 'Kaygı', 'icon': 'psychology'},
  {'id': 28, 'name': 'Diziler', 'icon': 'movie'},
  {'id': 29, 'name': 'Arabalar', 'icon': 'directions_car'},
  {'id': 30, 'name': 'Belirsiz', 'icon': 'help_outline'},
];

/// Kategori seçiminde ikonun yanında gösterilecek 30 slogan (Whoboom ruhuna uygun).
const List<String> categorySlogans = [
  'Hükmünü ver; Adaleti sağla',
  'Haksızlıkları dile getiren site.',
  'Tamamen ücretsizdir cebinizden tek kuruş harcatmaz.',
  'Sıradan insanların, asil duruşudur.',
  'Artık ben yada sen yok; biz varız.',
  'Hiçbir çaresizlik kader değildir, sadece kabullenmedir.',
  'Whoboom direniş gücünüzdür.',
  'Whoboom adalete giden yolda bastırılmış gür sesinizdir.',
  'Whoboom sevmediklerini yargılamanı ve yargılatmanı sağlar.',
  'Hemen, şimdi adalet.',
  'Ve beklenen adalet geldi.',
  'Adaletsizlik bataklığını kurutmak için, adaletsizliğe uğrayanları destekleyin.',
  'Kamu vicdanının sesi oluyoruz.',
  'Artık kendinizide yargılayabilirsiniz.',
  'Whoboom: Dayanışmanın diğer adı.',
  'Dinci züppelere karşı dindar duruşunuzuz.',
  'Whoboom\'cu güçlüden korkma, bırak o senden korksun.',
  'Whoboom ile adalet artık parmaklarının ucunda.',
  'Susma, Whoboom\'da hakkını ara.',
  'Haksızlığa karşı Whoboom kalkanı.',
  'Senin sesin, Whoboom\'un gücü.',
  'Adalet terazisi Whoboom\'da dengelenir.',
  'Whoboom: Haklı olan kazanır.',
  'Yargıç sensin, Whoboom mahkemen.',
  'Whoboom\'da hüküm senin elinde.',
  'Gerçeğin peşinde, Whoboom\'un izinde.',
  'Whoboom ile haksızlık tarih olur.',
  'Topluluğun adaleti, Whoboom\'un garantisi.',
  'Whoboom\'da her ses duyulur.',
  'Bugün insanlık adına bir hüküm verdiniz mi?',
];

/// Kategori adına göre slogan döndürür (initialCategories sırasına göre).
String getSloganForCategory(String categoryName) {
  final nameLower = categoryName.toLowerCase();
  for (int i = 0; i < initialCategories.length; i++) {
    if ((initialCategories[i]['name'] as String).toLowerCase() == nameLower) {
      return categorySlogans[i];
    }
  }
  return categorySlogans.isNotEmpty ? categorySlogans[0] : '';
}
