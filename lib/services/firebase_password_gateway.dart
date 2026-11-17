import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth çağrılarından gelen kod. Arayüz Türkçe metne çevirir.
class PasswordAuthException implements Exception {
  PasswordAuthException(this.code);

  final String code;
}

/// Firebase Auth şifre sıfırlama ve yeniden doğrulama.
class FirebasePasswordGateway {
  const FirebasePasswordGateway();

  static bool _firebaseMissing(Object error) {
    final text = error.toString();
    return text.contains('No Firebase App') ||
        text.contains('MissingPluginException') ||
        text.contains('FirebaseException');
  }

  /// Kayıtlı adrese şifre sıfırlama e-postası gönderir.
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw PasswordAuthException(error.code);
    } catch (error) {
      if (_firebaseMissing(error)) {
        throw PasswordAuthException('unavailable');
      }
      throw PasswordAuthException('unavailable');
    }
  }

  /// Açık Firebase oturumunda yeniden doğrular ve şifreyi günceller.
  ///
  /// Oturum yoksa yerel hesap güncellemesi yeterli olduğu için çıkar.
  static Future<void> reauthenticateAndUpdatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (error) {
      if (_firebaseMissing(error)) return;
      rethrow;
    }
    if (user == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email ?? email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw PasswordAuthException(error.code);
    } catch (error) {
      if (_firebaseMissing(error)) return;
      rethrow;
    }
  }
}
