import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../services/hive_database_service.dart';
import '../services/ad_service.dart';
import '../providers/dava_provider.dart';
import 'gelen_davalar_page.dart';
import 'yargila_page.dart';
import 'katildigim_davalar_page.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'haykir_page.dart';
import 'trend_insights_page.dart';

/// Masraf Seçim Sayfası
/// 
/// HTML yapısına benzer şekilde:
/// - Kategori seçimi (çift tıklama ile)
/// - Maksimum 10 masraf kuralı (FIFO mantığı)
/// - Seçilen masraflar listesi
/// - MASRAFLA ve İPTAL butonları
class MasrafSelectionPage extends StatefulWidget {
  final String? userEmail;
  final String? davaId;
  final String? davaAdi;

  const MasrafSelectionPage({
    super.key,
    this.userEmail,
    this.davaId,
    this.davaAdi,
  });

  @override
  State<MasrafSelectionPage> createState() => _MasrafSelectionPageState();
}

class _MasrafSelectionPageState extends State<MasrafSelectionPage> {
  int _current = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();
  
  // Seçilen masraflar listesi (maksimum 10) - kategori objesi olarak tutulacak
  final List<Map<String, dynamic>> _selectedExpenses = [];
  
  // Aktif kategori sekmesi
  int _currentCategoryTab = 0;
  
  // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
  bool showLeftIcons = false;
  
  // Reklam verileri
  List<Map<String, dynamic>> _instaAdData = <Map<String, dynamic>>[];
  
  // Filtrelenmiş kategoriler (cache)
  List<Map<String, dynamic>> _filteredCategories = <Map<String, dynamic>>[];

  // Ana Kategoriler ve Alt Kategoriler
  final List<Map<String, dynamic>> _mainCategories = [
    {'id': 0, 'name': 'TUTULANLAR', 'icon': MdiIcons.lock, 'subcategories': []},
    {'id': 1, 'name': 'OTOMOTİV', 'icon': MdiIcons.car, 'subcategories': [
      'Binek Otomobil', 'Motosiklet', 'Ticari Araçlar', 'Kamyon & Ağır Vasıta', 'ATV & UTV',
      'Orijinal Ekipman (OEM)', 'Yedek Parça', 'Lastik & Jant', 'Akü & Pil',
      'İç & Dış Aksesuarlar', 'Performans Parçaları', 'Elektronik Aksesuarlar',
      'Yeni Araç Satış', 'İkinci El Araç Satış', 'Kiralama (Leasing & Rent a Car)', 'Oto Kiralama',
      'Servis & Bakım', 'Oto Yıkama & Detay', 'Oto Elektrik & Oto Döşeme',
      'Benzin', 'Dizel', 'LPG', 'Elektrikli Araç Şarj İstasyonları', 'Hibrit Teknolojileri',
      'Oto Finansmanı & Sigorta', 'Motorsporları', 'Teknik Oto Bilgileri'
    ]},
    {'id': 2, 'name': 'İŞ DÜNYASI & ENDÜSTRİ', 'icon': MdiIcons.briefcase, 'subcategories': [
      'İmalat', 'İnşaat', 'Madencilik', 'Enerji', 'Lojistik & Taşımacılık', 'Tarım & Hayvancılık', 'Kimya & İlaç Sanayi',
      'Danışmanlık (Yönetim, BT, İnsan Kaynakları)', 'Muhasebe & Finansal Danışmanlık', 'Hukuki Hizmetler',
      'Pazarlama & Reklamcılık', 'Ofis Kiralama & Yönetimi', 'Güvenlik Hizmetleri',
      'Makine & Ekipman', 'Hammaddeler', 'Sanayi Malzemeleri', 'Elektrikli Ekipmanlar', 'Alet & Edevat',
      'Tedarikçi Yönetimi', 'Satın Alma', 'Depolama Çözümleri'
    ]},
    {'id': 3, 'name': 'EĞLENCE & KÜLTÜR', 'icon': MdiIcons.theater, 'subcategories': [
      'Gişe Filmleri', 'Bağımsız Filmler', 'Film İncelemeleri', 'Fragmanlar', 'Sinema Salonları',
      'Albüm & Single', 'Konser & Canlı Performans', 'Müzik Akışı (Streaming)', 'Enstrümanlar',
      'Müzik Türleri (Pop, Rock, Klasik, Hip-Hop vb.)',
      'Tiyatro', 'Opera', 'Bale', 'Müzeler & Galeriler', 'Sergiler', 'Sanat Festivalleri', 'Edebiyat & Kitaplar',
      'Gece Kulüpleri', 'Barlar', 'Komedi Kulüpleri', 'Konser Mekanları',
      'Video Oyunları', 'Board Games (Masaüstü Oyunlar)', 'Escape Roomlar'
    ]},
    {'id': 4, 'name': 'AİLE & EBEVEYNLİK', 'icon': MdiIcons.accountGroup, 'subcategories': [
      'Doğum Öncesi Bakım', 'Doğum Hazırlığı', 'Bebek Bekliyorum Ürünleri',
      'Bebek Bezi', 'Mama', 'Biberon', 'Emzirme Ürünleri', 'Bebek Odası Mobilyaları',
      'Oyuncaklar', 'Çocuk Giysileri', 'Eğitici Aktiviteler', 'Çocuk Bakıcılığı Hizmetleri',
      'Ebeveynlik Blogları', 'Çocuk Gelişimi', 'Aile Sağlığı', 'Aile Tatilleri',
      'Eğitim Desteği', 'Ergen Sağlığı', 'Sosyal Gelişim'
    ]},
    {'id': 5, 'name': 'YEMEK & İÇECEK', 'icon': MdiIcons.foodOutline, 'subcategories': [
      'Et & Kümes Hayvanları', 'Sebze & Meyve', 'Süt Ürünleri', 'Unlu Mamüller', 'Dondurulmuş Gıdalar',
      'Organik & Doğal Gıdalar', 'Vejetaryen & Vegan Ürünler',
      'Alkollü İçecekler (Bira, Şarap, Viski vb.)', 'Alkolsüz İçecekler (Su, Meyve Suyu, Gazoz, Enerji İçecekleri)',
      'Sıcak İçecekler (Kahve, Çay)',
      'Yemek Tarifleri', 'Mutfak Ekipmanları', 'Restoran İncelemeleri', 'Yemek Pişirme Teknikleri', 'Yemek Dağıtım Hizmetleri',
      'Kilo Yönetimi', 'Sporcu Beslenmesi', 'Alerji Dostu Gıdalar', 'Besin Takviyeleri'
    ]},
    {'id': 6, 'name': 'SAĞLIK & ZİNDELİK', 'icon': MdiIcons.medicalBag, 'subcategories': [
      'Hastaneler', 'Klinikler', 'Doktorlar (Tüm Branşlar)', 'Diş Hekimliği', 'Psikiyatri & Psikoloji',
      'Reçeteli İlaçlar', 'Reçetesiz İlaçlar', 'Bitkisel Ürünler & Takviyeler', 'Aşılar',
      'Spor Salonları', 'Fitness Ekipmanları', 'Kişisel Antrenörler', 'Spor Giysileri & Ayakkabılar',
      'Spor Türleri (Koşu, Yoga, Yüzme, Fitness vb.)',
      'Meditasyon', 'Mindfulness', 'Terapi', 'Stres Yönetimi', 'Kişisel Gelişim',
      'Kozmetik Dermatoloji', 'Estetik Cerrahi', 'Medikal Estetik Uygulamalar',
      'Diyet Programları', 'Detoks', 'Uyku Düzeni', 'Kronik Hastalık Yönetimi'
    ]},
    {'id': 7, 'name': 'EV & BAHÇE', 'icon': MdiIcons.home, 'subcategories': [
      'Oturma Odası', 'Yatak Odası', 'Mutfak & Yemek Odası', 'Ofis Mobilyaları', 'Aydınlatma',
      'Halı & Kilim', 'Duvar Dekorasyonu',
      'Büyük Beyaz Eşyalar (Buzdolabı, Çamaşır Makinesi)', 'Küçük Ev Aletleri (Süpürge, Kahve Makinesi)',
      'Bahçe Mobilyaları', 'Bahçe Aletleri', 'Bitkiler & Tohumlar', 'Barbekü & Açık Mutfak', 'Yüzme Havuzları',
      'Boya & Malzeme', 'Elektrik & Aydınlatma', 'Tesisat & Su Tesisatı', 'El Aletleri', 'Güvenlik Sistemleri',
      'Temizlik Ürünleri', 'Çamaşır & Bulaşık Ürünleri', 'Havalandırma & Nem Alma'
    ]},
    {'id': 8, 'name': 'MEDYA & YAYINCILIK', 'icon': MdiIcons.newspaper, 'subcategories': [
      'Gazeteler', 'Haber Dergileri', 'Çevrimiçi Haber Portalları', 'Yerel Haberler',
      'Süreli Yayınlar (Moda, Teknoloji, Spor, İş Dünyası vb.)',
      'Yayınevleri', 'Online Kitapçılar', 'E-Kitaplar', 'Sesli Kitaplar',
      'Niş Blog Yazarlığı', 'Kişisel Günlükler', 'İçerik Oluşturucular (Content Creator)'
    ]},
    {'id': 9, 'name': 'MODA & AKSESUAR', 'icon': MdiIcons.tshirtCrewOutline, 'subcategories': [
      'Kadın Giyim', 'Erkek Giyim', 'Çocuk Giyim', 'İç Giyim', 'Spor Giyim', 'Abiye & Gece Kıyafetleri',
      'Günlük Ayakkabı', 'Spor Ayakkabı', 'Topuklu Ayakkabı', 'Bot & Çizme',
      'Çanta', 'Cüzdan', 'Saat', 'Takı (Mücevher & Bijuteri)', 'Gözlük & Güneş Gözlüğü', 'Şapka & Bere',
      'Makyaj Ürünleri', 'Cilt Bakımı', 'Saç Bakımı', 'Parfüm & Deodorant', 'Erkek Bakım Ürünleri',
      'Tasarım Markaları', 'Yüksek Kaliteli Deri Ürünler', 'Saat & Mücevherat'
    ]},
    {'id': 10, 'name': 'SEYAHAT & TURİZM', 'icon': MdiIcons.airplane, 'subcategories': [
      'Oteller', 'Tatil Köyleri', 'Pansiyonlar (B&B)', 'Kiralık Ev & Daire (Airbnb vb.)', 'Hosteller',
      'Uçak Bileti', 'Otobüs Bileti', 'Tren Bileti', 'Araç Kiralama (Rent a Car)', 'Feribot & Kruvaziyer',
      'Seyahat Acenteleri', 'Tur Rehberleri', 'Tur Paketleri', 'Vize Hizmetleri', 'Seyahat Sigortası',
      'Yerli Turizm', 'Yurt Dışı Turizm', 'Şehir Turları', 'Doğa Turizmi', 'Kültür Turizmi',
      'Bavul & Valiz', 'Seyahat Aksesuarları', 'Kamp Malzemeleri'
    ]},
    {'id': 11, 'name': 'SPOR', 'icon': MdiIcons.dumbbell, 'subcategories': [
      'Futbol', 'Basketbol', 'Voleybol', 'Tenis', 'Yüzme', 'Atletizm', 'Golf', 'Amerikan Futbolu', 'Ragbi',
      'Buz Hokeyi', 'Kayak', 'Snowboard', 'Dalış', 'Bisiklet', 'Motor Sporları',
      'Olimpiyat Oyunları', 'Dünya Kupaları', 'Ligler', 'Şampiyonalar',
      'Toplar', 'Raketler', 'Kasklar', 'Koruyucu Ekipmanlar', 'Spor Giysileri',
      'Takım Formalaları', 'Taraftar Ürünleri', 'Biletler'
    ]},
    {'id': 12, 'name': 'TEKNOLOJİ & ELEKTRONİK', 'icon': MdiIcons.laptop, 'subcategories': [
      'Bilgisayarlar (Dizüstü, Masaüstü)', 'Tabletler', 'Akıllı Telefonlar', 'Yazıcılar', 'Monitörler',
      'Bileşenler (Anakart, İşlemci, Ekran Kartı)',
      'İşletim Sistemleri', 'Ofis Yazılımları', 'Güvenlik Yazılımları', 'Oyun Yazılımları', 'Mobil Uygulamalar',
      'Klavye', 'Fare', 'Hoparlör', 'Kulaklık', 'Web Kamerası',
      'Oyun Konsolları', 'Oyun Bilgisayarları', 'Oyun Yazılımları', 'Oyun Aksesuarları',
      'Wi-Fi Yönlendiriciler', 'Ağ Güvenliği', 'İnternet Servis Sağlayıcıları (ISP\'ler)',
      'Akıllı Hoparlörler', 'Akıllı Aydınlatma', 'Akıllı Termostatlar', 'Güvenlik Kameraları'
    ]},
    {'id': 13, 'name': 'TELEKOMÜNİKASYON', 'icon': MdiIcons.phoneOutline, 'subcategories': [
      'Sabit Hat Telefon', 'Genişbant İnternet', 'Kablolu TV',
      'Cep Telefonu Operatörleri', 'Kablosuz İnternet Paketleri', '5G Hizmetleri',
      'Bulut Telefoni', 'VPN Hizmetleri', 'Veri Merkezi Çözümleri'
    ]},
    {'id': 14, 'name': 'EĞİTİM', 'icon': MdiIcons.school, 'subcategories': [
      'İlköğretim', 'Ortaöğretim', 'Liseler', 'Üniversiteler', 'Yüksek Lisans & Doktora',
      'Sertifika Programları', 'Meslek Kursları', 'Teknik Eğitimler',
      'Uzaktan Eğitim Platformları', 'MOOC\'lar (Kitlesel Açık Çevrimiçi Dersler)', 'Webinar\'lar', 'Dil Öğrenme Uygulamaları',
      'Özel Ders Hizmetleri', 'Öğrenci Koçluğu', 'Sınav Hazırlık Kursları (LGS, YKS, SAT, GRE vb.)',
      'Ders Kitapları', 'Kırtasiye Ürünleri', 'Eğitim Yazılımları'
    ]},
    {'id': 15, 'name': 'FİNANS & BANKACILIK', 'icon': MdiIcons.wallet, 'subcategories': [
      'Mevduat Hesapları', 'Kredi Kartları', 'Bireysel Krediler', 'Konut Kredileri', 'İnternet & Mobil Bankacılık',
      'Hisse Senedi', 'Tahvil', 'Yatırım Fonları', 'Emeklilik Planları (BES)', 'Forex', 'Kripto Para',
      'Sağlık Sigortası', 'Araç Sigortası', 'Konut Sigortası', 'Hayat Sigortası', 'Seyahat Sigortası',
      'Emeklilik Planlaması', 'Vergi Planlaması', 'Varlık Yönetimi',
      'Dijital Cüzdanlar', 'Ödeme Sistemleri (POS, Online Ödeme)', 'Havale & EFT'
    ]},
    {'id': 16, 'name': 'EMLAK & GAYRİMENKUL', 'icon': MdiIcons.city, 'subcategories': [
      'Daire', 'Müstakil Ev', 'Villa', 'Yazlık', 'Stüdyo',
      'Ofis', 'Mağaza', 'Depo', 'Fabrika', 'Plaza',
      'Emlak Danışmanlığı', 'Emlak Yatırım Ortaklığı (REIT)', 'Kiralık & Satılık İlan Portalları', 'Ev Değerleme', 'Taşınma & Nakliye Hizmetleri',
      'Yeni Konut Projeleri', 'Tadilat & Yenileme', 'Mimar & Mühendis Hizmetleri'
    ]},
    {'id': 17, 'name': 'ALIŞVERİŞ', 'icon': MdiIcons.cart, 'subcategories': [
      'Giyim Mağazaları', 'Elektronik Mağazaları', 'Ev Eşyası Mağazaları', 'Kitapçılar', 'Oyuncak Mağazaları',
      'Online Market Alışverişi', 'Giyim Siteleri', 'Elektronik Siteleri', 'Pazar Yerleri (Amazon, Trendyol, n11 vb.)',
      'Doğum Günü', 'Yıl Dönümü', 'Düğün', 'Anneler/Günler Babalar Günü', 'Özel Tasarım Ürünler',
      'Günlük Fırsat Siteleri', 'Kupon & İndirim Kodları', 'Outlet Alışverişi'
    ]},
    {'id': 18, 'name': 'TOPLUM & KAMU', 'icon': MdiIcons.accountGroup, 'subcategories': [
      'Dernekler', 'Vakıflar', 'Hayır Kurumları',
      'Siyasi Partiler', 'Devlet Kurumları', 'Yerel Yönetimler', 'Seçimler',
      'Dini Kurumlar', 'Dini Yayınlar', 'Dini Günler ve Bayramlar',
      'Çevrecilik', 'Hayvan Hakları', 'Kadın Hakları', 'Engelli Hakları', 'Göçmen & Mülteci Hakları'
    ]},
    {'id': 19, 'name': 'KİŞİSEL HİZMETLER & İŞLETMELER', 'icon': MdiIcons.accountTie, 'subcategories': [
      'Grafikerler', 'Yazılımcılar', 'Fotoğrafçılar', 'Çevirmenler', 'Avukatlar', 'Muhasebeciler',
      'Kuaför & Güzellik Salonu', 'Berber', 'Temizlikçi', 'Özel Şoför', 'Kişisel Asistanlık', 'Evcil Hayvan Bakımı',
      'Düğün Organizasyonu', 'Konferans & Toplantı Organizasyonu', 'Catering Hizmetleri', 'DJ & Müzik Hizmetleri'
    ]},
    {'id': 20, 'name': 'HOBİLER & İLGİ ALANLARI', 'icon': MdiIcons.palette, 'subcategories': [
      'Fotoğrafçılık', 'Resim & Çizim', 'Müzik Aleti Çalma', 'El Sanatları', 'Dikiş & Nakış', 'Model Yapımı',
      'Pul', 'Para', 'Sanat Eserleri', 'Antika Eşyalar', 'Vinil Plak',
      'Balıkçılık', 'Avcılık', 'Kampçılık', 'Doğa Yürüyüşü', 'Dağcılık',
      'Köpek', 'Kedi', 'Kuş', 'Balık', 'Evcil Hayvan Mamaları', 'Veteriner Hizmetleri', 'Eğitim & Oyunca'
    ]},
    {'id': 21, 'name': 'İŞ KARİYER & KURUMSAL YAŞAM', 'icon': MdiIcons.briefcaseOutline, 'subcategories': [
      'İş Arama Platformları', 'Kariyer Fuarları', 'CV Hazırlama Hizmetleri', 'Mülakat Simülasyonları',
      'Ofis Malzemeleri', 'İş Kıyafetleri', 'Toplantı & Sunum Ekipmanları',
      'Mühendislik', 'Pazarlama', 'İnsan Kaynakları', 'Finans', 'Teknoloji', 'Sağlık'
    ]},
    {'id': 22, 'name': 'DİĞER', 'icon': MdiIcons.tagOff, 'subcategories': []},
  ];

  @override
  void initState() {
    super.initState();
    _loadReklamlar();
    _loadSavedExpenses();
    _refreshFilteredCategories();
  }
  
  /// Filtrelenmiş kategorileri yenile
  Future<void> _refreshFilteredCategories() async {
    final filtered = await _getFilteredCategories();
    if (mounted) {
      setState(() {
        _filteredCategories = filtered;
      });
    }
  }

  /// Reklamları Hive'dan yükle (varsayılan - tüm reklamlar)
  Future<void> _loadReklamlar() async {
    try {
      // Tüm aktif reklamları getir
      final allReklamlar = await HiveDatabaseService.getAllActiveReklamlar();
      
      // Kullanıcının tutulan reklamlarını getir
      List<String> tutulanReklamIds = [];
      if (widget.userEmail != null) {
        tutulanReklamIds = await HiveDatabaseService.getTutulanReklamlar(widget.userEmail!);
      }
      
      // Tutulan reklamları önce ekle, sonra diğerlerini karıştır
      final List<Map<String, dynamic>> reklamList = [];
      
      // Önce tutulan reklamları ekle
      for (final reklamId in tutulanReklamIds) {
        final reklam = allReklamlar.firstWhere(
          (r) => r['id'] == reklamId,
          orElse: () => <String, dynamic>{},
        );
        if (reklam.isNotEmpty) {
          reklamList.add(reklam);
        }
      }
      
      // Sonra diğer reklamları ekle (tutulanlar hariç)
      for (final reklam in allReklamlar) {
        if (!tutulanReklamIds.contains(reklam['id'])) {
          reklamList.add(reklam);
        }
      }
      
      // Karıştır
      reklamList.shuffle();
      
      // AdService formatına çevir
      _instaAdData = reklamList.take(10).map((reklam) {
        return <String, dynamic>{
          'id': reklam['id'],
          'profileImage': 'https://via.placeholder.com/40?text=WB',
          'name': 'WhoBoom',
          'sponsoredText': 'Sponsorlu',
          'mainImage': reklam['reklamResmi'] as String? ?? 'https://via.placeholder.com/360x360',
          'buttonText': 'Detaylı İncele',
          'buttonUrl': reklam['hedefUrl'] as String? ?? 'https://whoboom.com',
          'caption': reklam['reklamAciklamasi'] as String? ?? '',
          'adTitle': reklam['reklamBasligi'] as String? ?? '',
          'adCode': reklam['reklamKodu'] as String? ?? '',
          'price': 'Hediye',
          'reklamKategorisi': reklam['reklamKategorisi'] as String? ?? 'DİĞER',
        };
      }).toList();
      
      // Gösterim sayısını artır
      for (final reklam in _instaAdData) {
        if (reklam['id'] != null) {
          await HiveDatabaseService.incrementReklamGosterim(reklam['id'] as String);
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Hata durumunda AdService'den fallback
      _instaAdData = AdService.I.getWeightedAdsAsMap(maxCount: 10).map((ad) {
        return <String, dynamic>{
          ...ad,
          'reklamKategorisi': 'DİĞER',
        };
      }).toList();
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Alt kategoriye ait reklamları yükle
  Future<void> _loadReklamlarForSubCategory(String subCategoryName, String parentCategoryName) async {
    try {
      // Önce ana kategoriye göre reklamları getir
      final kategoriReklamlar = await HiveDatabaseService.getReklamlarByKategori(parentCategoryName);
      
      // Alt kategori adına göre filtrele (reklam başlığı veya açıklamasında alt kategori adı geçiyorsa)
      final filteredReklamlar = kategoriReklamlar.where((reklam) {
        final baslik = (reklam['reklamBasligi'] as String? ?? '').toLowerCase();
        final aciklama = (reklam['reklamAciklamasi'] as String? ?? '').toLowerCase();
        final subCatLower = subCategoryName.toLowerCase();
        
        // Alt kategori adı reklam başlığında veya açıklamasında geçiyorsa
        return baslik.contains(subCatLower) || aciklama.contains(subCatLower);
      }).toList();
      
      List<Map<String, dynamic>> reklamList = [];
      
      if (filteredReklamlar.isNotEmpty) {
        // Alt kategoriye ait reklamlar var
        reklamList = filteredReklamlar;
      } else {
        // Alt kategoriye ait reklam yok, WhoBoom Premium reklamı oluştur
        final premiumReklam = _createPremiumReklam(subCategoryName, parentCategoryName);
        reklamList = [premiumReklam];
      }
      
      // AdService formatına çevir
      _instaAdData = reklamList.map((reklam) {
        final isPremium = reklam['isPremium'] == true;
        return <String, dynamic>{
          'id': reklam['id'],
          'profileImage': 'https://via.placeholder.com/40?text=WB',
          'name': 'WhoBoom',
          'sponsoredText': 'Sponsorlu',
          'mainImage': isPremium 
              ? 'lib/icons/14_MasrfalarAdvertsimentPic.png' // Premium reklamlar için uygulama resmi
              : (reklam['reklamResmi'] as String? ?? 'https://via.placeholder.com/360x360'),
          'buttonText': 'Detaylı İncele',
          'buttonUrl': reklam['hedefUrl'] as String? ?? 'https://whoboom.com/premium',
          'caption': reklam['reklamAciklamasi'] as String? ?? '',
          'adTitle': reklam['reklamBasligi'] as String? ?? '',
          'adCode': reklam['reklamKodu'] as String? ?? '',
          'price': 'Hediye',
          'reklamKategorisi': reklam['reklamKategorisi'] as String? ?? 'DİĞER',
          'isPremium': isPremium,
        };
      }).toList();
      
      // Gösterim sayısını artır (sadece gerçek reklamlar için)
      for (final reklam in _instaAdData) {
        if (reklam['id'] != null && reklam['isPremium'] != true) {
          await HiveDatabaseService.incrementReklamGosterim(reklam['id'] as String);
        }
      }
      
      // Carousel'i başa al
      _current = 0;
      if (_instaAdData.isNotEmpty) {
        _carouselController.animateToPage(0);
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Hata durumunda Premium reklam göster
      final premiumReklam = _createPremiumReklam(subCategoryName, parentCategoryName);
      _instaAdData = [premiumReklam].map((reklam) {
        return <String, dynamic>{
          'id': reklam['id'],
          'profileImage': 'https://via.placeholder.com/40?text=WB',
          'name': 'WhoBoom',
          'sponsoredText': 'Sponsorlu',
          'mainImage': 'lib/icons/14_MasrfalarAdvertsimentPic.png',
          'buttonText': 'Detaylı İncele',
          'buttonUrl': reklam['hedefUrl'] as String? ?? 'https://whoboom.com/premium',
          'caption': reklam['reklamAciklamasi'] as String? ?? '',
          'adTitle': reklam['reklamBasligi'] as String? ?? '',
          'adCode': reklam['reklamKodu'] as String? ?? '',
          'price': 'Hediye',
          'reklamKategorisi': reklam['reklamKategorisi'] as String? ?? 'DİĞER',
          'isPremium': true,
        };
      }).toList();
      
      _current = 0;
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// WhoBoom Premium reklamı oluştur
  Map<String, dynamic> _createPremiumReklam(String subCategoryName, String parentCategoryName) {
    final now = DateTime.now();
    final kategoriIcon = _getKategoriIcon(parentCategoryName);
    
    return {
      'id': 'premium_${subCategoryName}_${now.millisecondsSinceEpoch}',
      'reklamAdi': 'WhoBoom Premium Abonelik',
      'reklamBasligi': '$kategoriIcon $subCategoryName İçin Özel Hediye!',
      'reklamAciklamasi': 'WhoBoom Premium abonelik hediye et! $subCategoryName kategorisindeki özel avantajlardan yararlan.',
      'reklamResmi': 'lib/icons/14_MasrfalarAdvertsimentPic.png',
      'reklamKodu': 'WB-PREM-${subCategoryName.replaceAll(' ', '-')}',
      'reklamKategorisi': parentCategoryName,
      'durum': 'aktif',
      'baslangicTarihi': now.toIso8601String(),
      'bitisTarihi': now.add(const Duration(days: 365)).toIso8601String(),
      'hedefUrl': 'https://whoboom.com/premium',
      'tiklanmaSayisi': 0,
      'gosterimSayisi': 0,
      'maksimumButce': null,
      'harcananButce': 0.0,
      'olusturulmaTarihi': now.toIso8601String(),
      'guncellenmeTarihi': now.toIso8601String(),
      'olusturanKullaniciId': 'system',
      'hedefKitlesi': null,
      'priority': 1,
      'isPremium': true,
    };
  }

  /// Kategori ikonunu getir
  String _getKategoriIcon(String kategoriName) {
    // Icon'u emoji'ye çevir (basit bir mapping)
    final iconMap = {
      'OTOMOTİV': '🚗',
      'İŞ DÜNYASI & ENDÜSTRİ': '💼',
      'EĞLENCE & KÜLTÜR': '🎭',
      'AİLE & EBEVEYNLİK': '👨‍👩‍👧',
      'YEMEK & İÇECEK': '🍔',
      'SAĞLIK & ZİNDELİK': '🏥',
      'EV & BAHÇE': '🏠',
      'MEDYA & YAYINCILIK': '📰',
      'MODA & AKSESUAR': '👕',
      'SEYAHAT & TURİZM': '✈️',
      'SPOR': '⚽',
      'TEKNOLOJİ & ELEKTRONİK': '💻',
      'TELEKOMÜNİKASYON': '📱',
      'EĞİTİM': '🎓',
      'FİNANS & BANKACILIK': '💰',
      'EMLAK & GAYRİMENKUL': '🏢',
      'ALIŞVERİŞ': '🛒',
      'TOPLUM & KAMU': '👥',
      'KİŞİSEL HİZMETLER & İŞLETMELER': '👔',
      'HOBİLER & İLGİ ALANLARI': '🎨',
      'İŞ KARİYER & KURUMSAL YAŞAM': '💼',
      'DİĞER': '📌',
    };
    return iconMap[kategoriName] ?? '🎁';
  }

  /// Kaydedilmiş masrafları yükle
  Future<void> _loadSavedExpenses() async {
    if (widget.davaId == null || widget.userEmail == null) return;
    
    try {
      final List<String>? savedExpenses = await HiveDatabaseService.getMasrafExpenses(
        davaId: widget.davaId!,
        userEmail: widget.userEmail!,
      );
      
      if (mounted && savedExpenses != null) {
        setState(() {
          _selectedExpenses.clear();
          // String listesini kategori objelerine çevir
          for (final expenseName in savedExpenses) {
            // Önce ana kategorilerde ara
            bool found = false;
            for (final mainCat in _mainCategories) {
              if (mainCat['name'] == expenseName) {
                _selectedExpenses.add(mainCat);
                found = true;
                break;
              }
              // Alt kategorilerde ara
              final List<String> subcats = mainCat['subcategories'] as List<String>;
              if (subcats.contains(expenseName)) {
                _selectedExpenses.add({
                  'id': mainCat['id'],
                  'name': expenseName,
                  'icon': mainCat['icon'],
                  'parentName': mainCat['name'],
                });
                found = true;
                break;
              }
            }
            if (!found) {
              _selectedExpenses.add({'id': -1, 'name': expenseName, 'icon': MdiIcons.tagOff});
            }
          }
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  /// Masrafları kaydet
  Future<void> _saveExpenses() async {
    if (widget.davaId == null || widget.userEmail == null) return;
    
    try {
      // Kategori objelerini string listesine çevir
      final List<String> expenseNames = _selectedExpenses
          .map((exp) => exp['name'] as String)
          .toList();
      
      // Provider üzerinden kaydet (senkronizasyon için)
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      await davaProvider.updateMasrafForDava(
        davaId: widget.davaId!,
        userEmail: widget.userEmail!,
        masraflar: expenseNames,
      );
      print('✅ [MasrafSelectionPage] Masraf Provider üzerinden kaydedildi');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Veritabanına kaydediliyor...\n'
              '✅ Kalıcı olarak saklanıyor...\n'
              '✅ Uygulama yeniden başlatıldığında korunuyor...\n'
              'Masraflar başarıyla kaydedildi!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Masraflar kaydedilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToPrevious() {
    if (_current > 0) {
      _carouselController.previousPage();
    }
  }

  void _goToNext(int itemCount) {
    if (_current < itemCount - 1) {
      _carouselController.nextPage();
    }
  }

  /// Kategoriye tek tıklandığında masraf ekle/kaldır ve reklamları yükle
  void _onCategoryTap(Map<String, dynamic> category) {
    final String categoryName = category['name'] as String;
    final String? parentName = category['parentName'] as String?;
    
    // Alt kategori seçildiğinde (parentName varsa ve TUTULANLAR değilse)
    if (parentName != null && parentName != 'TUTULANLAR' && _currentCategoryTab != 0) {
      // Alt kategori seçildi, bu alt kategoriye ait reklamları yükle
      _loadReklamlarForSubCategory(categoryName, parentName);
    } else {
      // Normal kategori seçimi (masraf ekle/kaldır)
      setState(() {
        final int index = _selectedExpenses.indexWhere(
          (exp) => exp['name'] == categoryName,
        );
        
        if (index == -1) {
          // Kategori seçili değil, ekle (maksimum 10 masraf kuralı - FIFO)
          if (_selectedExpenses.length >= 10) {
            _selectedExpenses.removeAt(0); // İlk öğeyi kaldır
          }
          _selectedExpenses.add(category);
        } else {
          // Kategori zaten seçili, kaldır
          _selectedExpenses.removeAt(index);
        }
      });
    }
  }

  /// Masrafı listeden kaldır
  void _removeExpense(int index) {
    setState(() {
      _selectedExpenses.removeAt(index);
    });
  }

  /// Reklam seçildiğinde çağrılır (cartPlus tıklama)
  Future<void> _onReklamSelect() async {
    if (_instaAdData.isEmpty || _current >= _instaAdData.length) return;
    
    final currentReklam = _instaAdData[_current];
    final reklamId = currentReklam['id'] as String?;
    final reklamKategori = currentReklam['reklamKategorisi'] as String? ?? 'DİĞER';
    final reklamBasligi = currentReklam['adTitle'] as String? ?? 'Reklam';
    
    if (reklamId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reklam seçilemedi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Reklam tıklama sayısını artır
    await HiveDatabaseService.incrementReklamTiklama(reklamId);
    
    // Eğer kullanıcı varsa, tutulan reklamlarına ekle
    if (widget.userEmail != null) {
      await HiveDatabaseService.addTutulanReklam(widget.userEmail!, reklamId);
    }
    
    // Reklamı masraf listesine ekle (maksimum 10 masraf kuralı - FIFO)
    if (mounted) {
      setState(() {
        // Reklamı kategori formatına çevir
        final reklamExpense = {
          'id': -1, // Reklamlar için özel ID
          'name': reklamBasligi,
          'icon': MdiIcons.giftOpenOutline,
          'parentName': reklamKategori,
          'reklamId': reklamId,
          'isReklam': true,
        };
        
        // Aynı reklam zaten seçili mi kontrol et
        final existingIndex = _selectedExpenses.indexWhere(
          (exp) => exp['reklamId'] == reklamId,
        );
        
        if (existingIndex == -1) {
          // Kategori seçili değil, ekle (maksimum 10 masraf kuralı - FIFO)
          if (_selectedExpenses.length >= 10) {
            _selectedExpenses.removeAt(0); // İlk öğeyi kaldır
          }
          _selectedExpenses.add(reklamExpense);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $reklamBasligi masraf listesine eklendi'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu reklam zaten seçili'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  /// Aktif sekmeye göre filtrelenmiş kategorileri (alt kategoriler) döndürür
  Future<List<Map<String, dynamic>>> _getFilteredCategories() async {
    if (_currentCategoryTab == 0) {
      // TUTULANLAR sekmesi - tutulan reklamları ve ana kategorileri göster
      final List<Map<String, dynamic>> categories = [];
      
      // Önce tutulan reklamları ekle
      if (widget.userEmail != null) {
        final tutulanReklamIds = await HiveDatabaseService.getTutulanReklamlar(widget.userEmail!);
        for (final reklamId in tutulanReklamIds) {
          final reklam = await HiveDatabaseService.getReklam(reklamId);
          if (reklam != null && reklam['durum'] == 'aktif') {
            // Süre kontrolü
            final bitisTarihi = reklam['bitisTarihi'] as String?;
            if (bitisTarihi != null) {
              final bitis = DateTime.parse(bitisTarihi);
              if (DateTime.now().isAfter(bitis)) continue; // Süresi dolmuş
            }
            
            categories.add({
              'id': -1,
              'name': reklam['reklamBasligi'] as String? ?? 'Reklam',
              'icon': MdiIcons.giftOpenOutline,
              'parentName': 'TUTULANLAR',
              'reklamId': reklamId,
              'isReklam': true,
            });
          }
        }
      }
      
      // Sonra ana kategorileri ekle
      categories.addAll(_mainCategories);
      return categories;
    } else {
      // Diğer sekmeler - seçili ana kategorinin alt kategorilerini göster
      final mainCategory = _mainCategories.firstWhere(
        (cat) => cat['id'] == _currentCategoryTab,
        orElse: () => {'subcategories': <String>[], 'id': _currentCategoryTab, 'name': 'DİĞER', 'icon': MdiIcons.tagOff},
      );
      
      // Güvenli tip dönüşümü
      final dynamic subcategoriesRaw = mainCategory['subcategories'];
      final List<String> subcategories = subcategoriesRaw != null
          ? List<String>.from(subcategoriesRaw)
          : <String>[];
      
      // Eğer alt kategori yoksa, ana kategoriyi döndür
      if (subcategories.isEmpty) {
        return [mainCategory];
      }
      
      // Alt kategorileri kategori objesi formatına çevir
      return subcategories.map((subcatName) {
        return {
          'id': _currentCategoryTab,
          'name': subcatName,
          'icon': mainCategory['icon'],
          'parentName': mainCategory['name'],
        };
      }).toList();
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool canMasraf = _selectedExpenses.length == 10;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
              ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
              // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
              ),
              // ROW 3: Profil Bölümü
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                  userEmail: widget.userEmail,
                  onShowSavedDavalar: () {
                    // Masraf seçim sayfasında kaydedilen davalar dialog'u açılamaz
                  },
                ),
              ),
              // ROW 4: Hamburger Iconu ve Başlık
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'lib/icons/menu_red.png',
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          showLeftIcons = !showLeftIcons;
                        });
                      },
                    ),
                    const SizedBox(width: 68),
                    const Center(
                      child: Text(
                        'MASRAFLAR',
                        style: TextStyle(fontSize: 19),
                      ),
                    ),
                  ],
                ),
              ),
              // ROW 5: Sol ikonlar ve içerik
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Açılıp kapanan sol menü
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: showLeftIcons ? 60 : 0,
                      child: showLeftIcons
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GelenDavalarPage(userEmail: widget.userEmail),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
                                      child: Icon(
                                        MdiIcons.briefcaseArrowLeftRight,
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => YargilaPage(userEmail: widget.userEmail),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                      child: Image.asset(
                                        'lib/icons/06_yargila_left_row_icon.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => KatildigimDavalarPage(userEmail: widget.userEmail),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                      child: Image.asset(
                                        'lib/icons/06_left_row_katildigim_davalar_icon.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ActigimDavalarPage(userEmail: widget.userEmail),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                      child: Image.asset(
                                        'lib/icons/06_left_row_actigim_davalar_icon.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DavaciUnlulurPage(userEmail: widget.userEmail),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                      child: Image.asset(
                                        'lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HaykirPage(userEmail: widget.userEmail),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                      child: Image.asset(
                                        'lib/icons/06_left_row_haykirislarim.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                        builder: (context) => TrendInsightsPage(userEmail: widget.userEmail),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                      child: Icon(
                                        MdiIcons.trendingUp,
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          // Reklam Carousel
                          CarouselSlider(
                            carouselController: _carouselController,
                            options: CarouselOptions(
                              height: 566,
                              autoPlay: false,
                              enlargeCenterPage: true,
                              viewportFraction: 0.95,
                              scrollPhysics: const PageScrollPhysics(),
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _current = index;
                                });
                              },
                            ),
                            items: _instaAdData.map((ad) {
                              return _InstaAdCard(
                                profileImage: ad['profileImage']!,
                                name: ad['name']!,
                                sponsoredText: ad['sponsoredText']!,
                                mainImage: ad['mainImage']!,
                                buttonText: ad['buttonText']!,
                                buttonUrl: ad['buttonUrl']!,
                                caption: ad['caption']!,
                                adTitle: ad['adTitle'] ?? 'Reklam Başlığı',
                                adCode: ad['adCode'] ?? 'AD-0001',
                                userEmail: widget.userEmail,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                onPressed: _current > 0 ? _goToPrevious : null,
                              ),
                              Text('${_current + 1} / ${_instaAdData.length}'),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: _current < _instaAdData.length - 1
                                    ? () => _goToNext(_instaAdData.length)
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Fiyat ve satın al bölümü
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Text(
                                  (_instaAdData.isNotEmpty && _current < _instaAdData.length)
                                      ? (_instaAdData[_current]['price'] ?? '—')
                                      : '—',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _onReklamSelect();
                                },
                                child: Icon(
                                  MdiIcons.cartPlus,
                                  size: 24,
                                  color: Colors.green,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _onReklamSelect();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  backgroundColor: Colors.lightGreen,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 12),
                                  minimumSize: const Size(60, 30),
                                ),
                                child: const Text('satınAL'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Kategori bölümü
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık ve seçim sayacı
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'REKLAM KATEGORİLERİ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${_selectedExpenses.length}/10 seçildi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _selectedExpenses.length == 10
                                            ? Colors.green
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Kategori sekmeleri (tabs) - Ana kategoriler
                                SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _mainCategories.length,
                                    itemBuilder: (context, index) {
                                      final category = _mainCategories[index];
                                      final bool isActive = _currentCategoryTab == category['id'] as int;
                                      return GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            _currentCategoryTab = category['id'] as int;
                                          });
                                          await _refreshFilteredCategories();
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.red.shade700
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isActive
                                                  ? Colors.red.shade700
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              category['name'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isActive ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Kategori grid (sadece seçili sekmenin kategorileri)
                                SizedBox(
                                  height: 300,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.85,
                                    ),
                                    itemCount: _filteredCategories.length,
                                    itemBuilder: (context, index) {
                                      final category = _filteredCategories[index];
                                      final bool isSelected = _selectedExpenses.any(
                                        (exp) => exp['name'] == category['name'],
                                      );
                                      return GestureDetector(
                                        onTap: () {
                                          _onCategoryTap(category);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.red.shade50
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.red.shade700
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.1),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                category['icon'] as IconData,
                                                size: 22,
                                                color: Colors.red.shade700,
                                              ),
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  category['name'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '#${category['id']}',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SEÇİLEN MASRAFLAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  constraints: const BoxConstraints(minHeight: 100),
                                  padding: const EdgeInsets.all(10),
                                  child: _selectedExpenses.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Henüz masraf seçilmedi\n(Kategorilere tıklayarak seçim yapın)',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(
                                            _selectedExpenses.length,
                                            (index) {
                                              final expense = _selectedExpenses[index];
                                              return Container(
                                                padding: const EdgeInsets.only(
                                                  left: 10,
                                                  right: 5,
                                                  top: 5,
                                                  bottom: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        expense['name'] as String,
                                                        style: const TextStyle(fontSize: 12),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: () => _removeExpense(index),
                                                      child: Container(
                                                        width: 16,
                                                        height: 16,
                                                        decoration: const BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          size: 10,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                ),
                                if (_selectedExpenses.length < 10)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'UYARI! Lütfen ${10 - _selectedExpenses.length} adet daha MASRAF belirleyiniz. "HAKSIZ" tarafın bütçesine uygun bir MASRAFı hediye olarak "HAKLI" tarafa almasına yardımcı olunuz.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 15),
                                // Butonlar
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: canMasraf
                                            ? () async {
                                                await _saveExpenses();
                                                if (mounted) {
                                                  Navigator.of(context).pop(true);
                                                }
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade700,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          disabledBackgroundColor: Colors.grey.shade300,
                                        ),
                                        child: const Text(
                                          'MASRAFLA',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('İptal'),
                                              content: const Text(
                                                'Seçilen MASRAFLAR iptal edilecek. Emin misiniz?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('Hayır'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedExpenses.clear();
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Evet'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade200,
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: Colors.grey.shade400),
                                          ),
                                        ),
                                        child: const Text(
                                          'İPTAL',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Instagram tarzı reklam kartı widget'ı
class _InstaAdCard extends StatelessWidget {
  final String profileImage;
  final String name;
  final String sponsoredText;
  final String mainImage;
  final String buttonText;
  final String buttonUrl;
  final String caption;
  final String adTitle;
  final String adCode;
  final String? userEmail;

  const _InstaAdCard({
    required this.profileImage,
    required this.name,
    required this.sponsoredText,
    required this.mainImage,
    required this.buttonText,
    required this.buttonUrl,
    required this.caption,
    required this.adTitle,
    required this.adCode,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipOval(
                  child: Image.network(
                    profileImage,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        sponsoredText,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              adTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              adCode,
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              ],
            ),
          ),
          // Main Image
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: mainImage.startsWith('lib/') || mainImage.startsWith('assets/')
                ? Image.asset(
                    mainImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  )
                : Image.network(
                    mainImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
          ),
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0095f6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () async {
                  final url = Uri.parse(buttonUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bağlantı açılamadı')),
                      );
                    }
                  }
                },
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(caption, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

