import 'package:flutter/material.dart';

/// Untitled projesindeki [StarPackagesSection] ile uyumlu: bakiye çipi + üç paket.
class HukumGiftStarStrip extends StatelessWidget {
  const HukumGiftStarStrip({
    super.key,
    required this.davaBaslik,
    required this.yellowStars,
    required this.billingReady,
    required this.onBuyPack,
    this.greenStars = 0,
    this.dense = false,
  });

  final String davaBaslik;
  final int yellowStars;

  /// Kazanılan / harcanabilir yeşil yıldız bakiyesi (Masraflar sayfasında gösterilir).
  final int greenStars;

  /// Play Billing başarıyla bağlandı; false iken paket dokunuşları yerelde yıldız ekler.
  final bool billingReady;
  final void Function(int amount) onBuyPack;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget balanceChip({
      required String label,
      required int count,
      required Color background,
      required Color borderColor,
      required Color textColor,
      required String emoji,
    }) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          dense ? '$emoji $count' : '$emoji $label: $count ⭐',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 0.15,
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(
        left: dense ? 8 : 12,
        right: dense ? 8 : 12,
        top: 6,
      ),
      padding: EdgeInsets.all(dense ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE9E2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF101815).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (davaBaslik.trim().isNotEmpty)
            Text(
              davaBaslik.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF1B2A23),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (davaBaslik.trim().isNotEmpty) SizedBox(height: dense ? 6 : 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              balanceChip(
                label: 'Bakiye',
                count: yellowStars,
                background: Colors.amber.shade50,
                borderColor: Colors.orange.shade100,
                textColor: Colors.orange.shade900,
                emoji: '🟡',
              ),
              balanceChip(
                label: 'Yeşil',
                count: greenStars,
                background: Colors.green.shade50,
                borderColor: Colors.green.shade200,
                textColor: Colors.green.shade900,
                emoji: '🟢',
              ),
            ],
          ),
          SizedBox(height: dense ? 8 : 10),
          Text(
            'YILDIZ SATIN AL',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.deepOrange.shade800,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: dense ? 8 : 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _PaketChip(
                  title: 'Küçük',
                  stars: 50,
                  dense: dense,
                  onTap: () => onBuyPack(50),
                ),
              ),
              SizedBox(width: dense ? 6 : 8),
              Expanded(
                child: _PaketChip(
                  title: 'Orta',
                  stars: 150,
                  dense: dense,
                  onTap: () => onBuyPack(150),
                ),
              ),
              SizedBox(width: dense ? 6 : 8),
              Expanded(
                child: _PaketChip(
                  title: 'Büyük',
                  stars: 500,
                  dense: dense,
                  onTap: () => onBuyPack(500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaketChip extends StatelessWidget {
  const _PaketChip({
    required this.title,
    required this.stars,
    required this.onTap,
    this.dense = false,
  });

  final String title;
  final int stars;
  final VoidCallback onTap;
  final bool dense;

  String get priceLabel {
    if (stars == 50) return '\$1.99';
    if (stars == 150) return '\$4.99';
    if (stars == 500) return '\$12.99'; // En iyi birim fiyat
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final Color border = Colors.orange.shade100;

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 10 : 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: dense ? 2 : 4),
              Text(
                '$stars ⭐',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.orange.shade800,
                  fontSize: dense ? 12 : 13,
                ),
              ),
              Text(
                priceLabel,
                style: TextStyle(
                  fontSize: dense ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: stars == 500
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
