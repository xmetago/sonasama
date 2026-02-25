import 'package:flutter/foundation.dart';

/// Tüm provider'lar için temel sınıf
/// Ortak loading, error ve success state yönetimi sağlar
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  /// Loading durumu
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? get error => _error;

  /// Başarı mesajı
  String? get successMessage => _successMessage;

  /// Loading durumunu ayarla
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Hata mesajını ayarla
  void setError(String? error) {
    _error = error;
    _successMessage = null;
    notifyListeners();
  }

  /// Başarı mesajını ayarla
  void setSuccess(String? message) {
    _successMessage = message;
    _error = null;
    notifyListeners();
  }

  /// Tüm mesajları temizle
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Hata durumunu temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Başarı durumunu temizle
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Async işlem wrapper'ı - otomatik loading yönetimi
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? errorMessage,
    String? successMessage,
  }) async {
    try {
      setLoading(true);
      clearMessages();
      
      final result = await operation();
      
      if (successMessage != null) {
        setSuccess(successMessage);
      }
      
      return result;
    } catch (e) {
      final error = errorMessage ?? e.toString();
      setError(error);
      return null;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    clearMessages();
    super.dispose();
  }
}
