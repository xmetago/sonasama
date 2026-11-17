import '../models/registration_model.dart';
import '../services/firebase_password_gateway.dart';
import '../services/hive_database_service.dart';
import '../services/user_session_service.dart';
import 'base_provider.dart';

/// Testlerin Firebase yerine kullanabildiği şifre çağrıları.
class PasswordAuthClient {
  const PasswordAuthClient({
    this.sendResetEmail,
    this.reauthenticateAndUpdate,
  });

  final Future<void> Function(String email)? sendResetEmail;
  final Future<void> Function({
    required String email,
    required String currentPassword,
    required String newPassword,
  })? reauthenticateAndUpdate;
}

/// Kimlik doğrulama ve kullanıcı oturum yönetimi için provider
class AuthProvider extends BaseProvider {
  AuthProvider({PasswordAuthClient? passwordAuthClient})
      : _passwordAuthClient = passwordAuthClient ?? const PasswordAuthClient();

  final PasswordAuthClient _passwordAuthClient;
  RegistrationModel? _currentUser;
  bool _isInitialized = false;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _strongPassword = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,19}$',
  );

  static bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

  static String? weakPasswordMessage(String password) {
    if (_strongPassword.hasMatch(password)) return null;
    return 'Şifre çok zayıf. En az 8 karakter, bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.';
  }

  static String passwordAuthMessage(String code, {required bool reset}) {
    switch (code) {
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi giriniz.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı bir hesap bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Mevcut şifre hatalı.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'Bağlantı kurulamadı. İnternetinizi kontrol edin.';
      case 'requires-recent-login':
        return 'Güvenlik için yeniden giriş yapmanız gerekiyor.';
      default:
        return reset
            ? 'Şifre sıfırlama e-postası gönderilemedi. Lütfen tekrar deneyin.'
            : 'Şifre değiştirilirken hata oluştu.';
    }
  }

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

  /// Firebase Auth üzerinden şifre sıfırlama e-postası gönderir.
  ///
  /// Başarıda null, aksi halde Türkçe hata döner.
  Future<String?> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (!isValidEmail(trimmed)) {
      const message = 'Geçerli bir e-posta adresi giriniz.';
      setError(message);
      return message;
    }

    try {
      setLoading(true);
      clearMessages();
      final override = _passwordAuthClient.sendResetEmail;
      if (override != null) {
        await override(trimmed);
      } else {
        await FirebasePasswordGateway.sendPasswordResetEmail(trimmed);
      }
      setSuccess('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.');
      return null;
    } on PasswordAuthException catch (error) {
      final message = passwordAuthMessage(error.code, reset: true);
      setError(message);
      return message;
    } catch (_) {
      const message = 'Şifre sıfırlama e-postası gönderilemedi. Lütfen tekrar deneyin.';
      setError(message);
      return message;
    } finally {
      setLoading(false);
    }
  }

  /// Mevcut şifreyle yeniden doğrular, ardından şifreyi günceller.
  ///
  /// Firebase oturumu varsa `reauthenticateWithCredential` ve `updatePassword`
  /// çağrılır. Yerel hesap her durumda Hive üzerinde güncellenir.
  /// Başarıda null, aksi halde Türkçe hata döner.
  Future<String?> reauthenticateAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      const message = 'Yeni şifreler eşleşmiyor.';
      setError(message);
      return message;
    }
    final weak = weakPasswordMessage(newPassword);
    if (weak != null) {
      setError(weak);
      return weak;
    }
    if (_currentUser == null) {
      const message = 'Giriş gerekli.';
      setError(message);
      return message;
    }
    if (!validatePassword(currentPassword)) {
      const message = 'Mevcut şifre hatalı.';
      setError(message);
      return message;
    }

    try {
      setLoading(true);
      clearMessages();
      final override = _passwordAuthClient.reauthenticateAndUpdate;
      if (override != null) {
        await override(
          email: _currentUser!.email,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      } else {
        await FirebasePasswordGateway.reauthenticateAndUpdatePassword(
          email: _currentUser!.email,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }

      final updatedUser = _currentUser!.copyWith(password: newPassword);
      await HiveDatabaseService.updateRegistration(updatedUser);
      _currentUser = updatedUser;
      UserSessionService.setCurrentUser(updatedUser);
      setSuccess('Şifre başarıyla değiştirildi.');
      return null;
    } on PasswordAuthException catch (error) {
      final message = passwordAuthMessage(error.code, reset: false);
      setError(message);
      return message;
    } catch (_) {
      const message = 'Şifre değiştirilirken hata oluştu.';
      setError(message);
      return message;
    } finally {
      setLoading(false);
    }
  }

  /// Şifre değiştirme
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final error = await reauthenticateAndUpdatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: newPassword,
    );
    return error == null;
  }
}
