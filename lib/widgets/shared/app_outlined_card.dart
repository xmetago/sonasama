import 'package:flutter/material.dart';

/// Yükseklik 0, 16 köşe, `grey[200]` kenar, 16 iç boşluk.
class AppOutlinedCard extends StatelessWidget {
  const AppOutlinedCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget padded = Padding(padding: padding, child: child);
    return Card(
      margin: margin,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: onTap == null
          ? padded
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: padded,
            ),
    );
  }
}
