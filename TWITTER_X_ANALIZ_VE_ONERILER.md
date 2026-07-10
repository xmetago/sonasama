# WhoBoom (its19) Proje Analizi ve Twitter/X Entegrasyon Önerileri

## 1. Proje Özeti

**WhoBoom (its19)** Flutter tabanlı bir mobil uygulama. Temalar:

- **Dava / yargıç simülasyonu**: Davalar, deliller, hükümler, halk kararı, davetler
- **Sosyal feed**: Ana sayfada Twitter/X benzeri post akışı (Haykır, post, like, retweet, yorum, medya, anket)
- **Kullanıcı yönetimi**: Kayıt, giriş, admin, arkadaş kategorileri, mesajlaşma (Firebase + Hive)
- **Yerel + bulut**: Hive (yerel), Firebase (Core, Firestore, Messaging, Storage)

### Mevcut “Twitter benzeri” yapı

| Özellik | Durum |
|--------|--------|
| Post composer (280 karakter) | ✅ `TwitterPostComposer` |
| Post kartı (like, retweet, yorum, paylaş) | ✅ `TwitterPostCard` |
| Medya (resim/video), anket | ✅ Var |
| Feed saklama | ✅ Hive, kullanıcı bazlı `home_feed_box` |
| Gerçek Twitter/X API | ❌ Yok; tüm veri uygulama içi |

Yani ürün zaten “Twitter tarzı” bir deneyim sunuyor; veri şu an tamamen uygulama içi.

---

## 2. Twitter/X ile İlişkilendirme Önerileri

### A. Öncelikli: “Twitter’a Paylaş” (Share to X)

**Ne yapar:** Kullanıcı bir Haykır/post oluşturduğunda veya bir dava/hüküm paylaşmak istediğinde “Twitter’da paylaş” ile metin + link X’e gider.

**Avantaj:** Resmi Twitter API’ye (ücretli) gerek yok; sadece Web Intent / `url_launcher` yeterli.

**Teknik:**

- **Android:** `https://twitter.com/intent/tweet?text=...&url=...`
- **iOS:** Aynı URL veya `twitter://post?message=...` (varsa)
- Projede zaten `url_launcher` var; yeni bir ekran veya `TwitterPostCard` / paylaş menüsüne “X’te paylaş” eklenebilir.

**Öneri:** `lib/utils/twitter_share_utils.dart` gibi bir yardımcı sınıf; metni 280 karaktere kırpıp, deep link (dava/haykır sayfası) ekleyerek URL oluştursun.

---

### B. Twitter/X ile Giriş (Sign in with X)

**Ne yapar:** “X ile giriş yap” ile kullanıcı kimliği alınır; e-posta yerine veya e-posta ile birlikte kullanılabilir.

**Gereksinim:** Twitter/X OAuth 2.0 (PKCE). Developer Portal’da uygulama + Client ID gerekir.

**Flutter:** Resmi Twitter paketi yok; `oauth2` veya `app_write` benzeri OAuth paketleri veya kendi OAuth 2.0 akışınız (WebView / in-app browser) kullanılabilir.

**Öneri:** Önce “Twitter’a paylaş” ile başlayın; kimlik doğrulama sonra eklenebilir. Giriş yapan X kullanıcısı için `RegistrationModel`’e `twitterUserId`, `twitterUsername` alanları eklenebilir.

---

### C. Post/Haykır’ı X’e Cross-Post (Tweet olarak atma)

**Ne yapar:** Uygulama içi “Post” veya “Haykır” butonuna basıldığında aynı metin (ve isteğe bağlı medya) X’te de bir tweet olarak yayınlanır.

**Gereksinim:** Twitter API v2 “Create Tweet” (ve varsa medya upload). **Ücretli** (Free tier çok kısıtlı; Basic/Pro gerekebilir).

**Mimari:**  
Backend (Cloud Functions / kendi sunucunuz) gerekir: Flutter → kendi API’nız → Twitter API. API anahtarları ve token’lar asla uygulama içinde tutulmamalı.

**Öneri:** Orta/uzun vadeli hedef. Önce “Share to X” ile kullanıcı kendi paylaşsın; sonra “İstersen X’e de otomatik at” seçeneği eklenebilir.

---

### D. X’ten Veri Çekme (Timeline, trend, arama)

**Ne yapar:** X’ten tweet’ler, trendler veya arama sonuçları uygulama içinde gösterilir (ör. “Bu dava X’te ne konuşuluyor?”).

**Gereksinim:** Twitter API v2 (Read) – yine ücretli plan gerekebilir.

**Mevcut proje:** `trend_engagement_service.dart` ve `trend_insights_page` zaten “trend” ve etkileşim kavramlarına sahip; bunlar şu an uygulama içi. İleride X’ten gelen trend/etkileşim verisi bu yapıya bağlanabilir.

**Öneri:** Uzun vadeli. Önce kendi feed’inizi ve trend yapınızı güçlendirin; API maliyeti ve politika değişiklikleri nedeniyle X verisi “ek kanal” olarak planlanabilir.

---

### E. Veri Modeli ve Senkronizasyon

Twitter/X ile ilişkiyi büyütmek için:

- **Post/Haykır modeli:**  
  - `twitterTweetId`, `twitterUserId`, `postedToTwitterAt` gibi alanlar eklenebilir.  
  - Böylece “Bu haykır X’te de paylaşıldı” ve ileride silme/güncelleme senkronu düşünülebilir.
- **Kullanıcı modeli:**  
  - `twitterUserId`, `twitterUsername`, `twitterDisplayName` (Sign in with X için).
- **Saklama:** Mevcut Hive yapısı aynen kalabilir; sadece ek alanlar. Firestore’da da aynı alanlar tutulursa çok cihaz / web senkronu kolaylaşır.

---

## 3. Teknik Uygulama Önerileri

### Hemen yapılabilecekler (API gerekmez)

1. **Twitter/X paylaşım yardımcısı**
   - `lib/utils/twitter_share_utils.dart`
   - `shareToTwitter(String text, {String? url})` → `url_launcher` ile intent/URL açma
   - Metni 280 karaktere kırpma; link için kısaltılmış alan (deep link veya web sayfanız)

2. **UI’da “X’te paylaş”**
   - `TwitterPostCard` ve Haykır kartlarındaki “Paylaş” butonuna “X’te paylaş” seçeneği
   - Mümkünse “Dava linki” veya “Haykır linki” (ileride web/backend ile desteklenebilir)

3. **Dil / metin**
   - “What’s happening?” gibi metinler Türkçe’ye çevrilebilir (örn. “Ne oluyor?”) veya uygulama diline göre seçilebilir.

### Kısa vade (backend + Twitter Developer hesabı)

4. **Sign in with X**
   - Developer Portal’da uygulama, OAuth 2.0 PKCE
   - Backend’de token exchange; Flutter’da WebView veya browser tab ile OAuth akışı
   - `RegistrationModel` ve auth akışına X hesabı eşlemesi

5. **Post modeli genişletmesi**
   - `twitterTweetId`, `postedToTwitterAt` (ve isteğe bağlı `twitterUserId`) eklenmesi; böylece ileride “X’e de at” özelliği temiz veriyle geliştirilebilir.

### Orta / uzun vade

6. **Backend + “Create Tweet”**
   - Sunucu veya Cloud Functions ile Twitter API v2 Create Tweet (ve medya) çağrısı
   - Sadece “X’e de gönder” seçeneği olan kullanıcılar için; rate limit ve hata yönetimi

7. **X’ten veri (trend / arama)**
   - API v2 ile trend veya arama; mevcut `TrendEngagementService` / trend sayfalarına “X’ten gelen” veri kanalı olarak eklenebilir.

---

## 4. Dikkat Edilmesi Gerekenler

- **API maliyeti:** Twitter/X API ücretli; Free tier sınırlı. Bütçe ve kullanım senaryosuna göre Basic/Pro plan değerlendirilmeli.
- **Gizlilik ve kurallar:** X’e gönderilen/gösterilen içerik, kullanıcı onayı ve gizlilik politikası ile uyumlu olmalı; Developer Agreement ve politika metinleri okunmalı.
- **Anahtarlar:** API key/secret ve kullanıcı token’ları sadece backend’de; Flutter tarafında sadece kendi backend’inize yapılan istekler olsun.
- **PROJECT_RULES.md:** Yeni özellikler `lib/screens/`, `lib/widgets/`, `lib/services/` altında ve mevcut arayüze “ekleme” şeklinde yapılmalı; ana sayfa/login’de izin verilenler dışında görsel değişiklik yapılmamalı.

---

## 5. Özet Eylem Planı

| Öncelik | Öneri | Bağımlılık |
|--------|--------|------------|
| 1 | “X’te paylaş” butonu + `twitter_share_utils` (URL intent) | Yok |
| 2 | Post/Haykır modeline `twitterTweetId`, `postedToTwitterAt` alanları | Yok (ileride API için hazırlık) |
| 3 | Sign in with X (OAuth 2.0) | Twitter Developer hesabı + backend |
| 4 | “Bu haykırı X’e de gönder” (Create Tweet) | Backend + Twitter API ücretli plan |
| 5 | X’ten trend/etkileşim verisi | Backend + Twitter API ücretli plan |

Bu sıra, önce kullanıcı değeri (paylaşım) ve veri modeli hazırlığını getirir; ardından kimlik doğrulama ve tam entegrasyon eklenebilir.

---

*Bu doküman WhoBoom (its19) projesinin Twitter/X ile ilişkilendirilmesi için analiz ve önerileri içerir. Uygulama detayları proje kurallarına ve güncel Twitter/X politikalarına göre güncellenmelidir.*
