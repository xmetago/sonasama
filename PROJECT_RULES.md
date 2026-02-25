# WhoBoom Proje Kuralları ve Standartları

## 📋 Genel Proje Kuralları

### 🚫 Kesinlikle Yasak Olanlar
- **Mevcut arayüzde hiçbir değişiklik yapılamaz**
- **Ana dosyalarda (main.dart, home.dart, login.dart) görsel değişiklik yasak**
- **Mevcut widget'ların yapısı değiştirilemez**
- **Row, Column gibi yapısal elemanlar silinemez**

### ✅ İzin Verilen İşlemler
- Yeni sayfa ekleme (`lib/screens/` altına)
- Yeni widget ekleme (`lib/widgets/` altına)
- Yeni model sınıfları ekleme (`lib/models/` altına)
- Yeni servis sınıfları ekleme (`lib/services/` altına)
- Yeni bağımlılık ekleme (pubspec.yaml'da açıklama ile)

## 🏗️ Mimari Kuralları

### Dizin Yapısı
```
lib/
├── screens/          # Sayfa bileşenleri
├── widgets/          # Yeniden kullanılabilir widget'lar
├── models/           # Veri modelleri
├── services/         # İş mantığı servisleri
├── data/             # Statik veriler
├── icons/            # Özel ikonlar
└── fonts/            # Özel fontlar
```

### Dosya Adlandırma
- **Sayfalar**: `snake_case` (örn: `user_profile.dart`)
- **Widget'lar**: `snake_case` (örn: `custom_button.dart`)
- **Model'ler**: `PascalCase` (örn: `UserModel.dart`)
- **Servis'ler**: `snake_case` (örn: `auth_service.dart`)

## 🎨 UI/UX Standartları

### Tasarım Prensipleri
- **Material 3** tasarım sistemi kullanılır
- **Responsive** tasarım zorunludur
- **Erişilebilirlik** standartları uygulanır
- **Tutarlı** renk paleti ve tipografi kullanılır

### Widget Kuralları
- Her widget için açıklayıcı yorumlar eklenir
- `const` constructor kullanımı tercih edilir
- Widget'lar mümkün olduğunca küçük ve odaklanmış olur
- State management için Provider/Riverpod kullanılır

## 🔧 Kod Kalitesi Kuralları

### Genel Kod Standartları
```dart
// ✅ Doğru kullanım
class UserService {
  Future<User?> getUserById(String id) async {
    try {
      // İş mantığı
      return user;
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}

// ❌ Yanlış kullanım
class UserService {
  Future<User?> getUserById(String id) async {
    // Hata yönetimi yok
    return user;
  }
}
```

### Hata Yönetimi
- Tüm `Future<void>` işlemleri try-catch ile sarılır
- Kullanıcı dostu hata mesajları gösterilir
- Network hataları uygun şekilde ele alınır

### Performans Kuralları
- `print()` ve `debugPrint()` production'da kullanılmaz
- Gereksiz rebuild'ler önlenir
- Büyük listeler için `ListView.builder` kullanılır
- Image caching uygulanır

## 🔐 Güvenlik Kuralları

### Veri Güvenliği
- Hassas veriler şifrelenir
- API anahtarları güvenli şekilde saklanır
- Kullanıcı verileri yerel olarak güvenli şekilde depolanır

### Kimlik Doğrulama
- Admin e-postası: `whoboom@whoboom.com`
- Admin sayfalarına sadece admin erişebilir
- Session yönetimi güvenli şekilde yapılır

## 📱 Özellik Geliştirme Kuralları

### Yeni Özellik Ekleme
1. **Planlama**: Özellik detayları dokümante edilir
2. **Tasarım**: UI/UX tasarımı onaylanır
3. **Geliştirme**: Kod yazılır ve test edilir
4. **Test**: Kapsamlı test yapılır
5. **Deploy**: Production'a güvenli şekilde deploy edilir

### Veritabanı Kuralları
- **Hive** veritabanı kullanılır
- Veritabanı şeması dokümante edilir
- Migration stratejisi planlanır
- Backup stratejisi uygulanır

## 🧪 Test Kuralları

### Test Kapsamı
- Unit testler yazılır
- Widget testleri uygulanır
- Integration testleri yapılır
- Test coverage %80'in üzerinde olur

### Test Yazma Standartları
```dart
// ✅ Test örneği
void main() {
  group('UserService Tests', () {
    test('should return user when valid id provided', () async {
      // Test kodu
    });
  });
}
```

## 📦 Bağımlılık Yönetimi

### Yeni Bağımlılık Ekleme
```yaml
# pubspec.yaml
dependencies:
  # Yeni bağımlılık ekleme örneği
  http: ^1.1.0  # API istekleri için
  provider: ^6.1.1  # State management için
```

### Bağımlılık Kuralları
- Sadece gerekli bağımlılıklar eklenir
- Her bağımlılık için açıklama yazılır
- Güncel ve güvenli sürümler kullanılır
- Bağımlılık çakışmaları kontrol edilir

## 🚀 Deployment Kuralları

### Build Kuralları
- Release build'ler optimize edilir
- Asset'ler sıkıştırılır
- Bundle boyutu kontrol edilir
- Performance profiling yapılır

### Store Deployment
- App Store ve Google Play Store kurallarına uyulur
- Privacy policy güncel tutulur
- Version management düzenli yapılır

## 📝 Dokümantasyon Kuralları

### Kod Dokümantasyonu
- Her public method için dartdoc yazılır
- README dosyası güncel tutulur
- API dokümantasyonu hazırlanır
- Change log tutulur

### Örnek Dokümantasyon
```dart
/// Kullanıcı bilgilerini getirir
/// 
/// [id] Kullanıcı ID'si
/// Returns [User] kullanıcı bilgileri veya null
Future<User?> getUserById(String id) async {
  // Implementation
}
```

## 🔄 Versiyon Kontrol Kuralları

### Git Kuralları
- Anlamlı commit mesajları yazılır
- Feature branch'ler kullanılır
- Pull request'ler review edilir
- Merge conflict'ler dikkatli çözülür

### Commit Mesaj Formatı
```
feat: yeni özellik eklendi
fix: hata düzeltildi
docs: dokümantasyon güncellendi
style: kod formatı düzeltildi
refactor: kod yeniden düzenlendi
test: test eklendi
chore: bakım işlemi
```

## 🎯 Proje Hedefleri

### Kısa Vadeli (1-2 hafta)
- [ ] Mevcut özelliklerin stabilizasyonu
- [ ] Bug fix'lerin tamamlanması
- [ ] Performance optimizasyonu

### Orta Vadeli (1-2 ay)
- [ ] Yeni özelliklerin eklenmesi
- [ ] UI/UX iyileştirmeleri
- [ ] Test coverage artırılması

### Uzun Vadeli (3-6 ay)
- [ ] Ölçeklenebilir mimari
- [ ] Advanced özellikler
- [ ] Platform genişletme

## ⚠️ Önemli Notlar

1. **Bu kurallar değiştirilemez** - Sadece ekleme yapılabilir
2. **Her değişiklik dokümante edilir**
3. **Test coverage korunur**
4. **Performance monitör edilir**
5. **Güvenlik öncelikli tutulur**

---

*Bu kurallar WhoBoom projesinin kalitesini ve sürdürülebilirliğini sağlamak için oluşturulmuştur.*
