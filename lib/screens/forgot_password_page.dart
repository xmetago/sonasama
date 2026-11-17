// lib/screens/forgot_password_page.dart
// Şifremi Unuttum sayfası. Kayıtlı e-posta için Firebase Auth sıfırlama bağlantısı gönderir.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/seyir_tokens.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorText;
  String? _resultMessage;
  bool _resultOk = false;
  bool _sending = false;

  static const Color _emerald = Color(0xFF059669);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!AuthProvider.isValidEmail(email)) {
      setState(() {
        _errorText = 'Geçerli bir e-posta adresi giriniz.';
        _resultMessage = null;
        _resultOk = false;
      });
      return;
    }

    final AuthProvider? auth = _auth();
    if (auth == null) {
      setState(() {
        _errorText = null;
        _resultOk = false;
        _resultMessage = 'Şifre sıfırlama e-postası gönderilemedi. Lütfen tekrar deneyin.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _errorText = null;
      _resultMessage = null;
    });

    final error = await auth.sendPasswordResetEmail(email);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _resultOk = error == null;
      _resultMessage = error ??
          'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.';
    });
  }

  AuthProvider? _auth() {
    try {
      return Provider.of<AuthProvider>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final cardBorder = palette.isDark ? SeyirTokens.neutral400 : palette.border;
    final titleColor = palette.isDark ? SeyirTokens.brand : _emerald;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şifremi Unuttum',
          style: TextStyle(
            fontSize: SeyirTokens.typeDisplay,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.isDark
                ? const [Color(0xFF022C22), Color(0xFF064E3B)]
                : const [Color(0xFFF0FDFA), Color(0xFFD1FAE5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(SeyirTokens.space4),
              padding: const EdgeInsets.all(SeyirTokens.space6),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: SeyirTokens.radiusLgAll,
                border: Border.all(color: cardBorder),
                boxShadow: palette.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Şifre Sıfırlama',
                    style: palette.display(color: titleColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SeyirTokens.space4),
                  Text(
                    'Kayıtlı e-posta adresinizi girin. Şifre sıfırlama bağlantısı e-posta adresinize gönderilecektir.',
                    style: palette.body(
                      weight: FontWeight.w400,
                      color: palette.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SeyirTokens.space6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_sending,
                    style: palette.body(weight: FontWeight.w400).copyWith(
                      fontSize: SeyirTokens.typeTitle,
                    ),
                    decoration: InputDecoration(
                      labelText: 'E-Posta',
                      hintText: 'ornek@email.com',
                      labelStyle: palette.body(color: palette.textSecondary),
                      hintStyle: palette.body(
                        weight: FontWeight.w400,
                        color: palette.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: SeyirTokens.radiusSmAll,
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: SeyirTokens.radiusSmAll,
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: SeyirTokens.radiusSmAll,
                        borderSide: BorderSide(color: titleColor, width: 2),
                      ),
                      errorText: _errorText,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: SeyirTokens.space4,
                        vertical: SeyirTokens.space3,
                      ),
                    ),
                  ),
                  const SizedBox(height: SeyirTokens.space6),
                  SizedBox(
                    width: double.infinity,
                    height: SeyirTokens.tapTarget,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emerald,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _emerald.withValues(alpha: 0.6),
                        disabledForegroundColor: Colors.white,
                        minimumSize: const Size(
                          double.infinity,
                          SeyirTokens.tapTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: SeyirTokens.space3,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: SeyirTokens.radiusSmAll,
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sıfırlama Linki Gönder',
                              style: TextStyle(
                                fontSize: SeyirTokens.typeTitle,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  if (_resultMessage != null) ...[
                    const SizedBox(height: SeyirTokens.space4),
                    Container(
                      padding: const EdgeInsets.all(SeyirTokens.space3),
                      decoration: BoxDecoration(
                        color: _resultOk
                            ? (palette.isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFD1FAE5))
                            : SeyirTokens.reject.withValues(
                                alpha: palette.isDark ? 0.22 : 0.10,
                              ),
                        borderRadius: SeyirTokens.radiusSmAll,
                        border: Border.all(
                          color: _resultOk
                              ? (palette.isDark
                                  ? const Color(0xFF6EE7B7)
                                  : _emerald)
                              : (palette.isDark
                                  ? const Color(0xFFFCA5A5)
                                  : SeyirTokens.reject),
                        ),
                      ),
                      child: Text(
                        _resultMessage!,
                        style: palette.body(
                          weight: FontWeight.w400,
                          color: _resultOk
                              ? (palette.isDark
                                  ? const Color(0xFF6EE7B7)
                                  : _emerald)
                              : (palette.isDark
                                  ? const Color(0xFFFCA5A5)
                                  : SeyirTokens.reject),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
