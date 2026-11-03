import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Profil bölümünde temel değerleri simgeleyen ikonları gösterir.
class ProfileIconsRow extends StatelessWidget {
  const ProfileIconsRow({super.key});

  static const iconSize = 19.0;
  static const iconColor = Colors.black54;

  /// Puan kartı lig sırasına göre ikon döndürür: 1 Pusula … 5 ⑲.
  static Widget ligIcon(
    int lig, {
    double size = iconSize,
    Color? color,
  }) {
    final resolvedColor = color ?? iconColor;
    switch (lig) {
      case 1:
        return Icon(MdiIcons.compassOutline, size: size, color: resolvedColor);
      case 2:
        return Icon(MdiIcons.handshake, size: size, color: resolvedColor);
      case 3:
        return Icon(MdiIcons.mirror, size: size, color: resolvedColor);
      case 4:
        return Icon(MdiIcons.scaleBalance, size: size, color: resolvedColor);
      case 5:
        return Text(
          '⑲',
          style: TextStyle(
            fontSize: size,
            color: resolvedColor,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        );
      default:
        return Icon(MdiIcons.compassOutline, size: size, color: resolvedColor);
    }
  }

  /// Değer seviyesi sırasından lig numarasını hesaplar.
  static int ligForRank(int rank) {
    if (rank >= 19) return 5;
    if (rank >= 16) return 4;
    if (rank >= 11) return 3;
    if (rank >= 6) return 2;
    return 1;
  }

  /// Lig numarasına karşılık gelen kısa etiket.
  static String ligLabel(int lig) {
    switch (lig) {
      case 1:
        return 'Pusula';
      case 2:
        return 'El Sıkışma';
      case 3:
        return 'Ayna';
      case 4:
        return 'Terazi';
      case 5:
        return '19';
      default:
        return 'Pusula';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ligIcon(5),
        const SizedBox(width: 4),
        ligIcon(4),
        const SizedBox(width: 4),
        ligIcon(3),
        const SizedBox(width: 4),
        ligIcon(1),
        const SizedBox(width: 4),
        ligIcon(2),
      ],
    );
  }
}
