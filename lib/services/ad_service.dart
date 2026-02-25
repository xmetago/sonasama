import 'dart:math';

/// Reklam öğesi modeli
class AdItem {
  final String code; // Reklam kodu (ör. AD-0001)
  final String title; // Reklamın başlığı
  final String description; // Reklamın açıklaması
  final String link; // Reklamın linki
  final String imageUrl; // Görsel URL
  final String price; // Ürün tutarı (metin)
  final int weight; // Gösterim ağırlığı/oranı
  final String owner; // Sahip/hesap adı
  final String ownerAvatar; // Profil görseli
  final String sponsoredText; // 'Sponsorlu' etiketi vb.

  const AdItem({
    required this.code,
    required this.title,
    required this.description,
    required this.link,
    required this.imageUrl,
    required this.price,
    required this.weight,
    required this.owner,
    required this.ownerAvatar,
    this.sponsoredText = 'Sponsorlu',
  });
}

/// Basit reklam yönetim servisi.
/// - Bellekte reklamları tutar
/// - Ağırlıklara göre bir gösterim listesi üretir
class AdService {
  AdService._internal();
  static final AdService _instance = AdService._internal();
  static AdService get I => _instance;

  final List<AdItem> _ads = <AdItem>[
    const AdItem(
      code: 'AD-0001',
      title: 'XMetaGo Kampanyası',
      description:
          'XMetaGo Dijital reklam kampanyalarınızı performansa dayalı büyütün. Daha fazla görünürlük ve etkileşim için hemen tıklayın!',
      link: 'https://www.xmetago.com',
      imageUrl: 'https://via.placeholder.com/360x360',
      price: '100 \$',
      weight: 5,
      owner: 'xmetago',
      ownerAvatar: 'https://via.placeholder.com/40',
      sponsoredText: 'Sponsorlu',
    ),
    const AdItem(
      code: 'AD-0002',
      title: 'LawyerPro Dijital',
      description:
          'LawyerPro ile davalarınızı dijital ortamda yönetin. Hemen keşfedin!',
      link: 'https://www.lawyerpro.com',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=360&q=80',
      price: '149 \$',
      weight: 3,
      owner: 'lawyerpro',
      ownerAvatar: 'https://randomuser.me/api/portraits/men/32.jpg',
      sponsoredText: 'Sponsorlu',
    ),
    const AdItem(
      code: 'AD-0003',
      title: 'Kanıt Analiz Platformu',
      description:
          'Kanıt Analiz Platformu ile yeni nesil yapay zeka destekli analizler!',
      link: 'https://www.kanitanaliz.com',
      imageUrl:
          'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=360&q=80',
      price: '89 \$',
      weight: 2,
      owner: 'kanitanaliz',
      ownerAvatar: 'https://randomuser.me/api/portraits/women/44.jpg',
      sponsoredText: 'Sponsorlu',
    ),
  ];

  /// Var olan reklamların tamamını döndürür
  List<AdItem> getAll() => List<AdItem>.unmodifiable(_ads);

  /// Reklam ekler (runtime)
  void add(AdItem item) {
    _ads.add(item);
  }

  /// Ağırlıklara göre karıştırılmış bir liste döndürür.
  /// Her reklam ağırlığı kadar çoğaltılır, sonra karıştırılır ve bir pencere seçilir.
  List<AdItem> getWeightedAds({int maxCount = 10}) {
    final List<AdItem> pool = <AdItem>[];
    for (final AdItem ad in _ads) {
      for (int i = 0; i < (ad.weight <= 0 ? 1 : ad.weight); i++) {
        pool.add(ad);
      }
    }
    pool.shuffle(Random());
    if (pool.length <= maxCount) {
      return List<AdItem>.from(pool);
    }
    return pool.sublist(0, maxCount);
  }

  /// UI kolaylığı için Map listesine dönüştürür
  List<Map<String, String>> getWeightedAdsAsMap({int maxCount = 10}) {
    return getWeightedAds(maxCount: maxCount).map((AdItem ad) {
      return <String, String>{
        'profileImage': ad.ownerAvatar,
        'name': ad.owner,
        'sponsoredText': ad.sponsoredText,
        'mainImage': ad.imageUrl,
        'buttonText': 'Detaylı İncele',
        'buttonUrl': ad.link,
        'caption': ad.description,
        'adTitle': ad.title,
        'adCode': ad.code,
        'price': ad.price,
      };
    }).toList();
  }
}


