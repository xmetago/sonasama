import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/seyir_tokens.dart';
import '../utils/hashtag_text_helper.dart';
import 'haykir_page.dart';

class GununHaykirisiPage extends StatelessWidget {
  const GununHaykirisiPage({
    super.key,
    required this.isAuthenticated,
    required this.userEmail,
    this.onRequestLogin,
  });

  final bool isAuthenticated;
  final String? userEmail;
  final VoidCallback? onRequestLogin;

  static const String _completedKey = 'gunun_haykirisi_completed';

  /// Günün sloganı. Form bu metinle açılır ve düzenlenebilir.
  static const String daySlogan = 'Sessiz kalmak, zulmü onaylamaktır.';

  /// Günün haykır metni. Formun detay alanı bu metinle açılır.
  static const String dayDetail =
      'Bugün, dünyadaki tüm haksızlıklara karşı tek bir nefes oluyoruz. '
      'Zulme karşı durmak, mazlumun yanında saf tutmak için sesini yükselt!';

  static Future<bool> isCompletedForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_completedKey}_$email') ?? false;
  }

  static Future<void> saveCompletion(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_completedKey}_$email', true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text('Günün Haykırışı', style: palette.headline()),
        centerTitle: true,
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            const _HaykirHeader(),
            const SizedBox(height: 24),

            // Günün Teması ve Haykırış Örneği
            const _SectionTitle('BUGÜNÜN MESELESİ: ADALET'),
            const SizedBox(height: 12),
            const _GununMesajiCard(
              quote: daySlogan,
              author: "Anonim",
              description: dayDetail,
            ),

            const SizedBox(height: 24),

            const _SectionTitle('SENİN HAYKIRIŞIN'),
            const SizedBox(height: 12),
            // Örnek haykırış metni
            const _InfoCard(
              title: 'Haykırıyorum Çünkü:',
              body: 'Dünyanın neresinde olursa olsun, bir çocuğun gözyaşı dökmesine sebep olan düzene '
                  'İTİRAZ EDİYORUM! Ben buradayım ve sessiz kalmayacağım.#Epstein',
            ),

            const SizedBox(height: 24),

            const _SectionTitle('DİREN'),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Diren:',
              body: 'Halay çekme',
            ),

            const SizedBox(height: 30),
            const _ClosingHaykirText(),
            const SizedBox(height: 24),

            _HaykirDecisionArea(
              isAuthenticated: isAuthenticated,
              userEmail: userEmail,
              onRequestLogin: onRequestLogin,
            ),
          ],
        ),
      ),
    );
  }
}

/// Günün Mesajını vurgulayan özel kart bileşeni
class _GununMesajiCard extends StatelessWidget {
  const _GununMesajiCard({
    required this.quote,
    required this.author,
    required this.description,
  });

  final String quote;
  final String author;
  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final quoteStyle = palette.headline(
      color: palette.foreground(Colors.orange.shade800),
    ).copyWith(fontStyle: FontStyle.italic);
    final bodyStyle = palette.body(color: palette.textPrimary);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.tint(Colors.orange.shade700),
        borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
        border: Border.all(color: palette.tintBorder(Colors.orange.shade700), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote, color: palette.foreground(Colors.orange.shade800), size: 40),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: quoteStyle,
          ),
          const SizedBox(height: 8),
          Text('- $author', style: palette.body(weight: FontWeight.w600)),
          const Divider(height: 32),
          SelectableText.rich(
            TextSpan(
              style: bodyStyle,
              children: buildHashtagAwareSpans(
                description,
                baseStyle: bodyStyle,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HaykirHeader extends StatelessWidget {
  const _HaykirHeader();

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.orange.shade700,
          child: const Icon(Icons.campaign, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          'VİCDANIN SESİ',
          style: palette.display().copyWith(letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Text(
      text,
      style: palette.body(
        weight: FontWeight.w800,
        color: palette.textSecondary,
      ).copyWith(letterSpacing: 1.1),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final bodyStyle = palette.body(color: palette.textPrimary);
    return Semantics(
      label: title,
      child: Card(
      elevation: 0,
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(
              TextSpan(
                style: bodyStyle,
                children: buildHashtagAwareSpans(
                  body,
                  baseStyle: bodyStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ClosingHaykirText extends StatelessWidget {
  const _ClosingHaykirText();

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Text(
      'Şimdi sıra sende. Bu haksızlığa karşı sessizliğini bozmaya hazır mısın?',
      textAlign: TextAlign.center,
      style: palette.title(weight: FontWeight.w600),
    );
  }
}

class _HaykirDecisionArea extends StatelessWidget {
  const _HaykirDecisionArea({
    required this.isAuthenticated,
    required this.userEmail,
    required this.onRequestLogin,
  });

  final bool isAuthenticated;
  final String? userEmail;
  final VoidCallback? onRequestLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFC2410C), Color(0xFFEA580C)],
        ),
      ),
      child: ElevatedButton(
        onPressed: () => _onHaydiHaykir(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, SeyirTokens.tapTarget),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'HAYDİ HAYKIR',
          style: TextStyle(
            fontSize: SeyirTokens.typeHeadline,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _onHaydiHaykir(BuildContext context) {
    if (isAuthenticated) {
      _doHaykir(context);
    } else {
      _showLoginRequired(context);
    }
  }

  // ... Diğer metodlar (_showLoginRequired, _doHaykir) öncekiyle aynı kalabilir ...
  // (Kısalık adına buraya tekrar eklemiyorum ancak mantık aynıdır.)
  void _showLoginRequired(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giriş gerekli'),
        content: const Text('Haykırmak için önce giriş yapmalısın.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onRequestLogin != null) onRequestLogin!();
            },
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  Future<void> _doHaykir(BuildContext context) async {
    final email = (userEmail ?? '').trim();
    if (email.isEmpty) return;
    await GununHaykirisiPage.saveCompletion(email);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HaykirPage(
          userEmail: email,
          initialShowForm: true,
          initialSlogan: GununHaykirisiPage.daySlogan,
          initialDetay: GununHaykirisiPage.dayDetail,
        ),
      ),
    );
  }
}