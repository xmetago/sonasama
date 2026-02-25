import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter için
import 'package:flutter_localizations/flutter_localizations.dart'; // Türkçe locale için
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:country_picker/country_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl; // Türkçe locale için
import 'package:its19/screens/forgot_password_page.dart';
import 'package:its19/screens/home_page.dart';
import 'package:its19/screens/privacy_policy_page.dart';
import 'package:flutter/gestures.dart';
import 'package:its19/screens/terms_conditions_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/services/friend_category_service.dart';
import 'package:its19/services/chat_service.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/providers/auth_provider.dart';
import 'package:its19/providers/dava_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:its19/services/local_notification_service.dart';
import 'package:its19/utils/timeago_helper.dart';
import 'package:its19/utils/app_theme.dart';
import 'package:its19/utils/country_display_utils.dart';
import 'package:its19/utils/country_picker_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Flutter binding'i başlat (dosya sistemi ve async işlemler için gerekli)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat (opsiyonel - Firebase yapılandırması yoksa hata vermez)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase başlatıldı');
  } catch (e) {
    print('⚠️ Firebase başlatılamadı (opsiyonel): $e');
    print('💡 Firebase kullanmak için firebase_options.dart dosyası gerekli');
  }
  
  // Hive veritabanını başlat
  await HiveDatabaseService.initialize();
  
  // Açılmış tüm davaları sil
  HiveDatabaseService.clearOpenedDavalar();
  print('✅ Tüm açılmış davalar silindi!');
  
  // FriendCategoryService'i başlat
  await FriendCategoryService.initialize();
  
  // ChatService'i başlat
  await ChatService.initialize();
  
  // Yerel bildirim servisini başlat
  await LocalNotificationService.initialize();
  
  // Bildirim izinlerini iste
  await LocalNotificationService.requestPermissions();
  
  // Timeago'yu Türkçe olarak başlat
  TimeAgoHelper.initialize();
  
  // Provider'ları MultiProvider ile sarmalayarak uygulamayı başlat
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DavaProvider()),
      ],
      child: const WhoBoomApp(),
    ),
  );
  
  // Test kullanıcılarını arka planda ekle (UI bloklanmasın)
  _initializeTestDataInBackground();
}

/// Test verilerini arka planda yükler
/// UI thread'i bloklamadan test kullanıcıları ve ayarları oluşturur
/// İşlemleri küçük parçalara bölerek UI thread'ine nefes alma fırsatı verir
Future<void> _initializeTestDataInBackground() async {
  try {
    print('📦 Arka planda test verileri yükleniyor...');
    
    // UI thread'ine nefes alma fırsatı ver
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Test kullanıcılarını ekle
    await _addTestUsers();
    
    // UI thread'ine nefes alma fırsatı ver
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Mevcut tüm kullanıcılar için varsayılan ayarları oluştur
    await HiveDatabaseService.createDefaultSettingsForAllUsers();
    
    // UI thread'ine nefes alma fırsatı ver
    await Future.delayed(const Duration(milliseconds: 50));
    
    // whoboom@whoboom.com kullanıcısı için test arkadaş kategorileri oluştur
    await HiveDatabaseService.createTestFriendCategories('whoboom@whoboom.com');
    
    print('✅ Test verileri başarıyla yüklendi!');
  } catch (e) {
    print('❌ Test verileri yüklenirken hata: $e');
  }
}

/// Test kullanıcılarını veritabanına ekler
/// Admin ve normal kullanıcı örnekleri oluşturur
Future<void> _addTestUsers() async {
  try {
    // Admin kullanıcısı
    final adminUser = RegistrationModel(
      id: 'admin_user',
      judgeName: 'Admin Yargıç',
      email: 'whoboom@whoboom.com',
      password: 'Nk05354904105-*/',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      isAdmin: true, // Admin yetkisi
    );

    // Test kullanıcısı 2
    final user2 = RegistrationModel(
      id: 'test_user_2',
      judgeName: 'Test Yargıç 2',
      email: 'whosdoom@gmail.com',
      password: 'Nk05354904105-*/',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      isAdmin: false, // Normal kullanıcı
    );

    // Canan kullanıcısı
    final cananUser = RegistrationModel(
      id: 'canan_user',
      judgeName: 'Canan Yargıç',
      email: 'canan@whoboom.com',
      password: 'Nk05354904105-*/',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      isAdmin: false, // Normal kullanıcı
    );

    // Fatih kullanıcısı (sıradan kullanıcı)
    final fatihUser = RegistrationModel(
      id: 'fatih_user',
      judgeName: 'Fatih Yargıç',
      email: 'fatih@whoboom.com',
      password: 'Nk05354904105-*/',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      isAdmin: false, // Sıradan kullanıcı - admin değil
    );

    // Test Yargıç 1
    final yargic1 = RegistrationModel(
      id: 'yargic1_user',
      judgeName: 'Yargıç 1',
      email: 'email1@gmail.com',
      password: '1',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      isAdmin: false, // Normal kullanıcı
    );

    // Test Yargıç 2
    final yargic2 = RegistrationModel(
      id: 'yargic2_user',
      judgeName: 'Yargıç 2',
      email: 'email2@gmail.com',
      password: '1',
      country: 'Türkiye',
      oath: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      isAdmin: false, // Normal kullanıcı
    );

    // 50 Test Yargıç Listesi
    final testCountries = [
      'Türkiye', 'Almanya', 'Fransa', 'İtalya', 'İspanya', 'Hollanda', 'Belçika', 'Avusturya', 'İsviçre', 'Polonya',
      'Çek Cumhuriyeti', 'Macaristan', 'Romanya', 'Bulgaristan', 'Yunanistan', 'Portekiz', 'İrlanda', 'Danimarka', 'Finlandiya', 'İsveç',
      'Norveç', 'Ukrayna', 'Rusya', 'Beyaz Rusya', 'Letonya', 'Litvanya', 'Estonya', 'Slovakya', 'Slovenya', 'Hırvatistan',
      'Sırbistan', 'Bosna Hersek', 'Kosova', 'Makedonya', 'Arnavutluk', 'Karadağ', 'Moldova', 'Gürcistan', 'Ermenistan', 'Azerbaycan',
      'Kazakistan', 'Özbekistan', 'Türkmenistan', 'Kırgızistan', 'Tacikistan', 'Moğolistan', 'Çin', 'Japonya', 'Güney Kore', 'Kuzey Kore'
    ];

    final testYargiclar = <RegistrationModel>[];
    
    for (int i = 1; i <= 50; i++) {
      final country = testCountries[i % testCountries.length];
      final yargic = RegistrationModel(
        id: 'test_yargic_$i',
        judgeName: 'Test Yargıç $i',
        email: 'testyargic$i@gmail.com',
        password: '1',
        country: country,
        oath: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: true,
        isActive: true,
        isAdmin: false, // Normal kullanıcı
      );
      testYargiclar.add(yargic);
    }

    // Kullanıcıları veritabanına ekle veya güncelle
    // Her işlemden sonra UI thread'ine nefes alma fırsatı ver
    final existingAdmin = HiveDatabaseService.getRegistrationByEmail(adminUser.email);
    if (existingAdmin == null) {
      await HiveDatabaseService.addRegistration(adminUser);
      print('Admin kullanıcısı eklendi: ${adminUser.email}');
    } else {
      // Mevcut admin kullanıcısını güncelle
      final updatedAdmin = existingAdmin.copyWith(
        isActive: true,
        isEmailVerified: true,
        isAdmin: true,
        loginAttempts: 0,
      );
      await HiveDatabaseService.updateRegistration(updatedAdmin);
      print('Admin kullanıcısı güncellendi: ${adminUser.email}');
      print('Admin durumu: isActive=${updatedAdmin.isActive}, isEmailVerified=${updatedAdmin.isEmailVerified}, canLogin=${updatedAdmin.canLogin}');
    }
    await Future.delayed(const Duration(milliseconds: 10));

    final existingUser2 = HiveDatabaseService.getRegistrationByEmail(user2.email);
    if (existingUser2 == null) {
      await HiveDatabaseService.addRegistration(user2);
      print('Test kullanıcısı 2 eklendi: ${user2.email}');
    } else {
      // Mevcut test kullanıcısını güncelle
      final updatedUser2 = existingUser2.copyWith(
        isActive: true,
        isEmailVerified: true,
        isAdmin: false,
        loginAttempts: 0,
      );
      await HiveDatabaseService.updateRegistration(updatedUser2);
      print('Test kullanıcısı 2 güncellendi: ${user2.email}');
      print('Test kullanıcısı durumu: isActive=${updatedUser2.isActive}, isEmailVerified=${updatedUser2.isEmailVerified}, canLogin=${updatedUser2.canLogin}');
    }
    await Future.delayed(const Duration(milliseconds: 10));

    // Canan kullanıcısını ekle veya güncelle
    final existingCanan = HiveDatabaseService.getRegistrationByEmail(cananUser.email);
    if (existingCanan == null) {
      await HiveDatabaseService.addRegistration(cananUser);
      print('Canan kullanıcısı eklendi: ${cananUser.email}');
    } else {
      // Mevcut Canan kullanıcısını güncelle
      final updatedCanan = existingCanan.copyWith(
        isActive: true,
        isEmailVerified: true,
        isAdmin: false,
        loginAttempts: 0,
      );
      await HiveDatabaseService.updateRegistration(updatedCanan);
      print('Canan kullanıcısı güncellendi: ${cananUser.email}');
      print('Canan kullanıcısı durumu: isActive=${updatedCanan.isActive}, isEmailVerified=${updatedCanan.isEmailVerified}, canLogin=${updatedCanan.canLogin}');
    }
    await Future.delayed(const Duration(milliseconds: 10));

    // Fatih kullanıcısını ekle veya güncelle
    final existingFatih = HiveDatabaseService.getRegistrationByEmail(fatihUser.email);
    if (existingFatih == null) {
      await HiveDatabaseService.addRegistration(fatihUser);
      print('Fatih kullanıcısı eklendi: ${fatihUser.email}');
    } else {
      // Mevcut Fatih kullanıcısını güncelle - sıradan kullanıcı olarak
      final updatedFatih = existingFatih.copyWith(
        isActive: true,
        isEmailVerified: true,
        isAdmin: false,
        loginAttempts: 0,
      );
      await HiveDatabaseService.updateRegistration(updatedFatih);
      print('Fatih kullanıcısı güncellendi: ${fatihUser.email}');
    }
    await Future.delayed(const Duration(milliseconds: 10));

    // Test Yargıç 1'i ekle veya güncelle
    final existingYargic1 = HiveDatabaseService.getRegistrationByEmail(yargic1.email);
    if (existingYargic1 == null) {
      await HiveDatabaseService.addRegistration(yargic1);
      print('Test Yargıç 1 eklendi: ${yargic1.email}');
    } else {
      // Mevcut test yargıcını güncelle
      final updatedYargic1 = existingYargic1.copyWith(
        isActive: true,
        isEmailVerified: true,
        isAdmin: false,
        loginAttempts: 0,
      );
      await HiveDatabaseService.updateRegistration(updatedYargic1);
      print('Test Yargıç 1 güncellendi: ${yargic1.email}');
    }
    await Future.delayed(const Duration(milliseconds: 10));

    // Test Yargıç 2'yi ekle veya güncelle
    final existingYargic2 = HiveDatabaseService.getRegistrationByEmail(yargic2.email);
    if (existingYargic2 == null) {
      await HiveDatabaseService.addRegistration(yargic2);
      print('Test Yargıç 2 eklendi: ${yargic2.email}');
    } else {
      // Mevcut test yargıcını güncelle
      final updatedYargic2 = existingYargic2.copyWith(
        isActive: true,
        isEmailVerified: true,
        isAdmin: false,
        loginAttempts: 0,
      );
      await HiveDatabaseService.updateRegistration(updatedYargic2);
      print('Test Yargıç 2 güncellendi: ${yargic2.email}');
    }
    await Future.delayed(const Duration(milliseconds: 10));

     // Sadece ilk 5 test yargıcını ekle (performans için)
     print('İlk 5 test yargıcı ekleniyor...');
     final testYargiclarSubset = testYargiclar.take(5).toList();
     for (int i = 0; i < testYargiclarSubset.length; i++) {
       final yargic = testYargiclarSubset[i];
       final existingYargic = HiveDatabaseService.getRegistrationByEmail(yargic.email);
       
       if (existingYargic == null) {
         await HiveDatabaseService.addRegistration(yargic);
         print('Test Yargıç ${i + 1} eklendi: ${yargic.email} (${yargic.country})');
       } else {
         // Mevcut test yargıcını güncelle
         final updatedYargic = existingYargic.copyWith(
           isActive: true,
           isEmailVerified: true,
           isAdmin: false,
           loginAttempts: 0,
         );
         await HiveDatabaseService.updateRegistration(updatedYargic);
         print('Test Yargıç ${i + 1} güncellendi: ${yargic.email} (${yargic.country})');
       }
       // Her yargıç işleminden sonra UI thread'ine nefes alma fırsatı ver
       if (i < testYargiclarSubset.length - 1) {
         await Future.delayed(const Duration(milliseconds: 10));
       }
     }
     print('${testYargiclarSubset.length} test yargıcı işlemi tamamlandı!');

    // Özel kullanıcıların admin yetkilerini kontrol et (örn. testyargic3 admin olmamalı)
    await HiveDatabaseService.setUserAdminStatus('testyargic3@gmail.com', false);

    // Tüm kullanıcıları listele (sadece sayı)
    final allUsers = HiveDatabaseService.getAllRegistrations();
    print('✅ Toplam kullanıcı sayısı: ${allUsers.length}');
    print('✅ Test kullanıcıları hazır.');
  } catch (e) {
    print('Test kullanıcıları eklenirken hata: $e');
  }
}

class WhoBoomApp extends StatelessWidget {
  const WhoBoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhoBoom',
      theme: AppTheme.lightTheme,
      // Türkçe dil desteği
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe
        Locale('en', 'US'), // İngilizce (fallback)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const WhoBoomLoginPage(),
    );
  }
}

class WhoBoomLoginPage extends StatefulWidget {
  const WhoBoomLoginPage({super.key});

  @override
  _WhoBoomLoginPageState createState() => _WhoBoomLoginPageState();
}

class _WhoBoomLoginPageState extends State<WhoBoomLoginPage> {
  bool _showPassword = false;
  bool _isLogin = true;
  bool _rememberMe = false;
  final _formData = {
    'name': '',
    'judgeName': '',
    'email': '',
    'password': '',
    'country': '',
    'activationCode': '',
    'oath': false,
  };
  final _errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  /// Kaydedilmiş giriş bilgilerini yükle
  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberedPassword = prefs.getString('remembered_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && rememberedEmail != null && rememberedPassword != null) {
        setState(() {
          _rememberMe = true;
          _formData['email'] = rememberedEmail;
          _formData['password'] = rememberedPassword;
        });
      }
    } catch (e) {
      print('Kaydedilmiş bilgiler yüklenirken hata: $e');
    }
  }

  /// Giriş bilgilerini kaydet veya sil
  Future<void> _saveRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', _formData['email'] as String);
        await prefs.setString('remembered_password', _formData['password'] as String);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remembered_email');
        await prefs.remove('remembered_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      print('Bilgiler kaydedilirken hata: $e');
    }
  }

  void _handleInputChange(String field, dynamic value) {
    setState(() {
      _formData[field] = value;
      if (_errors.containsKey(field)) {
        _errors.remove(field);
      }
    });
    
    // Gerçek zamanlı validasyon
    _validateField(field);
  }

  void _validateField(String field) {
    final newErrors = <String, String>{};
    
    switch (field) {
      case 'judgeName':
        if (!_isLogin) {
          final judgeName = _formData['judgeName'] as String;
          if (judgeName.isNotEmpty) {
            if (judgeName.length < 8) {
              newErrors['judgeName'] = 'Yargıç adı en az 8 karakter olmalıdır.';
            } else if (judgeName.length > 171) {
              newErrors['judgeName'] = 'Yargıç adı en fazla 171 karakter olabilir.';
            } else if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(judgeName)) {
              newErrors['judgeName'] = 'Yargıç adı sadece harf içermelidir.';
            }
          }
        }
        break;
        
      case 'email':
        final email = _formData['email'] as String;
        if (email.isNotEmpty) {
          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
            newErrors['email'] = 'Geçerli bir e-posta adresi giriniz.';
          } else if (email.length > 254) {
            newErrors['email'] = 'E-posta adresi çok uzun.';
          } else if (!_isLogin) {
            // Kayıt sırasında e-posta benzersizlik kontrolü
            final existingRegistration = HiveDatabaseService.getRegistrationByEmail(email);
            if (existingRegistration != null) {
              newErrors['email'] = 'Bu e-posta adresi zaten kayıtlı.';
            }
          }
        }
        break;
        
      case 'password':
        final password = _formData['password'] as String;
        if (password.isNotEmpty && !_isLogin) {
          // Şifre validasyonu sadece kayıt sırasında
          if (password.length < 8) {
            newErrors['password'] = 'Şifre en az 8 karakter olmalıdır.';
          } else if (password.length > 19) {
            newErrors['password'] = 'Şifre en fazla 19 karakter olabilir.';
          } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]').hasMatch(password)) {
            newErrors['password'] = 'Şifre en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.';
          }
        }
        break;
        
      case 'country':
        if (!_isLogin) {
          final country = _formData['country'] as String;
          if (country.isEmpty) {
            newErrors['country'] = 'Lütfen ülkenizi seçiniz.';
          }
        }
        break;
    }
    
    setState(() {
      _errors.remove(field);
      if (newErrors.containsKey(field)) {
        _errors[field] = newErrors[field]!;
      }
    });
  }

  bool _validateForm() {
    final newErrors = <String, String>{};

    if (!_isLogin) {
      // Yargıç Adı Kontrolü
      final judgeName = _formData['judgeName'] as String;
      if (judgeName.isEmpty) {
        newErrors['judgeName'] = 'Yargıç adı boş olamaz.';
      } else if (judgeName.length < 8) {
        newErrors['judgeName'] = 'Yargıç adı en az 8 karakter olmalıdır.';
      } else if (judgeName.length > 171) {
        newErrors['judgeName'] = 'Yargıç adı en fazla 171 karakter olabilir.';
      } else if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(judgeName)) {
        newErrors['judgeName'] = 'Yargıç adı sadece harf içermelidir.';
      }

      // Ülke Kontrolü
      final country = _formData['country'] as String;
      if (country.isEmpty) {
        newErrors['country'] = 'Lütfen ülkenizi seçiniz.';
      }

      // Yemin Kontrolü
      if (!(_formData['oath'] as bool)) {
        newErrors['oath'] = 'Lütfen önce yemin ediniz.';
      }
    }

    // E-posta Kontrolü
    final email = _formData['email'] as String;
    if (email.isEmpty) {
      newErrors['email'] = 'E-posta adresi boş olamaz.';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      newErrors['email'] = 'Geçerli bir e-posta adresi giriniz.';
    } else if (email.length > 254) {
      newErrors['email'] = 'E-posta adresi çok uzun.';
    }

    // Şifre Kontrolü
    final password = _formData['password'] as String;
    if (password.isEmpty) {
      newErrors['password'] = 'Şifre boş olamaz.';
    } else if (!_isLogin) {
      // Şifre validasyonu sadece kayıt sırasında
      if (password.length < 8) {
        newErrors['password'] = 'Şifre en az 8 karakter olmalıdır.';
      } else if (password.length > 19) {
        newErrors['password'] = 'Şifre en fazla 19 karakter olabilir.';
      } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]').hasMatch(password)) {
        newErrors['password'] = 'Şifre en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.';
      }
    }

    // E-posta Benzersizlik Kontrolü (Kayıt sırasında)
    if (!_isLogin) {
      final existingRegistration = HiveDatabaseService.getRegistrationByEmail(email);
      if (existingRegistration != null) {
        newErrors['email'] = 'Bu e-posta adresi zaten kayıtlı.';
      }
    }

    setState(() {
      _errors.clear();
      _errors.addAll(newErrors);
    });

    return newErrors.isEmpty;
  }

  // Modern uyarı gösterme fonksiyonu
  void _showModernAlert({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    bool isSuccess = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon ve başlık
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // Mesaj
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                
                // Buton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (isSuccess) {
                        // Başarılı kayıt sonrası otomatik giriş
                        Future.delayed(const Duration(milliseconds: 500), () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => HomePage(userEmail: _formData['email'] as String),
                            ),
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isSuccess ? 'Devam Et' : 'Tamam',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modern hata gösterme fonksiyonu
  void _showModernError(String message) {
    _showModernAlert(
      title: 'Oops! 😅',
      message: message,
      icon: FeatherIcons.alertCircle,
      color: const Color(0xFFEF4444),
    );
  }

  /// Günün Davası modalını gösterir
  /// Ekranı kaplayan tam ekran modal, sağ altta X ikonu ile kapatılabilir
  void _showGununDavasiModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppTheme.scaffoldBackgroundColor,
            child: SafeArea(
              child: Stack(
                children: [
                  // İçerik
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60), // X butonu için boşluk
                        // Başlık
                        Row(
                          children: [
                            Icon(
                              MdiIcons.gavel,
                              size: 24,
                              color: AppTheme.iconPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Günün Davası',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sessizliğin Kırılması Davası',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // İçerik kartı
                        Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dava Detayları',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bu dava hakkında detaylı bilgiler burada yer alacaktır. Kullanıcılar üye olmadan bu içeriği okuyabilirler.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Dava konusu ve detayları buraya eklenecektir. Bu bir önizleme içeriğidir.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Sağ altta X kapatma butonu
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Haykıra Katıl modalını gösterir
  /// Ekranı kaplayan tam ekran modal, sağ altta X ikonu ile kapatılabilir
  void _showHaykiraKatilModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppTheme.scaffoldBackgroundColor,
            child: SafeArea(
              child: Stack(
                children: [
                  // İçerik
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60), // X butonu için boşluk
                        // Başlık
                        Row(
                          children: [
                            Image.asset(
                              'lib/icons/00_giris_haykira_katil_icon.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Haykıra Katıl',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ses ver, tarafını seç!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // İçerik kartı
                        Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Haykırış Detayları',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bu haykırış hakkında detaylı bilgiler burada yer alacaktır. Kullanıcılar üye olmadan bu içeriği okuyabilirler.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Haykırış konusu ve detayları buraya eklenecektir. Bu bir önizleme içeriğidir.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Sağ altta X kapatma butonu
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  // Modern başarı gösterme fonksiyonu
  void _showModernSuccess(String message) {
    _showModernAlert(
      title: 'Harika! 🎉',
      message: message,
      icon: FeatherIcons.checkCircle,
      color: const Color(0xFF10B981),
      isSuccess: true,
    );
  }

  // Modern bilgi gösterme fonksiyonu
  void _showModernInfo(String title, String message) {
    _showModernAlert(
      title: title,
      message: message,
      icon: FeatherIcons.info,
      color: const Color(0xFF3B82F6),
    );
  }

  void _handleSubmit() async {
    if (!_validateForm()) {
      return;
    }

    // Provider'ları al
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final davaProvider = Provider.of<DavaProvider>(context, listen: false);

    try {
      if (_isLogin) {
        // Giriş işlemi - Provider kullanarak
        final email = _formData['email'] as String;
        final password = _formData['password'] as String;
        
        final success = await authProvider.login(email, password);
        
        if (success) {
          // "Beni anımsa" seçiliyse bilgileri kaydet
          await _saveRememberedCredentials();
          
          // Kullanıcı verilerini yükle
          await davaProvider.loadUserData(email);
          
          // Tüm kullanıcılar ana sayfaya yönlendirilir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(userEmail: email),
            ),
          );
        } else {
          _showModernError(authProvider.error ?? 'E-posta veya şifre hatalı. Lütfen tekrar deneyin! 🔐');
        }
      } else {
        // Kayıt işlemi - Provider kullanarak
        final registration = RegistrationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          judgeName: _formData['judgeName'] as String,
          email: _formData['email'] as String,
          password: _formData['password'] as String,
          country: _formData['country'] as String,
          oath: _formData['oath'] as bool,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: true, // Kayıt sonrası otomatik e-posta doğrulaması
          isActive: true, // Hesap aktif olarak başlat
        );

        final success = await authProvider.register(registration);
        
        if (success) {
          // Kullanıcı verilerini yükle
          await davaProvider.loadUserData(registration.email);
          
          // Modern başarı mesajı ve otomatik geçiş
          _showModernSuccess('Kayıt işlemi başarılı! Hoş geldiniz! 🎉\n\nOtomatik olarak giriş yapılıyor...');
          
          // 2 saniye sonra otomatik geçiş
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomePage(userEmail: _formData['email'] as String),
                ),
              );
            }
          });
        } else {
          _showModernError(authProvider.error ?? 'Kayıt olurken hata oluştu. Lütfen tekrar deneyin! 🔄');
        }
      }
    } catch (e) {
      _showModernError('Bir hata oluştu: $e\n\nLütfen tekrar deneyin! 🔄');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5FBF9), Color(0xFFE8F4F0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.successColor, AppTheme.calmGreenDark], // Yeşil tonları
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/icons/00_giris_gavel_ust_icon.png',
                              width: 60,
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Flexible( // Çok dilli uyumluluk için esnek yapı
                              child: FittedBox( // Çok dilli uyumluluk için otomatik ölçekleme
                                fit: BoxFit.scaleDown,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Huzur verici koyu yeşil stroke (arka plan) - Çok dilli uyumlu
                                    Text(
                                      'WhoBoom',
                                      style: TextStyle(
                                        fontSize: 19, // Maksimum font boyutu
                                        fontWeight: FontWeight.w900, // Çok kalın
                                        letterSpacing: 1.0, // Çok dilli uyumlu harf aralığı
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 3.0 // Uygun stroke kalınlığı
                                          ..color = AppTheme.calmGreenDark, // Huzur verici koyu yeşil
                                      ),
                                    ),
                                    // Beyaz fill (ön plan) - Çok dilli uyumlu
                                    Text(
                                      'WhoBoom',
                                      style: TextStyle(
                                        fontSize: 19, // Maksimum font boyutu
                                        fontWeight: FontWeight.w900, // Çok kalın
                                        letterSpacing: 1.0, // Çok dilli uyumlu harf aralığı
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 2),
                                            blurRadius: 6,
                                            color: AppTheme.calmGreenDark.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hükmünü ver, adaleti sağla.',
                          textAlign: TextAlign.center,
                          maxLines: 2, // Çok dilli uyumluluk için maksimum satır
                          overflow: TextOverflow.ellipsis, // Taşma durumunda ellipsis
                          style: TextStyle(
                            fontSize: 19, // Maksimum font boyutu
                            fontWeight: FontWeight.w900, // Çok kalın
                            letterSpacing: 1.0, // Çok dilli uyumlu harf aralığı
                            height: 1.3,
                            color: Colors.white, // Beyaz renk - çok belirgin
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 3),
                                blurRadius: 8,
                                color: AppTheme.calmGreenDark.withOpacity(0.6), // Güçlü gölge
                              ),
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: AppTheme.successColor.withOpacity(0.5),
                              ),
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.3), // Derinlik için siyah gölge
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login/Register Toggle
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryUltraLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: _isLogin ? AppTheme.primaryColor : Colors.transparent,
                                foregroundColor: _isLogin ? AppTheme.textOnPrimary : AppTheme.textSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => setState(() => _isLogin = true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'lib/icons/00_giris_mini_gavel.png',
                                    width: 16,
                                    height: 16,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Giriş', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: !_isLogin ? AppTheme.primaryColor : Colors.transparent,
                                foregroundColor: !_isLogin ? AppTheme.textOnPrimary : AppTheme.textSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => setState(() => _isLogin = false),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FeatherIcons.userPlus, size: 16),
                                  SizedBox(width: 8),
                                  Text('Kaydol', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          // Yargıç Adı
                          _buildTextField(
                            label: 'Yargıç Adı',
                            icon: FeatherIcons.anchor,
                            placeholder: '', // Bilgilendirici hint kaldırıldı
                            field: 'judgeName',
                            error: _errors['judgeName'],
                            onChanged: (value) => _handleInputChange('judgeName', value),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // E-Posta
                        _buildTextField(
                          label: 'E-Posta',
                          icon: FeatherIcons.mail,
                          placeholder: '', // Bilgilendirici hint kaldırıldı
                          field: 'email',
                          error: _errors['email'],
                          onChanged: (value) => _handleInputChange('email', value),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Şifre
                        _buildTextField(
                          label: 'Şifre',
                          icon: FeatherIcons.lock,
                          placeholder: '', // Bilgilendirici hint kaldırıldı
                          field: 'password',
                          error: _errors['password'],
                          obscureText: !_showPassword,
                          onChanged: (value) => _handleInputChange('password', value),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? FeatherIcons.eyeOff : FeatherIcons.eye,
                              size: 16,
                              color: AppTheme.iconSecondary,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Beni Anımsa checkbox (sadece giriş modunda)
                        if (_isLogin) ...[
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Text(
                                  'Beni anımsa',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        if (!_isLogin) ...[
                          // Ülke Seçimi (country_picker ile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(FeatherIcons.globe, size: 16, color: const Color(0xFF5A8A7E)),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Ülkeniz',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5A8A7E)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  // Önce Kürdistan seçeneğini de içeren özel modal göster
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    builder: (context) => Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Diğer ülkeler seçeneği
                                          ListTile(
                                            leading: const Icon(Icons.public, color: Colors.blue),
                                            title: const Text('Ülke Seç'),
                                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                            onTap: () {
                                              Navigator.pop(context);
                                              // Kurdistan'ı içeren özel ülke seçiciyi aç
                                              showCountryPickerWithKurdistan(
                                                context: context,
                                                showPhoneCode: false,
                                                onSelect: (String countryName) {
                                                  _handleInputChange('country', countryName);
                                                },
                                              );
                                            },
                                          ),
                                          const Divider(),
                                          // Kurdistan seçeneği (diğer ülkelerin altında)
                                          ListTile(
                                            leading: const Icon(
                                              Icons.flag,
                                              size: 24,
                                              color: Colors.orange,
                                            ),
                                            title: Text(CountryDisplayUtils.kurdistanHebrew),
                                            onTap: () {
                                              _handleInputChange('country', CountryDisplayUtils.kurdistanDbName);
                                              Navigator.pop(context);
                                            },
                                          ),
                                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(minHeight: 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _errors['country'] != null 
                                          ? Colors.red 
                                          : const Color(0xFF88D3C5)
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    (_formData['country'] as String?)?.isNotEmpty == true
                                      ? CountryDisplayUtils.getDisplayName(_formData['country'] as String)
                                      : CountryDisplayUtils.kurdistanHebrew,
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  ),
                                ),
                              ),
                              if (_errors['country'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(FeatherIcons.alertCircle, size: 12, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text(
                                        _errors['country']!,
                                        style: const TextStyle(fontSize: 12, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          // Yemin
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _formData['oath'] as bool,
                                onChanged: (value) => _handleInputChange('oath', value!),
                                activeColor: AppTheme.primaryColor,
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  heightFactor: 1.5,
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      children: [
                                        const TextSpan(text: 'Adil bir yargıç olacağıma, '),
                                        TextSpan(
                                          text: 'gizlilik',
                                          style: TextStyle(color: AppTheme.primaryColor, decoration: TextDecoration.underline),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.white,
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                ),
                                                builder: (context) => const PrivacyPolicyPage(),
                                              );
                                            },
                                        ),
                                        const TextSpan(text: ' ve '),
                                        TextSpan(
                                          text: 'koşullarınızı',
                                          style: TextStyle(color: AppTheme.primaryColor, decoration: TextDecoration.underline),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.white,
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                ),
                                                builder: (context) => const TermsConditionsPage(),
                                              );
                                            },
                                        ),
                                        const TextSpan(text: ' kabul ettiğime dair tüm mukaddesatım üzerine yemin ederim.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_errors['oath'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(FeatherIcons.alertCircle, size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    _errors['oath']!,
                                    style: const TextStyle(fontSize: 12, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleSubmit,
                            style: AppTheme.primaryButtonStyle,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'lib/icons/00_giris_mini_gavel.png',
                                        width: 16,
                                        height: 16,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_isLogin ? 'GİRİŞ YAP' : 'KAYDET'),
                                    ],
                                  ),
                          ),
                        ),

                        // Forgot Password
                        if (_isLogin)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Şifreni mi unuttun?',
                                style: TextStyle(color: AppTheme.primaryColor),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Daily Case & Virtual Action
                  if (_isLogin) ...[
                    Container(
                      color: const Color(0xFFF5FBF9),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Günün Davası
                          Card(
                            color: const Color(0xFFE8F4F0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _showGununDavasiModal,
                                hoverColor: const Color(0xFF88D3C5).withOpacity(0.3),
                                splashColor: const Color(0xFF88D3C5).withOpacity(0.2),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: const Border(
                                      left: BorderSide(color: Color(0xFF88D3C5), width: 4),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            MdiIcons.gavel,
                                            size: 16,
                                            color: AppTheme.iconPrimary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Günün Davası',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Sessizliğin Kırılması Davası',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Haykır'a Katıl
                          Card(
                            color: const Color(0xFFE8F4F0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _showHaykiraKatilModal,
                                hoverColor: const Color(0xFF88D3C5).withOpacity(0.3),
                                splashColor: const Color(0xFF88D3C5).withOpacity(0.2),
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: const Border(
                                      left: BorderSide(color: Color(0xFF88D3C5), width: 4),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            'lib/icons/00_giris_haykira_katil_icon.png',
                                            width: 16,
                                            height: 16,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Haykıra Katıl',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ses ver, tarafını seç!',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(width: 8),
                  // Footer - Vurgulu Metin
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                    child: Text(
                      'Düşün; ölç ve biç. Tanrının adaletine katıl',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic, // İtalik stil
                        letterSpacing: 1.0,
                        height: 1.4,
                        color: AppTheme.calmGreenDark, // Huzur verici koyu yeşil
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: AppTheme.calmGreenDark.withOpacity(0.25),
                          ),
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: AppTheme.successColor.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String placeholder,
    required String field,
    String? error,
    bool obscureText = false,
    Function(String)? onChanged,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.iconPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          // Türkçe karakter desteği - tüm karakterleri kabul et
          inputFormatters: [
            // Türkçe karakterler dahil tüm karakterleri kabul et
            FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
          ],
          decoration: InputDecoration(
            hintText: placeholder.isNotEmpty ? placeholder : null, // Boş placeholder gösterilmez
            errorText: error,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) return const SizedBox.shrink();
    
    int strength = 0;
    String message = '';
    Color color = Colors.grey;
    
    if (password.length >= 8) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'\d').hasMatch(password)) strength++;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) strength++;
    
    switch (strength) {
      case 0:
      case 1:
        message = 'Çok Zayıf';
        color = AppTheme.errorColor;
        break;
      case 2:
        message = 'Zayıf';
        color = AppTheme.warningColor;
        break;
      case 3:
        message = 'Orta';
        color = AppTheme.primaryColor;
        break;
      case 4:
        message = 'Güçlü';
        color = AppTheme.successColor;
        break;
      case 5:
        message = 'Çok Güçlü';
        color = AppTheme.successColor;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primaryUltraLight,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: strength / 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCounter(String text, int maxLength) {
    if (maxLength == 0) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${text.length}/$maxLength',
            style: TextStyle(
              fontSize: 12,
              color: text.length > maxLength ? AppTheme.errorColor : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}