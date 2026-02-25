import '../models/registration_model.dart';

class UserSessionService {
  static RegistrationModel? _currentUser;

  static RegistrationModel? getCurrentUser() {
    return _currentUser;
  }

  static void setCurrentUser(RegistrationModel user) {
    _currentUser = user;
  }

  static void clearCurrentUser() {
    _currentUser = null;
  }

  static bool isLoggedIn() {
    return _currentUser != null;
  }
}
