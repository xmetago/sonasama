# Firebase Kurulum Rehberi

## 🔥 Real-Time Mesajlaşma için Firebase Kurulumu

Uygulama şu anda Firebase Firestore ile real-time mesajlaşma desteğine sahip. Firebase kurulumu **opsiyoneldir** - Firebase yapılandırması olmadan da uygulama çalışır (Hive offline mode).

### 📋 Adımlar

#### 1. Firebase Console'da Proje Oluştur

1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. "Add project" (Proje Ekle) butonuna tıklayın
3. Proje adını girin ve "Continue" (Devam) tıklayın
4. Google Analytics'i etkinleştirin (opsiyonel)
5. "Create project" (Proje Oluştur) tıklayın

#### 2. Android Uygulaması Ekle

1. Firebase Console'da projenizi seçin
2. Android ikonuna tıklayın
3. **Package name**: `com.example.its19` (android/app/build.gradle dosyasındaki applicationId'yi kontrol edin)
4. App nickname (opsiyonel) girin
5. "Register app" (Uygulamayı Kaydet) tıklayın
6. `google-services.json` dosyasını indirin
7. Dosyayı `android/app/` klasörüne kopyalayın

#### 3. iOS Uygulaması Ekle (Opsiyonel)

1. Firebase Console'da iOS ikonuna tıklayın
2. **Bundle ID**: iOS bundle identifier'ınızı girin
3. "Register app" tıklayın
4. `GoogleService-Info.plist` dosyasını indirin
5. Dosyayı `ios/Runner/` klasörüne kopyalayın

#### 4. FlutterFire CLI ile Yapılandırma

```bash
# FlutterFire CLI'yi yükle
dart pub global activate flutterfire_cli

# Firebase'i yapılandır
flutterfire configure
```

Bu komut:
- Firebase projenizi seçmenizi ister
- Platformları (Android, iOS, Web) seçmenizi ister
- `lib/firebase_options.dart` dosyasını oluşturur

#### 5. Android Gradle Yapılandırması

`android/build.gradle` dosyasına ekleyin:

```gradle
buildscript {
    dependencies {
        // Firebase için Google Services plugin
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

`android/app/build.gradle` dosyasının en altına ekleyin:

```gradle
apply plugin: 'com.google.gms.google-services'
```

#### 6. Firestore Veritabanı Oluştur

1. Firebase Console'da "Firestore Database" seçin
2. "Create database" (Veritabanı Oluştur) tıklayın
3. **Test mode** seçin (geliştirme için)
4. Location seçin (örn: `europe-west`)
5. "Enable" (Etkinleştir) tıklayın

#### 7. Firestore Güvenlik Kuralları

Firebase Console > Firestore Database > Rules sekmesinde:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Mesajlar koleksiyonu
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Konuşmalar koleksiyonu
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Not:** Production için daha sıkı kurallar kullanın!

#### 8. Firebase Storage Güvenlik Kuralları

Firebase Console > Storage > Rules sekmesinde ses dosyaları için kurallar ekleyin:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Sesli mesajlar için kurallar
    match /audio_messages/{conversationId}/{messageId} {
      // Herkes okuyabilir (mesaj alıcıları için)
      allow read: if true;
      
      // Herkes yazabilir (geliştirme için - production'da daha sıkı kurallar kullanın)
      allow write: if request.resource.size < 10 * 1024 * 1024  // Max 10MB
                    && request.resource.contentType.matches('audio/.*');
      
      // Production için örnek (authentication gerekli):
      // allow write: if request.auth != null
      //               && request.resource.size < 10 * 1024 * 1024
      //               && request.resource.contentType.matches('audio/.*');
    }
    
    // Diğer dosyalar için varsayılan kurallar
    match /{allPaths=**} {
      allow read, write: if false;  // Varsayılan olarak erişim yok
    }
  }
}
```

**Önemli Notlar:**
- `allow read: if true;` - Herkes ses dosyalarını okuyabilir (mesaj alıcıları için)
- `allow write` - Dosya boyutu max 10MB ve audio content type kontrolü
- Production için authentication ekleyin: `request.auth != null`

#### 9. Firebase Authentication (Opsiyonel)

Mesajlaşma için authentication gerekli değil (şu an), ancak gelecekte eklenebilir.

### ✅ Kurulum Kontrolü

Uygulamayı çalıştırdığınızda konsolda şunu görmelisiniz:

```
✅ Firebase başlatıldı
```

Eğer Firebase yapılandırması yoksa:

```
⚠️ Firebase başlatılamadı (opsiyonel): ...
💡 Firebase kullanmak için firebase_options.dart dosyası gerekli
```

Bu durumda uygulama Hive offline mode ile çalışmaya devam eder.

### 🔄 Hibrit Yaklaşım

Uygulama **hibrit** bir yaklaşım kullanıyor:

- **Firestore**: Real-time mesajlaşma ve senkronizasyon
- **Hive**: Offline cache ve fallback

Bu sayede:
- ✅ İnternet varsa: Real-time mesajlaşma (Firestore)
- ✅ İnternet yoksa: Offline mesajlaşma (Hive)
- ✅ Otomatik senkronizasyon: İnternet geldiğinde mesajlar senkronize olur

### 📱 Test Etme

1. İki farklı cihazda/emülatörde uygulamayı açın
2. Farklı kullanıcılarla giriş yapın
3. Birbirleriyle mesajlaşın
4. Mesajların real-time olarak göründüğünü kontrol edin

### 🐛 Sorun Giderme

**Firebase başlatılamıyor:**
- `firebase_options.dart` dosyasının `lib/` klasöründe olduğundan emin olun
- `google-services.json` dosyasının `android/app/` klasöründe olduğundan emin olun
- `flutter clean` ve `flutter pub get` çalıştırın

**Mesajlar görünmüyor:**
- Firestore veritabanının oluşturulduğundan emin olun
- Firestore kurallarının doğru olduğundan emin olun
- İnternet bağlantısını kontrol edin

**Build hatası:**
- Android Gradle yapılandırmasını kontrol edin
- `google-services.json` dosyasının doğru yerde olduğundan emin olun

**Ses dosyası yüklenemiyor:**
- Firebase Storage'ın etkinleştirildiğinden emin olun (Firebase Console > Storage > Get Started)
- Firebase Storage Security Rules'ın doğru yapılandırıldığından emin olun (yukarıdaki kuralları kontrol edin)
- İnternet bağlantısını kontrol edin
- Dosya boyutunun 10MB'dan küçük olduğundan emin olun
- Konsol loglarını kontrol edin (detaylı hata mesajları için)

### 📚 Daha Fazla Bilgi

- [Firebase Flutter Dokümantasyonu](https://firebase.flutter.dev/)
- [Cloud Firestore Dokümantasyonu](https://firebase.google.com/docs/firestore)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

