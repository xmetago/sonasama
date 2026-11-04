import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
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
    return Row(
      children: [ const SizedBox(width: 38),

        const Text(
          '8-HÜKÜM || ',
          style: TextStyle(
            fontSize: 22,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF2F3E35),
          ),

        ),

        Stack(
          children: [
            Icon(
              MdiIcons.gavel,
              size: 24,
              color: Colors.black54,
            ),

          ],
        ),


        // const SizedBox(width: 8),
        // const Text('Şartları kabul ediyorum'),
      ],
    );
  }
} 