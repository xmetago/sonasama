import '../models/registration_model.dart';
import '../services/hive_database_service.dart';
import '../services/user_session_service.dart';
import 'base_provider.dart';

/// Kimlik doğrulama ve kullanıcı oturum yönetimi için provider
class AuthProvider extends BaseProvider {
  RegistrationModel? _currentUser;
  bool _isInitialized = false;

  /// Mevcut kullanıcı
  RegistrationModel? get currentUser => _currentUser;

  /// Kullanıcı giriş yapmış mı?
  bool get isLoggedIn => _currentUser != null;

  /// Kullanıcı admin mi?
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Kullanıcı e-posta adresi
  String? get userEmail => _currentUser?.email;

  /// Kullanıcı adı
  String? get userName => _currentUser?.judgeName;

  /// Kullanıcı ülkesi
  String? get userCountry => _currentUser?.country;

  /// Provider başlatıldı mı?
  bool get isInitialized => _isInitialized;

  /// Kullanıcı giriş yapabilir mi? (19 saat kuralı)
  bool get canUserOpenDava {
    if (_currentUser == null) return false;
    return HiveDatabaseService.canUserOpenDava(_currentUser!.email);
  }

  /// Kullanıcı haykırabilir mi? (19 saat kuralı)
  bool get canUserHaykir {
    if (_currentUser == null) return false;
    return HiveDatabaseService.canUserHaykir(_currentUser!.email);
  }

  /// Dava açma için kalan saat
  int get remainingDavaAcHours {
    if (_currentUser == null) return 0;
    return HiveDatabaseService.getRemainingDavaAcHours(_currentUser!.email);
  }

  /// Haykırma için kalan saat
  int get remainingHaykirHours {
    if (_currentUser == null) return 0;
    return HiveDatabaseService.getRemainingHaykirHours(_currentUser!.email);
  }

  /// Provider'ı başlat - mevcut oturumu kontrol et
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      setLoading(true);
      
      // Mevcut oturumu kontrol et
      final currentUser = UserSessionService.getCurrentUser();
      if (currentUser != null) {
        _currentUser = currentUser;
        notifyListeners();
      }
      
      _isInitialized = true;
    } catch (e) {
      setError('Oturum başlatılırken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Kullanıcı girişi
  Future<bool> login(String email, String password) async {
    return await executeAsync(
      () async {
        final isValid = HiveDatabaseService.validateLogin(email, password);
        
        if (!isValid) {
          throw Exception('E-posta veya şifre hatalı');
        }

        final user = HiveDatabaseService.getRegistrationByEmail(email);
        if (user == null) {
          throw Exception('Kullanıcı bulunamadı');
        }

        if (!user.canLogin) {
          throw Exception('Hesabınız aktif değil veya giriş yapamaz durumda');
        }

        // Kullanıcı oturumunu ayarla
        _currentUser = user;
        UserSessionService.setCurrentUser(user);
        
        notifyListeners();
        return true;
      },
      errorMessage: 'Giriş yapılırken hata oluştu',
      successMessage: 'Başarıyla giriş yapıldı',
    ) ?? false;
  }

  /// Kullanıcı kaydı
  Future<bool> register(RegistrationModel registration) async {
    return await executeAsync(
      () async {
        // E-posta benzersizlik kontrolü
        final existingUser = HiveDatabaseService.getRegistrationByEmail(registration.email);
        if (existingUser != null) {
          throw Exception('Bu e-posta adresi zaten kayıtlı');
        }

        // Yargıç adı benzersizlik kontrolü (case-insensitive)
        final existingJudgeName =
            HiveDatabaseService.getRegistrationByJudgeName(registration.judgeName);
        if (existingJudgeName != null) {
          throw Exception('Bu Yargıç Adı zaten kullanımda');
        }

        // Kullanıcıyı kaydet
        await HiveDatabaseService.addRegistration(registration);

        // Otomatik giriş yap
        _currentUser = registration;
        UserSessionService.setCurrentUser(registration);
        
        notifyListeners();
        return true;
      },
      errorMessage: 'Kayıt olurken hata oluştu',
      successMessage: 'Başarıyla kayıt olundu',
    ) ?? false;
  }

  /// Kullanıcı çıkışı
  void logout() {
    _currentUser = null;
    UserSessionService.clearCurrentUser();
    clearMessages();
    notifyListeners();
  }

  /// Kullanıcı bilgilerini güncelle
  Future<bool> updateUser(RegistrationModel updatedUser) async {
    return await executeAsync(
      () async {
        await HiveDatabaseService.updateRegistration(updatedUser);
        
        // Eğer güncellenen kullanıcı mevcut kullanıcıysa, state'i güncelle
        if (_currentUser?.id == updatedUser.id) {
          _currentUser = updatedUser;
          UserSessionService.setCurrentUser(updatedUser);
          notifyListeners();
        }
        
        return true;
      },
      errorMessage: 'Kullanıcı bilgileri güncellenirken hata oluştu',
      successMessage: 'Kullanıcı bilgileri başarıyla güncellendi',
    ) ?? false;
  }

  /// Dava açma zamanını güncelle
  Future<void> updateDavaAcTime() async {
    if (_currentUser == null) return;

    try {
      await HiveDatabaseService.updateUserDavaAcTime(_currentUser!.email);
      
      // Kullanıcı bilgilerini yeniden yükle
      final updatedUser = HiveDatabaseService.getRegistrationByEmail(_currentUser!.email);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        UserSessionService.setCurrentUser(updatedUser);
        notifyListeners();
      }
    } catch (e) {
      setError('Dava açma zamanı güncellenirken hata oluştu: $e');
    }
  }

  /// Haykırma zamanını güncelle
  Future<void> updateHaykirTime() async {
    if (_currentUser == null) return;

    try {
      await HiveDatabaseService.updateUserHaykirTime(_currentUser!.email);
      
      // Kullanıcı bilgilerini yeniden yükle
      final updatedUser = HiveDatabaseService.getRegistrationByEmail(_currentUser!.email);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        UserSessionService.setCurrentUser(updatedUser);
        notifyListeners();
      }
    } catch (e) {
      setError('Haykırma zamanı güncellenirken hata oluştu: $e');
    }
  }

  /// Kullanıcı bilgilerini yeniden yükle
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      final refreshedUser = HiveDatabaseService.getRegistrationByEmail(_currentUser!.email);
      if (refreshedUser != null) {
        _currentUser = refreshedUser;
        UserSessionService.setCurrentUser(refreshedUser);
        notifyListeners();
      }
    } catch (e) {
      setError('Kullanıcı bilgileri yenilenirken hata oluştu: $e');
    }
  }

  /// Kullanıcı doğrulama (şifre kontrolü)
  bool validatePassword(String password) {
    if (_currentUser == null) return false;
    return _currentUser!.password == password;
  }

  /// Şifre değiştirme
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    return await executeAsync(
      () async {
        // Mevcut şifreyi kontrol et
        if (!validatePassword(currentPassword)) {
          throw Exception('Mevcut şifre hatalı');
        }

        // Yeni şifre ile kullanıcıyı güncelle
        final updatedUser = _currentUser!.copyWith(password: newPassword);
        await HiveDatabaseService.updateRegistration(updatedUser);
        
        _currentUser = updatedUser;
        UserSessionService.setCurrentUser(updatedUser);
        notifyListeners();
        
        return true;
      },
      errorMessage: 'Şifre değiştirilirken hata oluştu',
      successMessage: 'Şifre başarıyla değiştirildi',
    ) ?? false;
  }
}
