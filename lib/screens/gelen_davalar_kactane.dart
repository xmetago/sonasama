import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/shared/dava_count_headline_page.dart';

/// Gelen Davalar Kaç Tane Sayfası - GelenDavalarPage'in kopyası
class GelenDavalarKactanePage extends StatelessWidget {
  static const int iconCount = 13;
  const GelenDavalarKactanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DavaCountHeadlinePage(
      iconCount: iconCount,
      headline: MyCheckboxWidget(),
    );
  }
}

// Stateful checkbox widget (dava_ac_page.dart ile aynı)
class MyCheckboxWidget extends StatefulWidget {
  const MyCheckboxWidget({super.key});

  @override
  State<MyCheckboxWidget> createState() => _MyCheckboxWidgetState();
}

class _MyCheckboxWidgetState extends State<MyCheckboxWidget> {
  bool isChecked = true;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Row(
      children: [ const SizedBox(width: 38),

        Text(
          '8-HÜKÜM || ',
          style: palette.display(weight: FontWeight.w600).copyWith(
            letterSpacing: 0.8,
          ),
        ),

        Stack(
          children: [
            Icon(
              MdiIcons.gavel,
              size: 24,
              color: palette.textSecondary,
            ),

          ],
        ),


        // const SizedBox(width: 8),
        // const Text('Şartları kabul ediyorum'),
      ],
    );
  }
} 