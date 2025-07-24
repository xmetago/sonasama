// lib/screens/forgot_password_page.dart
// Şifremi Unuttum sayfası. Kullanıcı e-posta adresini girerek şifre sıfırlama talebinde bulunabilir.
// Material 3, responsive, sade ve modern Flutter UI. main.dart ile uyumlu.

import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorText;
  bool _submitted = false;

  // E-posta doğrulama fonksiyonu
  bool _validateEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  // Şifre sıfırlama isteği gönderme simülasyonu
  void _submit() {
    final email = _emailController.text.trim();
    setState(() {
      if (_validateEmail(email)) {
        _errorText = null;
        _submitted = true;
      } else {
        _errorText = 'Geçerli bir e-posta adresi giriniz.';
        _submitted = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDFA), Color(0xFFD1FAE5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  const Text(
                    'Şifre Sıfırlama',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Açıklama
                  const Text(
                    'Kayıtlı e-posta adresinizi girin. Şifre sıfırlama bağlantısı e-posta adresinize gönderilecektir.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // E-posta giriş alanı
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-Posta',
                      hintText: 'ornek@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                      ),
                      errorText: _errorText,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Gönder butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Sıfırlama Linki Gönder'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Başarı mesajı
                  if (_submitted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
                        style: TextStyle(color: Color(0xFF059669), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 