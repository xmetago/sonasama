import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcıya göre Sarı / Yeşil yıldız bakiyesi — [SharedPreferences].
///
/// Sarı yıldız (masraf bakiyesi): asla negatif olamaz, biterse satın alma akışı
/// devreye girer.
/// Yeşil yıldız (itibar puanı): negatif olabilir; haksız çıkıldığında düşer.
class UserStarBalanceStore {
  UserStarBalanceStore._();

  static const String _yellowKeyPrefix = 'whooboom_yellow_stars_v1';
  static const String _greenKeyPrefix = 'whooboom_green_stars_v1';

  static String _yellowKey(String email) =>
      '$_yellowKeyPrefix:${email.trim().toLowerCase()}';

  static String _greenKey(String email) =>
      '$_greenKeyPrefix:${email.trim().toLowerCase()}';

  // ===================== SARI YILDIZ (Masraf) =====================

  static Future<int> getYellowStars(String? email) async {
    if (email == null || email.trim().isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_yellowKey(email)) ?? 0;
  }

  static Future<void> setYellowStars(String email, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_yellowKey(email), value < 0 ? 0 : value);
  }

  static Future<void> addYellowStars(String email, int amount) async {
    if (amount <= 0) return;
    final current = await getYellowStars(email);
    await setYellowStars(email, current + amount);
  }

  /// Yeterliyse çıkarır ve [true] döndürür.
  /// Yetersizse hiçbir değişiklik yapmaz ve [false] döndürür.
  static Future<bool> trySpendYellowStars(String email, int cost) async {
    if (cost <= 0) return true;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_yellowKey(email)) ?? 0;
    if (current < cost) return false;
    await prefs.setInt(_yellowKey(email), current - cost);
    return true;
  }

  // ===================== YEŞİL YILDIZ (İtibar) =====================
  // Yeşil yıldız negatif olabildiği için doğrudan int olarak saklanır.

  static Future<int> getGreenStars(String? email) async {
    if (email == null || email.trim().isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_greenKey(email)) ?? 0;
  }

  static Future<void> setGreenStars(String email, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_greenKey(email), value);
  }

  static Future<void> addGreenStars(String email, int amount) async {
    if (amount == 0 || email.trim().isEmpty) return;
    final current = await getGreenStars(email);
    await setGreenStars(email, current + amount);
  }

  /// Yeşil yıldız harcar — negatife düşmesine izin verilir.
  static Future<void> spendGreenStars(String email, int amount) async {
    if (amount <= 0) return;
    await addGreenStars(email, -amount);
  }
}

