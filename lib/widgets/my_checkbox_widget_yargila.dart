import 'package:flutter/material.dart';

/// Yargila ve Delilleri İncele sayfalarında kullanılan özel checkbox widget'ı
class MyCheckboxWidgetYargila extends StatefulWidget {
  const MyCheckboxWidgetYargila({super.key});

  @override
  State<MyCheckboxWidgetYargila> createState() => _MyCheckboxWidgetYargilaState();
}

class _MyCheckboxWidgetYargilaState extends State<MyCheckboxWidgetYargila> {
  bool isChecked = true;

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [ SizedBox(width: 38),
        Text(
          ' YARGILA ',
          style: TextStyle( fontSize: 18,color: Colors.green),
        ),
        SizedBox(width:100),
        Icon(Icons.gavel_outlined, size: 24, color: Colors.green),
      ],
    );
  }
} 