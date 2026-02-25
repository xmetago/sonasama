# WhoBoom Uygulaması İçin Reklam Entegrasyon Stratejisi

## 📊 Uygulama Analizi

WhoBoom (ITS19) bir **hukuk/dava yönetim uygulaması**dır. Kullanıcılar:
- Davalar açıyor ve yönetiyor
- Deliller ekliyor ve paylaşıyor
- Mesajlaşma yapıyor
- Seyir defteri tutuyor
- Trend analizi görüntülüyor
- İstatistikler takip ediyor

**Hedef Kitle:** Avukatlar, hukuk öğrencileri, hukuki süreç takip eden bireyler

---

## 🎯 ÖNERİLEN STRATEJİ: "Hibrit Yaklaşım"

### **1. Temel Reklam Ağı: Google AdMob + Mediation**

**Neden AdMob?**
- ✅ Flutter ile mükemmel entegrasyon (`google_mobile_ads` paketi)
- ✅ Güvenilir ödeme sistemi
- ✅ Detaylı analitik ve raporlama
- ✅ Otomatik reklam optimizasyonu
- ✅ GDPR/KVKK uyumlu veri yönetimi
- ✅ Türkiye'de de kabul gören bir platform

**Mediation Platform:** AdMob'un kendi mediation'ı (AppLovin, Unity Ads, Meta Audience Network ile)

---

## 📱 Reklam Formatları ve Yerleşim Önerileri

### **A. Banner Reklamlar (Öncelik: YÜKSEK)**
**Yerleşim Yerleri:**
1. **Ana Sayfa (HomePage) Alt Kısım**
   - Seyir defteri listesinin altında
   - Kullanıcı içerikle ilgilenirken görünür ama rahatsız etmez
   - **Gelir potansiyeli:** Orta

2. **Kategori Sayfaları (Category Page) Alt Kısım**
   - Kategori içeriklerinin altında
   - **Gelir potansiyeli:** Orta-Yüksek

3. **Dava Detay Sayfaları Alt Kısım**
   - Delil listesi veya yorumların altında
   - **Gelir potansiyeli:** Yüksek (kullanıcı sayfada uzun süre kalıyor)

**Tasarım:** Minimal, uygulama temasıyla uyumlu

---

### **B. Ödüllü Video Reklamlar (Öncelik: YÜKSEK)**
**Kullanım Senaryoları:**
1. **Premium İçerik/Özellik Kilidi**
   - Ekstra dava analizi, gelişmiş istatistikler
   - Reklamsız deneyim süresi (30 dakika - 2 saat)
   - Ek depolama alanı

2. **Özel Kategori Erişimi**
   - Özel kategorilere ücretsiz erişim
   - Özel temalar/avatar

3. **Hızlı İşlem**
   - Toplu işlem yapma
   - Öncelikli bildirim

**Uygulama Yeri:**
- Ayarlar sayfasında "Premium Özellikler" bölümü
- Özellik kilitliyken gösterme butonu
- "Reklam İzle, Özellik Aç" butonu

**Gelir Potansiyeli:** ÇOK YÜKSEK (en yüksek eCPM)

---

### **C. Interstitial (Tam Sayfa) Reklamlar (Öncelik: DÜŞÜK-ORTA)**
**DİKKAT:** Hukuk uygulaması olduğu için **ÇOK DİKKATLİ** kullanılmalı!

**Sadece Doğal Geçiş Noktalarında:**
1. **Dava Kapandıktan Sonra**
   - Kullanıcı bir dava tamamladığında
   - "Tebrikler! Dava tamamlandı" ekranından sonra
   - **Sıklık:** Her 3-5 dava tamamlamada 1 kez

2. **Uygulama Açılışında (Splash)**
   - **SADECE** günde ilk açılışta
   - Maksimum 5 saniye
   - "Atla" butonu olmalı

3. **Sayfa Geçişlerinde**
   - Kategori sayfasından dava detay sayfasına geçerken
   - **Sıklık:** Her 5-7 geçişte 1 kez

**Kullanmayın:**
- ❌ Delil eklerken
- ❌ Mesaj yazarken
- ❌ Kritik işlemler sırasında
- ❌ Uygulamayı her açışta

**Gelir Potansiyeli:** Yüksek ama kullanıcı memnuniyeti riski var

---

### **D. Native (Yerel) Reklamlar (Öncelik: ORTA)**
**Yerleşim:**
- Seyir defteri listesi içinde (feed içinde doğal görünüm)
- Kategoriler arasında
- **Önemli:** "Reklam" etiketi zorunlu

**Gelir Potansiyeli:** Orta-Yüksek

---

## 💰 Gelir Maksimizasyon Stratejileri

### **1. Coğrafi Segmentasyon**
- **Türkiye:** Banner + Native ağırlıklı
- **ABD/AB:** Video reklam ağırlıklı (yüksek eCPM)
- **Diğer:** Hibrit

### **2. Kullanıcı Segmentasyonu**
- **Yeni kullanıcılar (ilk 3 gün):** Daha az reklam (onboarding)
- **Aktif kullanıcılar:** Standart reklam yoğunluğu
- **Premium abone adayları:** Ödüllü reklam gösterimi

### **3. Zaman Bazlı Optimizasyon**
- **Pazartesi-Salı:** Daha fazla reklam (iş günü, kullanım yoğun)
- **Hafta sonu:** Daha az reklam (kullanıcı deneyimi öncelikli)

### **4. A/B Testleri**
- Farklı reklam yerleşimleri test edin
- Kullanıcı memnuniyeti vs. gelir dengesini ölçün
- Firebase Analytics ile takip edin

---

## 🔧 Teknik Entegrasyon Detayları

### **Gerekli Paketler:**
```yaml
dependencies:
  google_mobile_ads: ^5.1.0  # AdMob SDK - reklam entegrasyonu için
  in_app_purchase: ^3.2.0    # İsteğe bağlı: Premium abonelik için
```

### **Android Ayarları:**
1. `AndroidManifest.xml`'e AdMob App ID eklenmeli
2. `build.gradle`'a AdMob bağımlılığı eklenmeli
3. Google Play Console'da uygulama kaydedilmeli

### **iOS Ayarları:**
1. `Info.plist`'e AdMob App ID eklenmeli
2. App Store Connect'te uygulama kaydedilmeli
3. Privacy manifest güncellenmeli (iOS 17+)

---

## ⚠️ KRİTİK DİKKAT NOKTALARI

### **1. Kullanıcı Deneyimi (UX)**
- ✅ **Asla reklam duvarı oluşturmayın**
- ✅ Kritik işlemler sırasında reklam göstermeyin
- ✅ "Reklam" etiketini her zaman görünür yapın
- ✅ Reklam hatalarında uygulama çökmemeli (try-catch)

### **2. Yasal Uyumluluk**
- ✅ **GDPR/KVKK:** Kullanıcı onayı alın (AdMob otomatik yapar)
- ✅ **Çocuk Koruma:** Uygulamanız 13+ ise, AdMob'da "Çocuklar için tasarlanmamıştır" işaretleyin
- ✅ **Kullanım Şartları:** Terms & Conditions'a reklam politikasını ekleyin

### **3. Performans**
- ✅ Reklamları lazy load yapın (sadece görünür olacakları yükle)
- ✅ Cache mekanizması kullanın
- ✅ Network durumuna göre reklam formatı seçin (düşük hız → banner, yüksek hız → video)

### **4. Test**
- ✅ AdMob Test Ad Units kullanın (geliştirme aşamasında)
- ✅ Gerçek cihazlarda test edin (emulator'da bazen çalışmaz)
- ✅ Farklı cihaz boyutlarında test edin

---

## 📈 Beklenen Gelir Tahmini

**Türkiye Pazarı:**
- Banner: ~$0.50-1.50 eCPM (1000 gösterim başına)
- Interstitial: ~$2-5 eCPM
- Ödüllü Video: ~$3-8 eCPM

**Örnek Senaryo:**
- Günlük aktif kullanıcı: 1,000
- Kullanıcı başına günlük gösterim: 10 banner + 2 interstitial + 1 video
- Toplam gösterim: 10,000 banner + 2,000 interstitial + 1,000 video
- Aylık gelir: ~$150-400 (Türkiye), ~$500-1,500 (ABD/AB)

**Not:** Bu rakamlar tahminidir. Gerçek gelir, kullanıcı sayısı, coğrafya, reklam doluluk oranı gibi faktörlere bağlıdır.

---

## 🎁 Alternatif/Hibrit Modeller

### **1. Premium Abonelik (Subscription)**
- **Reklamsız deneyim:** Aylık/Yıllık abonelik
- **Fiyatlandırma:** ₺49.99/ay veya ₺399.99/yıl
- **Platform:** Google Play Billing / Apple In-App Purchase

**Strateji:** 
- Hem reklam hem premium sunun
- Premium kullanıcılar reklam görmez
- Geliri çeşitlendirin

### **2. İç Reklam Sistemi (Mevcut) + Dış Reklam (Yeni)**
- Mevcut `reklam_yonetim_page.dart` sistemi korunur
- AdMob reklamları ek olarak gösterilir
- İç reklamlar (sponsorlu içerik) + Dış reklamlar (AdMob) birlikte çalışır

---

## 🚀 UYGULAMA ÖNCELİKLENDİRME

### **Faz 1: MVP (Minimum Viable Product) - İlk 2 Hafta**
1. ✅ AdMob hesabı açılması
2. ✅ Banner reklamlar (Ana sayfa + Kategori sayfaları)
3. ✅ Test reklam birimleri ile test
4. ✅ Hata yönetimi

### **Faz 2: Genişletme - 1. Ay**
1. ✅ Ödüllü video reklamlar (Premium özellik kilidi)
2. ✅ Interstitial reklamlar (dikkatli yerleşim)
3. ✅ Analytics entegrasyonu
4. ✅ A/B testleri başlatma

### **Faz 3: Optimizasyon - 2-3. Ay**
1. ✅ Native reklamlar
2. ✅ Coğrafi segmentasyon
3. ✅ Premium abonelik seçeneği (isteğe bağlı)
4. ✅ Gelir optimizasyonu

---

## 📝 SONUÇ VE TAVSİYE

**En İyi Yaklaşım:**
1. **AdMob** ile başlayın (güvenilir, Flutter uyumlu)
2. **Banner reklamlar** ile başlayın (düşük risk, kabul edilebilir gelir)
3. **Ödüllü video reklamlar** ekleyin (yüksek gelir, kullanıcı memnuniyeti yüksek)
4. **Interstitial'ları dikkatli kullanın** (kullanıcı deneyimini bozmayın)
5. **Premium abonelik** ekleyin (uzun vadede daha karlı)

**Altın Kural:** 
> "Kullanıcı memnuniyeti > Kısa vadeli gelir"
> 
> Bir kullanıcı uygulamayı silerse, o kullanıcıdan gelecek tüm gelir kaybolur. 
> Kısa vadede az gelir, uzun vadede sadık kullanıcı kitlesi her zaman daha değerlidir.

---

## 📚 Ek Kaynaklar

- [AdMob Flutter Dokümantasyonu](https://developers.google.com/admob/flutter/start)
- [AdMob Politikaları](https://support.google.com/admob/answer/6128543)
- [GDPR Uyumluluk Rehberi](https://support.google.com/admob/answer/7666366)
- [Reklam Yerleşim En İyi Uygulamaları](https://support.google.com/admob/answer/6329638)

---

**Hazırlayan:** AI Asistan  
**Tarih:** 2025  
**Versiyon:** 1.0



