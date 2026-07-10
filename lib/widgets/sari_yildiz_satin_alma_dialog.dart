import 'package:flutter/material.dart';

import '../services/play_billing_service.dart';
import '../services/user_star_balance_store.dart';

/// KURAL 4: Sarı yıldız satın alma süreci.
///
/// Sistem haksız tarafın sarı yıldız bakiyesini kontrol eder; yetersizse bu
/// dialog açılır. Kullanıcı Küçük / Orta / Büyük paketten birini seçip Satın Al
/// veya İptal yapabilir. Başarılı satın alma sonrası, çağıran tarafa true
/// döndürülür ve onay akışı tekrar denenir.
class SariYildizSatinAlmaDialog extends StatefulWidget {
  const SariYildizSatinAlmaDialog({
    super.key,
    required this.userEmail,
    required this.requiredAmount,
    required this.currentAmount,
    this.davaAdi,
  });

  /// Yıldız satın alacak kullanıcının e-postası (haksız tarafın e-postası).
  final String userEmail;

  /// İhtiyaç duyulan toplam sarı yıldız (cost).
  final int requiredAmount;

  /// Mevcut sarı yıldız sayısı.
  final int currentAmount;

  /// Bağlam için dava adı (opsiyonel).
  final String? davaAdi;

  /// Yardımcı yöntem.
  static Future<bool> show(
    BuildContext context, {
    required String userEmail,
    required int requiredAmount,
    required int currentAmount,
    String? davaAdi,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SariYildizSatinAlmaDialog(
        userEmail: userEmail,
        requiredAmount: requiredAmount,
        currentAmount: currentAmount,
        davaAdi: davaAdi,
      ),
    );
    return result ?? false;
  }

  @override
  State<SariYildizSatinAlmaDialog> createState() =>
      _SariYildizSatinAlmaDialogState();
}

class _SariYildizSatinAlmaDialogState extends State<SariYildizSatinAlmaDialog> {
  static const List<_PaketTanim> _paketler = <_PaketTanim>[
    _PaketTanim(title: 'Küçük', stars: 50, priceLabel: r'$1.99'),
    _PaketTanim(title: 'Orta', stars: 150, priceLabel: r'$4.99'),
    _PaketTanim(title: 'Büyük', stars: 500, priceLabel: r'$12.99'),
  ];

  int _seciliPaketIndex = 1;
  bool _islemDevamEdiyor = false;

  Future<void> _satinAl() async {
    if (_islemDevamEdiyor) return;
    setState(() => _islemDevamEdiyor = true);
    final paket = _paketler[_seciliPaketIndex];
    try {
      bool billingOk = false;
      final String? productId =
          PlayBillingService.productIdForStarAmount(paket.stars);
      if (productId != null) {
        try {
          billingOk = await globalPlayBilling.buyConsumable(productId);
        } catch (_) {
          billingOk = false;
        }
      }

      // Billing başarısız olsa bile lokal bakiyeyi artırırız (test/sandbox).
      await UserStarBalanceStore.addYellowStars(
        widget.userEmail,
        paket.stars,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            billingOk
                ? '✅ ${paket.stars} sarı yıldız satın alındı.'
                : '⚠️ Billing onaylanmadı, yerel bakiye güncellendi (+${paket.stars} ⭐).',
          ),
          backgroundColor:
              billingOk ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Satın alma sırasında hata: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() => _islemDevamEdiyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🟡', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sarı Yıldız Yetersiz',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _islemDevamEdiyor
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  tooltip: 'İptal',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.davaAdi != null && widget.davaAdi!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '"${widget.davaAdi!.trim()}" davası için',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Masrafı onaylamak için en az ${widget.requiredAmount} ⭐ '
                      'sarı yıldıza ihtiyacın var. Şu an: ${widget.currentAmount} ⭐.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Paket Seç',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.deepOrange.shade800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                for (int i = 0; i < _paketler.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _PaketSecimKarti(
                      tanim: _paketler[i],
                      secili: _seciliPaketIndex == i,
                      onTap: _islemDevamEdiyor
                          ? null
                          : () => setState(() => _seciliPaketIndex = i),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // NOT: Üstteki Column `crossAxisAlignment: stretch` olduğu için
            // Row'u doğrudan kullanmak butonu tüm genişliğe yayar; uygulama
            // temasındaki ElevatedButton.minimumSize infinity ise
            // `BoxConstraints forces an infinite width` hatası fırlatır.
            // Align + Row(mainAxisSize.min) ile butona doğal genişliği veriyoruz.
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    onPressed: _islemDevamEdiyor
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _islemDevamEdiyor ? null : _satinAl,
                    icon: _islemDevamEdiyor
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shopping_cart_checkout),
                    label: Text(
                      _islemDevamEdiyor
                          ? 'İşleniyor…'
                          : 'Satın Al (${_paketler[_seciliPaketIndex].stars} ⭐)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaketTanim {
  const _PaketTanim({
    required this.title,
    required this.stars,
    required this.priceLabel,
  });
  final String title;
  final int stars;
  final String priceLabel;
}

class _PaketSecimKarti extends StatelessWidget {
  const _PaketSecimKarti({
    required this.tanim,
    required this.secili,
    required this.onTap,
  });

  final _PaketTanim tanim;
  final bool secili;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? Colors.orange.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: secili ? Colors.orange.shade700 : Colors.orange.shade100,
          width: secili ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                tanim.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tanim.stars} ⭐',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.orange.shade800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tanim.priceLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tanim.stars == 500
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
