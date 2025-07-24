import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'energy_bar.dart';

/// Profil bölümünde rütbe ikonlarını göstermek için kullanılır.
/// Solda: 03_profile_row_rutbe_icon.png, Sağda: 03_profile_row_rutbeloading_icon.png
class ProfileIconsRow extends StatelessWidget {
  const ProfileIconsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Rütbe Army ikonu
        Icon(
          MdiIcons.knifeMilitary,
          size: 15,
          color: Colors.black54,
        ),
        Icon(
          MdiIcons.knifeMilitary,
          size: 15,
          color: Colors.black54,
        ), Icon(
          MdiIcons.knifeMilitary,
          size: 15,
          color: Colors.black54,
        ),

        Icon(
          MdiIcons.knifeMilitary,
          size: 15,
          color: Colors.black54,
        ),
        Icon(
          MdiIcons.knifeMilitary,
          size: 15,
          color: Colors.black54,
        ),
        // Rütbe Loading ikonu (Enerji Bar)
        SizedBox(
          width: 100,
          height: 19,
          child: EnergyBar(value: 0.7),
        ),
      ],
    );
  }
} 