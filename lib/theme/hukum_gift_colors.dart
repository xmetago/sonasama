 import 'package:flutter/material.dart';

/// Hüküm kartı / hediye ızgarası için fiyat tonları (untitled AppColors ile uyumlu).
abstract final class HukumGiftColors {
  static const Color accentGold = Color(0xFFD4A373);
  static const Color accentCaramel = Color(0xFFC77D4A);
  static const Color selectedAreaBg = Color(0xFFF5FAF7);

  static Color priceLow(BuildContext context) => Colors.green.shade700;
  static Color priceMid(BuildContext context) => Colors.orange.shade800;
  static Color priceHigh(BuildContext context) => Colors.red.shade700;

  static Color priceColorForValue(BuildContext context, int price) {
    if (price <= 95) return priceLow(context);
    if (price <= 247) return priceMid(context);
    return priceHigh(context);
  }
}
