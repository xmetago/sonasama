# WhoBoom - Profesyonel Tasarım Önerileri
## Metin Okuma Odaklı Eğlenceli Hukuk Uygulaması

---

## 📋 İçindekiler
1. [Renk Paleti Önerileri](#renk-paleti-önerileri)
2. [Tipografi ve Metin Stilleri](#tipografi-ve-metin-stilleri)
3. [Okunabilirlik İçin Özel Öneriler](#okunabilirlik-için-özel-öneriler)
4. [Uygulama Genelinde Renk Kullanımı](#uygulama-genelinde-renk-kullanımı)
5. [Eğlenceli-Profsyonel Denge](#eğlenceli-profesyonel-denge)

---

## 🎨 Renk Paleti Önerileri

### Ana Renk Paleti (Önerilen)

#### **VARYANT 1: Modern Adalet Teması (ÖNERİLEN)**
```dart
// Ana Renkler
static const Color primaryColor = Color(0xFF2E7D8F);        // Derin turkuaz (Adalet ve güven)
static const Color primaryLightColor = Color(0xFF4FA8B8);   // Orta turkuaz
static const Color primaryLighterColor = Color(0xFF7EC8D4); // Açık turkuaz
static const Color primaryDarkColor = Color(0xFF1A5563);    // Çok koyu turkuaz

// Vurgu Renkleri (Eylem ve Eğlence)
static const Color accentColor = Color(0xFFE94B3C);         // Canlı kırmızı (Haykır/Eylem)
static const Color accentLightColor = Color(0xFFFF6B5A);    // Açık kırmızı
static const Color successColor = Color(0xFF10B981);        // Başarı yeşili
static const Color warningColor = Color(0xFFF59E0B);        // Uyarı turuncusu
static const Color infoColor = Color(0xFF3B82F6);           // Bilgi mavisi

// Arka Plan Renkleri (Okunabilirlik için optimize)
static const Color scaffoldBackgroundColor = Color(0xFFFAFAFA); // Çok hafif gri
static const Color cardBackgroundColor = Colors.white;          // Saf beyaz
static const Color textBackgroundColor = Color(0xFFF8F9FA);     // Metin için özel arka plan

// Metin Renkleri (Yüksek kontrast)
static const Color textPrimary = Color(0xFF1F2937);         // Neredeyse siyah (Başlıklar)
static const Color textSecondary = Color(0xFF4B5563);       // Koyu gri (Alt metinler)
static const Color textTertiary = Color(0xFF6B7280);        // Orta gri (Açıklamalar)
static const Color textMuted = Color(0xFF9CA3AF);           // Açık gri (Yardımcı metinler)
```

#### **VARYANT 2: Klasik Adalet Teması**
```dart
// Ana Renkler (Daha klasik ve ciddi)
static const Color primaryColor = Color(0xFF1A4A5C);        // Koyu lacivert
static const Color primaryLightColor = Color(0xFF2E6B7F);   
static const Color primaryLighterColor = Color(0xFF6BA8C4);
static const Color accentColor = Color(0xFFC75050);         // Koyu kırmızı
```

#### **VARYANT 3: Eğlenceli Modern Teması**
```dart
// Ana Renkler (Daha canlı ve eğlenceli)
static const Color primaryColor = Color(0xFF2563EB);        // Parlak mavi
static const Color primaryLightColor = Color(0xFF3B82F6);
static const Color accentColor = Color(0xFFFF6B35);         // Turuncu-kırmızı
static const Color accentSecondary = Color(0xFF10B981);     // Canlı yeşil
```

### Renk Kullanım Kuralları

#### **Metin İçerikleri için:**
- **Dava konuları, haykırışlar:** Beyaz arka plan üzerinde `textPrimary` (0xFF1F2937)
- **Uzun metinler:** Minimum 16px font, satır yüksekliği 1.6-1.8
- **Vurgu metinler:** `primaryColor` veya `accentColor` kullanın
- **Önemli bilgiler:** `textSecondary` (0xFF4B5563) - başlıklardan daha açık

#### **Buton ve Etkileşimler:**
- **Birincil butonlar:** `primaryColor` (0xFF2E7D8F)
- **Eylem butonları (Haykır, Dava Aç):** `accentColor` (0xFFE94B3C)
- **Başarı butonları:** `successColor` (0xFF10B981)
- **İkincil butonlar:** Beyaz arka plan, `primaryColor` kenarlık

---

## 📝 Tipografi ve Metin Stilleri

### Font Boyutları ve Hiyerarşi

```dart
class AppTextStyles {
  // Başlıklar
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2937),  // textPrimary
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2937),
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
    height: 1.4,
  );
  
  static const TextStyle headline4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
    height: 1.4,
  );
  
  // Metin İçerikleri (ÖNEMLİ: Metin okuma için optimize)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,  // Okunabilirlik için ideal boyut
    fontWeight: FontWeight.normal,
    color: Color(0xFF1F2937),  // Yüksek kontrast
    height: 1.75,  // Geniş satır aralığı (okuma için kritik)
    letterSpacing: 0.2,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1F2937),
    height: 1.7,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF4B5563),  // textSecondary
    height: 1.6,
  );
  
  // Dava Konusu ve Uzun Metinler için Özel Stil
  static const TextStyle davaContent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1F2937),
    height: 1.8,  // Çok geniş satır aralığı
    letterSpacing: 0.15,
    wordSpacing: 2.0,  // Kelimeler arası boşluk
  );
  
  // Haykırış İçeriği için Özel Stil
  static const TextStyle haykirContent = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,  // Biraz daha kalın
    color: Color(0xFF1F2937),
    height: 1.8,
    letterSpacing: 0.2,
  );
  
  // Yardımcı Metinler
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF6B7280),  // textTertiary
    height: 1.5,
  );
  
  // Etiketler ve Badge'ler
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
  );
  
  // Buton Metinleri
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
    letterSpacing: 0.5,
  );
}
```

### Metin Okuma için Özel Öneriler

#### **1. Satır Genişliği (Line Length)**
- **Optimal:** 45-75 karakter (yaklaşık 320-520px genişlik)
- Uzun metinler için maksimum genişlik sınırı koyun
- Tablet ve desktop'ta daha geniş alan kullanılabilir

#### **2. Paragraf Aralıkları**
- Paragraflar arası minimum 16px boşluk
- Uzun içerikler için 24px daha iyi
- Görsel nefes alma alanı yaratır

#### **3. Kontrast Oranları (WCAG AA Standardı)**
- **Normal metin:** Minimum 4.5:1 kontrast
- **Büyük metin (18px+):** Minimum 3:1 kontrast
- **Önerilen:** 7:1 kontrast (ideal okunabilirlik)

#### **4. Metin Hizalama**
- **Türkçe için:** Sol hizalama (left-aligned)
- Asla ortalanmış uzun metin kullanmayın
- Sağ hizalama sadece sayılar ve tarihler için

---

## 👁️ Okunabilirlik İçin Özel Öneriler

### Dava Konusu ve Detay Görüntüleme

```dart
// Dava konusu için özel widget örneği
class DavaKonusuDisplay extends StatelessWidget {
  final String davaKonusu;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,  // Saf beyaz arka plan
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFE5E7EB),  // Hafif gri kenarlık
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'Dava Konusu',
            style: AppTextStyles.headline4.copyWith(
              color: Color(0xFF2E7D8F),  // primaryColor
            ),
          ),
          SizedBox(height: 16),
          // İçerik
          SelectableText(  // Seçilebilir metin
            davaKonusu,
            style: AppTextStyles.davaContent,
            // Metin seçimi için optimize
          ),
        ],
      ),
    );
  }
}
```

### Haykırış İçeriği Görüntüleme

```dart
// Haykırış için özel stil
class HaykirContentDisplay extends StatelessWidget {
  final String content;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),  // Hafif gri arka plan
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Color(0xFFE94B3C),  // accentColor
            width: 4,
          ),
        ),
      ),
      child: SelectableText(
        content,
        style: AppTextStyles.haykirContent,
      ),
    );
  }
}
```

### Uzun Metinler için Özellikler

1. **Metin Seçilebilir Olmalı:** `SelectableText` kullanın
2. **Kopyalama Özelliği:** Uzun metinlerde kopyala butonu
3. **Yazı Tipi Boyutu Ayarlama:** Kullanıcı tercihine göre (14px, 16px, 18px)
4. **Karanlık Mod Desteği:** Gece okuma için
5. **Pagination:** Çok uzun metinler için sayfalama

---

## 🎯 Uygulama Genelinde Renk Kullanımı

### Sayfa Bazında Renk Önerileri

#### **Ana Sayfa (Home)**
- Arka plan: `scaffoldBackgroundColor` (0xFFFAFAFA)
- Kartlar: Beyaz
- Vurgu: `primaryColor` (0xFF2E7D8F)

#### **Dava Sayfaları**
- Dava kartları: Beyaz arka plan
- Dava konusu: Beyaz arka plan, `davaContent` stili
- Eylem butonları: `accentColor` (0xFFE94B3C)
- Durum rozetleri: `successColor`, `warningColor` gibi

#### **Haykırış Sayfaları**
- Haykırış kartları: `Color(0xFFF8F9FA)` arka plan
- Sol kenarlık: `accentColor` (0xFFE94B3C) - 4px
- Metin: `haykirContent` stili

#### **Yargılama Sayfaları**
- Ciddi görünüm için: `primaryDarkColor` vurguları
- Metin: Yüksek kontrast siyah-beyaz

#### **Profil ve Ayarlar**
- Nötr renkler: Gri tonları
- Vurgular: `primaryColor`

### İkon ve Görsel Öğeler

```dart
// İkon renkleri
static const Color iconPrimary = Color(0xFF2E7D8F);      // Ana ikonlar
static const Color iconSecondary = Color(0xFF6B7280);    // İkincil ikonlar
static const Color iconAccent = Color(0xFFE94B3C);       // Vurgu ikonları
static const Color iconMuted = Color(0xFF9CA3AF);        // Sessiz ikonlar
```

---

## 🎪 Eğlenceli-Profesyonel Denge

### Eğlenceli Öğeler (Ama Profesyonel Kalın)

1. **Renkli Vurgular:**
   - `accentColor` (0xFFE94B3C) sadece eylem butonlarında
   - Abartılı renklerden kaçının

2. **İkonlar:**
   - Material Design Icons kullanın
   - Renkli ama minimal

3. **Animasyonlar:**
   - Yumuşak ve profesyonel
   - Aşırı bouncy efektlerden kaçının

4. **Dil ve Ton:**
   - Eğlenceli ama saygılı
   - Hukuki terimleri doğru kullanın
   - Emoji kullanımı minimal olsun

### Profesyonel Öğeler

1. **Tutarlı Tipografi:**
   - Tüm uygulamada aynı font hiyerarşisi
   - Okunabilirlik ön planda

2. **Düzenli Boşluklar:**
   - 8px grid sistemi
   - Tutarlı padding ve margin değerleri

3. **Renk Tutarlılığı:**
   - Aynı anlamlar için aynı renkler
   - Marka kimliği korunmalı

---

## 📱 Responsive Tasarım Önerileri

### Mobil (Phone)
- Metin boyutu: 16-17px (body)
- Satır genişliği: Ekran genişliğinin %90'ı
- Padding: 16-20px

### Tablet
- Metin boyutu: 17-18px (body)
- Satır genişliği: Maksimum 600px
- Padding: 24-32px

### Desktop (Gelecek için)
- Metin boyutu: 16-18px (body)
- Satır genişliği: Maksimum 720px
- Çok sütunlu düzen mümkün

---

## ✅ Uygulama Checklist

### Renk Kontrolü
- [ ] Tüm metinler için yeterli kontrast (minimum 4.5:1)
- [ ] Renk körlüğü testi yapıldı
- [ ] Karanlık mod için renk paleti hazır

### Tipografi Kontrolü
- [ ] Tüm uzun metinler için `davaContent` veya `haykirContent` stili
- [ ] Minimum font boyutu 14px (mobil için)
- [ ] Satır yüksekliği minimum 1.6
- [ ] Paragraf aralıkları yeterli

### Okunabilirlik Kontrolü
- [ ] Metinler seçilebilir (`SelectableText`)
- [ ] Uzun metinler için maksimum genişlik sınırı
- [ ] Yeterli beyaz alan (whitespace)
- [ ] Görsel hiyerarşi net

---

## 🚀 Hızlı Başlangıç Kodu

```dart
// lib/utils/app_theme.dart
class AppTheme {
  // Renkler
  static const Color primaryColor = Color(0xFF2E7D8F);
  static const Color accentColor = Color(0xFFE94B3C);
  static const Color scaffoldBackgroundColor = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF1F2937);
  
  // Metin Stilleri
  static const TextStyle davaContentStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1F2937),
    height: 1.8,
    letterSpacing: 0.15,
  );
  
  // Tema
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: 'Cocon',  // Mevcut fontunuz
      textTheme: TextTheme(
        bodyLarge: davaContentStyle,
        bodyMedium: davaContentStyle,
      ),
    );
  }
}
```

---

## 📚 Kaynaklar ve Referanslar

- **WCAG 2.1 Kontrast Oranları:** https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
- **Typography Best Practices:** Google Material Design
- **Readability Research:** Baymard Institute

---

**Son Güncelleme:** 2024
**Versiyon:** 1.0

