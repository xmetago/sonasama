import 'package:flutter/material.dart';
import 'category_icon_utils.dart';
import 'constants.dart';

/// Kategori adına göre local Lottie asset path döndürür.
String getLottieAssetForCategory(String categoryName) {
  final n = categoryName.toLowerCase();
  // Vefasızlara – kırık kalp
  if (n.contains('vefa')) return _assetBrokenHeart;
  // Ünlü – yıldız
  if (n.contains('ünlü') || n.contains('unlu')) return _assetStar;
  // Aşk, sevgili, eş, evlilik, kadın, erkek – kalp
  if (n.contains('aşk') ||
      n.contains('ask') ||
      n.contains('sevgili') ||
      n.contains('eşine') ||
      n.contains('evlilik') ||
      n.contains('kadın') ||
      n.contains('erkek')) {
    return _assetHeart;
  }
  // Aile, arkadaş – aile/arkadaşlık
  if (n.contains('aile') || n.contains('arkadaş') || n.contains('arkadas')) return _assetFamily;
  // Zalim – öfke/ateş
  if (n.contains('zalim')) return _assetAngry;
  // Patron, iş – çalışma
  if (n.contains('patron') || n.contains('iş arkadaş') || n.contains('is arkadas')) return _assetWork;
  // Öğretmen – eğitim
  if (n.contains('öğretmen') || n.contains('ogretmen')) return _assetSchool;
  // Politika, belediye, banka – bina/kurum
  if (n.contains('politika') || n.contains('belediye') || n.contains('banka')) return _assetBuilding;
  // Tanrı – huzur/ışık
  if (n.contains('tanrı') || n.contains('tanri')) return _assetSpiritual;
  // Futbol, takım – spor
  if (n.contains('futbol') || n.contains('takım') || n.contains('takim')) return _assetSoccer;
  // Hastane, doktor – sağlık
  if (n.contains('hastane') || n.contains('doktor')) return _assetHealth;
  // Sosyal medya
  if (n.contains('sosyal')) return _assetSocial;
  // Mahkeme – hukuk
  if (n.contains('mahkeme')) return _assetLaw;
  // Hayat, kaygı – düşünce/psikoloji
  if (n.contains('hayat') || n.contains('kaygı') || n.contains('kaygi')) return _assetLife;
  // Diziler – film
  if (n.contains('dizi')) return _assetMovie;
  // Arabalar
  if (n.contains('araba')) return _assetCar;
  return _assetDefault;
}

/// Preload için mevcut tüm Lottie asset path'leri.
List<String> getAllCategoryLottieAssets() {
  return const <String>[
    _assetDefault,
    _assetStar,
  ];
}

/// Kategori adına göre Lottie yüklenemezse gösterilecek ikon.
IconData getFallbackIconForCategory(String categoryName) {
  for (final entry in initialCategories) {
    if ((entry['name'] as String).toLowerCase() == categoryName.toLowerCase()) {
      final icon = entry['icon'] as String?;
      if (icon != null) return categoryIconFromPath(icon);
    }
  }
  return Icons.category;
}

// ——— Tema bazlı local Lottie asset'leri ———
const String _assetDefault = 'assets/animations/category_default.json';
const String _assetBrokenHeart = _assetDefault;
const String _assetStar = 'assets/animations/category_star.json';
const String _assetHeart = _assetDefault;
const String _assetFamily = _assetDefault;
const String _assetAngry = _assetDefault;
const String _assetWork = _assetDefault;
const String _assetSchool = _assetDefault;
const String _assetBuilding = _assetDefault;
const String _assetSpiritual = _assetDefault;
const String _assetSoccer = _assetDefault;
const String _assetHealth = _assetDefault;
const String _assetSocial = _assetDefault;
const String _assetLaw = _assetDefault;
const String _assetLife = _assetDefault;
const String _assetMovie = _assetDefault;
const String _assetCar = _assetDefault;
