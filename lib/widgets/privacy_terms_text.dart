import 'package:flutter/material.dart';
import '../screens/privacy_policy_page.dart';
import '../screens/terms_conditions_page.dart';

/// Kayıt ekranında kullanılacak, gizlilik ve koşullar bağlantılı metin widget'ı.
class PrivacyTermsText extends StatelessWidget {
  const PrivacyTermsText({super.key});

  // Modal olarak sayfa açan yardımcı fonksiyon
  void _showModal(BuildContext context, Widget page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(child: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            const Text('Kaydolarak '),
            GestureDetector(
              onTap: () => _showModal(context, const PrivacyPolicyPage()),
              child: const Text(
                'gizlilik',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text(' ve '),
            GestureDetector(
              onTap: () => _showModal(context, const TermsConditionsPage()),
              child: const Text(
                'koşullarınızı',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text(' kabul etmiş olursunuz.'),
          ],
        ),
      ),
    );
  }
} 