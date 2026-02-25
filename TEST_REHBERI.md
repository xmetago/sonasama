# 🧪 Açtığım Davalar Sayfası Test Rehberi

## 📋 Test Senaryosu

### ✅ Adım 1: Uygulamayı Çalıştırma
```bash
flutter run
```

### ✅ Adım 2: Dava Açma İşlemi

1. **Giriş Yap**
   - Uygulamaya giriş yapın (kullanıcı email'i gerekli)

2. **Dava Aç Butonuna Bas**
   - Ana sayfada veya ilgili sayfada `lib/icons/03_davala_ana_icon.png` butonuna tıklayın
   - 19 saatlik süre kontrolü varsa bekleyin veya test için süreyi atlayın

3. **Kategori Seç**
   - Bir kategori seçin (zorunlu)

4. **Dava Bilgilerini Doldur**
   - Dava Adı: En az 6 karakter (örn: "Test Dava Açma")
   - Davalı: Bir isim girin
   - Dava Konusu: En az 285 karakter yazın

5. **DAVA ATA Butonuna Bas**
   - Formu doldurduktan sonra "DAVA ATA" butonuna tıklayın
   - Grup seçimi yapın (Grup19, Arkadaşlar, vb.)

### ✅ Adım 3: Açtığım Davalar Sayfasını Kontrol

1. **Sayfaya Git**
   - Sol menüden veya ilgili ikondan "Açtığım Davalar" sayfasına gidin
   - Veya `ActigimDavalarPage` sayfasına direkt gidin

2. **Kontrol Edilecekler:**

#### 🎯 Görev Alanı Kontrolü
- ✅ **Görev** alanı her zaman **"Davacı"** olarak görünmeli
- ❌ "Davalı" veya başka bir değer görünmemeli

#### ⏰ Kalan Süre Kontrolü
- ✅ **Kalan Süre** alanı görünmeli
- ✅ 168 saatten geriye doğru saymalı (örn: "167 saat 59 dakika")
- ✅ Her saniye güncellenmeli
- ✅ 168 saat dolunca **"İlelebet Bitti"** yazmalı
- ✅ Süre dolduğunda kırmızı renkte gösterilmeli

#### ⚖️ Hüküm Durumu Kontrolü
- ✅ **Hüküm** alanı görünmeli
- ✅ Başlangıçta **"Beklemede"** yazmalı (turuncu renk)
- ✅ Yargıç yorum yapınca güncellenmeli:
  - **"Haklı Davacı"** (yeşil) - Olumlu hükümler fazlaysa
  - **"Haklı Davalı"** (kırmızı) - Olumsuz hükümler fazlaysa

#### 🎨 Modern UI Kontrolü
- ✅ Kart tasarımı modern ve profesyonel görünmeli
- ✅ Animasyonlar çalışmalı (açılış/kapanış)
- ✅ Renkler doğru olmalı (mavi, yeşil, turuncu, kırmızı)
- ✅ "Detayları Göster" butonuna tıklayınca genişlemeli
- ✅ Genişletilmiş görünümde:
  - Dava Konusu görünmeli
  - Yargıç Kararları (olumlu/olumsuz sayıları) görünmeli
  - Dava ID görünmeli

### ✅ Adım 4: Hüküm Durumunu Test Etme

1. **8 Hüküm Sayfasına Git**
   - Açtığınız davaya tıklayın
   - 8 Hüküm sayfasına gidin

2. **Hüküm Ver**
   - Bir yargıç olarak hüküm yazın
   - Olumlu veya olumsuz seçin

3. **Açtığım Davalar Sayfasına Dön**
   - Geri dönün ve sayfayı yenileyin
   - Hüküm durumunun güncellendiğini kontrol edin

### ✅ Adım 5: Geri Sayım Testi (Hızlı Test)

Geri sayımı hızlı test etmek için test kodu ekleyebilirsiniz:

```dart
// Test için: openedAt tarihini 167 saat öncesine ayarlayın
// Böylece 1 saat kalan süre görebilirsiniz
```

## 🐛 Debug İpuçları

### Konsol Çıktıları
Uygulamayı çalıştırırken konsolda şunları kontrol edin:
- `✅ Veritabanına kaydediliyor...`
- `✅ Kalıcı olarak saklanıyor...`
- `✅ Uygulama yeniden başlatıldığında korunuyor...`

### Veritabanı Kontrolü
```dart
// Debug için konsola yazdırma
print('Dava ID: ${dava.id}');
print('OpenedAt: ${davaData['openedAt']}');
print('Kalan Süre: ${_remainingTime}');
print('Hüküm Durumu: ${_getHukumStatus()}');
```

## ⚠️ Bilinen Sorunlar ve Çözümler

### Sorun 1: Kalan Süre Görünmüyor
**Çözüm:** `openedAt` tarihinin veritabanında kayıtlı olduğundan emin olun.

### Sorun 2: Hüküm Durumu "Beklemede" Kalıyor
**Çözüm:** 
- Yargıçların hüküm verdiğinden emin olun
- Consensus evaluation'ın çalıştığını kontrol edin
- `DavaConsensusService.evaluateConsensus` fonksiyonunu test edin

### Sorun 3: Geri Sayım Çalışmıyor
**Çözüm:**
- Timer'ın başlatıldığını kontrol edin
- `_remainingTime` değerinin null olmadığını kontrol edin
- `openedAt` tarihinin geçerli bir DateTime olduğunu kontrol edin

## 📝 Test Checklist

- [ ] Dava açma işlemi başarılı
- [ ] Görev alanı "Davacı" olarak görünüyor
- [ ] Kalan süre 168 saatten geriye sayıyor
- [ ] Kalan süre her saniye güncelleniyor
- [ ] 168 saat dolunca "İlelebet Bitti" yazıyor
- [ ] Hüküm durumu başlangıçta "Beklemede"
- [ ] Hüküm verilince durum güncelleniyor
- [ ] Modern UI tasarımı doğru görünüyor
- [ ] Animasyonlar çalışıyor
- [ ] Detaylar genişletilince görünüyor

## 🎯 Hızlı Test Komutları

```bash
# Uygulamayı çalıştır
flutter run

# Hot reload (değişiklikleri anında görmek için)
# Terminal'de 'r' tuşuna basın

# Hot restart (tam yeniden başlatma)
# Terminal'de 'R' tuşuna basın

# Debug modunda çalıştır
flutter run --debug

# Release modunda çalıştır (performans testi)
flutter run --release
```

