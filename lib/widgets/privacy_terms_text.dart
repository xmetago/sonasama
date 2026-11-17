import 'package:flutter/material.dart';
import '../screens/privacy_policy_page.dart';
import '../screens/terms_conditions_page.dart';
import '../theme/seyir_tokens.dart';

/// Kayıt ekranında kullanılacak, gizlilik ve koşullar bağlantılı metin widget'ı.
class PrivacyTermsText extends StatelessWidget {
  const PrivacyTermsText({super.key});

  void _showModal(BuildContext context, Widget page) {
    final palette = SeyirPalette.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SeyirTokens.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(child: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final linkColor = palette.isDark
        ? const Color(0xFF7DD3FC)
        : const Color(0xFF0369A1);
    final body = palette.body(weight: FontWeight.w400);
    final link = body.copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w700,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SeyirTokens.space4,
          horizontal: SeyirTokens.space2,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Kaydolarak ', style: body),
            GestureDetector(
              onTap: () => _showModal(context, const PrivacyPolicyPage()),
              child: Text('gizlilik', style: link),
            ),
            Text(' ve ', style: body),
            GestureDetector(
              onTap: () => _showModal(context, const TermsConditionsPage()),
              child: Text('koşullarınızı', style: link),
            ),
            Text(' kabul etmiş olursunuz.', style: body),
          ],
        ),
      ),
    );
  }
}
