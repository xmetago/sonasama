import 'package:flutter/material.dart';
import '../widgets/shared/dava_count_headline_page.dart';

class KatildigimDavalarKactanePage extends StatelessWidget {
  static const int iconCount = 13;
  const KatildigimDavalarKactanePage({super.key});

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
      children: [ const SizedBox(width: 5),

        const Text(
          'KATILDIĞIM  DAVALAR KAÇ TANE ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),

        ),
        const SizedBox(width: 19),
        Stack(
          children: [
            Image.asset(
              'lib/icons/06_left_row_katildigim_davalar_icon.png',
              width: 30,
              height: 30,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  KatildigimDavalarKactanePage.iconCount.toString(), // Buradaki sayı dinamik (şimdi 13)
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),


        // const SizedBox(width: 8),
        // const Text('Şartları kabul ediyorum'),
      ],
    );
  }
} 