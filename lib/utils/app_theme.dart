import 'package:flutter/material.dart';

/// WhoBoom Uygulaması için Profesyonel Tema ve Stil Tanımlamaları
/// Metin okuma odaklı tasarım için optimize edilmiş renk paleti ve stiller
class AppTheme {
  // ========== RENK PALETİ ==========
  
  // Ana Renkler - Modern Adalet Teması
  static const Color primaryColor = Color(0xFF2E7D8F);        // Derin turkuaz (Adalet ve güven)
  static const Color primaryLightColor = Color(0xFF4FA8B8);   // Orta turkuaz
  static const Color primaryLighterColor = Color(0xFF7EC8D4); // Açık turkuaz
  static const Color primaryDarkColor = Color(0xFF1A5563);    // Çok koyu turkuaz
  static const Color primaryUltraLight = Color(0xFFE0F2F5);   // Çok açık turkuaz

  // Vurgu Renkleri (Eylem ve Eğlence)
  static const Color accentColor = Color(0xFFE94B3C);         // Canlı kırmızı (Haykır/Eylem)
  static const Color accentLightColor = Color(0xFFFF6B5A);    // Açık kırmızı
  static const Color accentDarkColor = Color(0xFFC23A2D);     // Koyu kırmızı
  static const Color accentUltraLight = Color(0xFFFFEDEB);    // Çok açık kırmızı

  // Durum Renkleri
  static const Color successColor = Color(0xFF10B981);        // Başarı yeşili
  static const Color successLightColor = Color(0xFF34D399);   // Açık başarı yeşili
  static const Color successDarkColor = Color(0xFF059669);    // Koyu başarı yeşili
  static const Color successUltraLight = Color(0xFFD1FAE5);   // Çok açık yeşil
  
  // Huzur Verici Yeşil Tonları (Okunabilirlik için optimize)
  static const Color calmGreen = Color(0xFF6EE7B7);           // Huzur verici açık yeşil
  static const Color calmGreenLight = Color(0xFFA7F3D0);      // Çok açık huzur verici yeşil
  static const Color calmGreenUltraLight = Color(0xFFECFDF5); // Çok açık yeşil arka plan
  static const Color calmGreenDark = Color(0xFF047857);       // Koyu huzur verici yeşil

  static const Color warningColor = Color(0xFFF59E0B);        // Uyarı turuncusu
  static const Color warningLightColor = Color(0xFFFBBF24);   // Açık turuncu
  static const Color warningUltraLight = Color(0xFFFEF3C7);   // Çok açık turuncu

  static const Color errorColor = Color(0xFFEF4444);          // Hata kırmızısı
  static const Color errorLightColor = Color(0xFFF87171);     // Açık hata kırmızısı
  static const Color errorUltraLight = Color(0xFFFEE2E2);     // Çok açık kırmızı

  static const Color infoColor = Color(0xFF3B82F6);           // Bilgi mavisi
  static const Color infoLightColor = Color(0xFF60A5FA);      // Açık mavi
  static const Color infoUltraLight = Color(0xFFDBEAFE);      // Çok açık mavi

  // Arka Plan Renkleri (Okunabilirlik için optimize - Yeşil tonları ile huzur verici)
  static const Color scaffoldBackgroundColor = Color(0xFFF0F9F5); // Çok açık yeşilimsi arka plan (huzur verici)
  static const Color cardBackgroundColor = Color(0xFFFAFDFB);    // Çok açık yeşilimsi beyaz (huzur verici)
  static const Color textBackgroundColor = Color(0xFFF5FBF8);     // Metin için özel yeşilimsi arka plan
  static const Color surfaceColor = Color(0xFFFAFDFB);           // Yüzey rengi (yeşilimsi beyaz)
  static const Color dividerColor = Color(0xFFD1E5DD);           // Ayırıcı çizgi rengi (yeşilimsi gri)

  // Metin Renkleri (Yüksek kontrast - WCAG AA uyumlu)
  static const Color textPrimary = Color(0xFF1F2937);         // Neredeyse siyah (Başlıklar) - 7:1 kontrast
  static const Color textSecondary = Color(0xFF4B5563);       // Koyu gri (Alt metinler) - 5:1 kontrast
  static const Color textTertiary = Color(0xFF6B7280);        // Orta gri (Açıklamalar) - 4.5:1 kontrast
  static const Color textMuted = Color(0xFF9CA3AF);           // Açık gri (Yardımcı metinler)
  static const Color textOnPrimary = Colors.white;            // Beyaz (renkli arka planlar üzerinde)
  static const Color textOnAccent = Colors.white;             // Beyaz (vurgu renkleri üzerinde)

  // İkon Renkleri (Yeşil tonları ile huzur verici)
  static const Color iconPrimary = Color(0xFF059669);         // Ana ikonlar (huzur verici yeşil)
  static const Color iconSecondary = Color(0xFF10B981);       // İkincil ikonlar (yeşil tonu)
  static const Color iconAccent = Color(0xFFE94B3C);          // Vurgu ikonları
  static const Color iconMuted = Color(0xFF6EE7B7);           // Sessiz ikonlar (açık yeşil)

  // ========== TİPOGRAFİ ==========
  
  // Başlıklar
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle headline4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  // Metin İçerikleri (ÖNEMLİ: Metin okuma için optimize)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,  // Okunabilirlik için ideal boyut
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.75,  // Geniş satır aralığı (okuma için kritik)
    letterSpacing: 0.2,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.7,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.6,
  );
  
  // Dava Konusu ve Uzun Metinler için Özel Stil
  static const TextStyle davaContent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.8,  // Çok geniş satır aralığı
    letterSpacing: 0.15,
    wordSpacing: 2.0,  // Kelimeler arası boşluk
  );
  
  // Haykırış İçeriği için Özel Stil
  static const TextStyle haykirContent = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,  // Biraz daha kalın
    color: textPrimary,
    height: 1.8,
    letterSpacing: 0.2,
  );
  
  // Yardımcı Metinler
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textTertiary,
    height: 1.5,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textMuted,
    height: 1.4,
    letterSpacing: 1.5,
  );

  // ========== BUTON STİLLERİ ==========
  
  // Birincil Buton (Primary Button) - Ana eylemler (Yeşil tonu ile huzur verici)
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: successColor, // Yeşil ana renk
    foregroundColor: textOnPrimary,
    elevation: 2,
    shadowColor: successColor.withOpacity(0.3), // Yeşilimsi gölge
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(120, 48),  // Minimum buton boyutu
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Birincil Buton Küçük Boyut (Yeşil tonu ile huzur verici)
  static ButtonStyle get primaryButtonSmallStyle => ElevatedButton.styleFrom(
    backgroundColor: successColor, // Yeşil ana renk
    foregroundColor: textOnPrimary,
    elevation: 2,
    shadowColor: successColor.withOpacity(0.3), // Yeşilimsi gölge
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: const Size(100, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Vurgu Butonu (Accent Button) - Eylem butonları (Haykır, Dava Aç)
  static ButtonStyle get accentButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: textOnAccent,
    elevation: 3,
    shadowColor: accentColor.withOpacity(0.4),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    minimumSize: const Size(140, 52),  // Daha büyük ve belirgin
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );

  // Vurgu Butonu Küçük
  static ButtonStyle get accentButtonSmallStyle => ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: textOnAccent,
    elevation: 2,
    shadowColor: accentColor.withOpacity(0.3),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    minimumSize: const Size(120, 44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
  );

  // Başarı Butonu (Success Button)
  static ButtonStyle get successButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: successColor,
    foregroundColor: textOnPrimary,
    elevation: 2,
    shadowColor: successColor.withOpacity(0.3),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(120, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Uyarı Butonu (Warning Button)
  static ButtonStyle get warningButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: warningColor,
    foregroundColor: textOnPrimary,
    elevation: 2,
    shadowColor: warningColor.withOpacity(0.3),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(120, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Hata Butonu (Error Button)
  static ButtonStyle get errorButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: errorColor,
    foregroundColor: textOnPrimary,
    elevation: 2,
    shadowColor: errorColor.withOpacity(0.3),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(120, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // İkincil Buton (Outlined Button) - Yeşil tonu ile huzur verici
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: successColor, // Yeşil renk
    side: const BorderSide(color: successColor, width: 2), // Yeşil kenarlık
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(120, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // İkincil Buton Küçük - Yeşil tonu ile huzur verici
  static ButtonStyle get secondaryButtonSmallStyle => OutlinedButton.styleFrom(
    foregroundColor: successColor, // Yeşil renk
    side: const BorderSide(color: successColor, width: 2), // Yeşil kenarlık
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: const Size(100, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Metin Butonu (Text Button) - Yeşil tonu ile huzur verici
  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: successColor, // Yeşil renk
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    minimumSize: const Size(80, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );

  // Buton Icon Stilleri - Yeşil tonu ile huzur verici
  static ButtonStyle get iconButtonStyle => IconButton.styleFrom(
    foregroundColor: iconPrimary, // Yeşil ikon rengi
    padding: const EdgeInsets.all(12),
    minimumSize: const Size(48, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // ========== TEMA ==========
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: successColor, // Yeşil ana renk
      scaffoldBackgroundColor: scaffoldBackgroundColor, // Yeşilimsi arka plan
      cardColor: cardBackgroundColor, // Yeşilimsi kart rengi
      dividerColor: dividerColor, // Yeşilimsi ayırıcı
      fontFamily: 'Cocon',
      
      // Renk Şeması (Yeşil tonları ile huzur verici)
      colorScheme: const ColorScheme.light(
        primary: successColor, // Yeşil ana renk
        primaryContainer: calmGreenUltraLight, // Çok açık yeşil konteyner
        secondary: accentColor,
        secondaryContainer: accentUltraLight,
        surface: surfaceColor, // Yeşilimsi yüzey
        error: errorColor,
        onPrimary: textOnPrimary,
        onSecondary: textOnAccent,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),
      
      // Metin Teması
      textTheme: const TextTheme(
        displayLarge: headline1,
        displayMedium: headline2,
        displaySmall: headline3,
        headlineMedium: headline4,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: caption,
      ),
      
      // ElevatedButton Teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      
      // OutlinedButton Teması
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryButtonStyle,
      ),
      
      // TextButton Teması
      textButtonTheme: TextButtonThemeData(
        style: textButtonStyle,
      ),
      
      // IconButton Teması
      iconButtonTheme: IconButtonThemeData(
        style: iconButtonStyle,
      ),
      
      // Input Decoration Teması (Yeşil tonları ile huzur verici)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: calmGreenUltraLight, // Çok açık yeşil arka plan
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: successColor, width: 2), // Yeşil odak rengi
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Card Teması (Yeşil tonları ile huzur verici)
      cardTheme: CardThemeData(
        color: cardBackgroundColor, // Çok açık yeşilimsi beyaz
        elevation: 2,
        shadowColor: successColor.withOpacity(0.1), // Yeşilimsi gölge
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // AppBar Teması (Yeşil tonu ile huzur verici)
      appBarTheme: const AppBarTheme(
        backgroundColor: successColor, // Yeşil arka plan
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
      ),
    );
  }
}

/// Buton Boyutları için Yardımcı Sınıf
class ButtonSizes {
  // Standart buton boyutları
  static const double smallHeight = 40;
  static const double mediumHeight = 48;
  static const double largeHeight = 52;
  static const double extraLargeHeight = 56;
  
  // Padding değerleri
  static const EdgeInsets smallPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  static const EdgeInsets mediumPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets largePadding = EdgeInsets.symmetric(horizontal: 28, vertical: 18);
  
  // Minimum genişlik
  static const double smallMinWidth = 100;
  static const double mediumMinWidth = 120;
  static const double largeMinWidth = 140;
}

/// Buton Türleri için Yardımcı Metodlar
class AppButtons {
  /// Birincil buton oluştur
  static Widget primary({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = false,
    bool isSmall = false,
  }) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: isSmall ? 18 : 20),
            label: Text(text),
            style: isSmall ? AppTheme.primaryButtonSmallStyle : AppTheme.primaryButtonStyle,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: isSmall ? AppTheme.primaryButtonSmallStyle : AppTheme.primaryButtonStyle,
            child: Text(text),
          );
    
    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
  
  /// Vurgu butonu oluştur (Eylem butonları için)
  static Widget accent({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = false,
    bool isSmall = false,
  }) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: isSmall ? 18 : 20),
            label: Text(text),
            style: isSmall ? AppTheme.accentButtonSmallStyle : AppTheme.accentButtonStyle,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: isSmall ? AppTheme.accentButtonSmallStyle : AppTheme.accentButtonStyle,
            child: Text(text),
          );
    
    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
  
  /// Başarı butonu oluştur
  static Widget success({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(text),
            style: AppTheme.successButtonStyle,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: AppTheme.successButtonStyle,
            child: Text(text),
          );
    
    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
  
  /// İkincil buton oluştur (Outlined)
  static Widget secondary({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = false,
    bool isSmall = false,
  }) {
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: isSmall ? 18 : 20),
            label: Text(text),
            style: isSmall ? AppTheme.secondaryButtonSmallStyle : AppTheme.secondaryButtonStyle,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: isSmall ? AppTheme.secondaryButtonSmallStyle : AppTheme.secondaryButtonStyle,
            child: Text(text),
          );
    
    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

