import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class TreeMenuPageheadlines extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final Widget? menuButton;
  final String? title; // Başlık parametresi eklendi
  final bool isCollapsed; // Arayüzün küçültülüp küçültülmediğini kontrol eder
  final VoidCallback? onToggleCollapse; // Aç/kapa ok butonu için callback

  const TreeMenuPageheadlines({
    super.key,
    this.onMenuPressed,
    this.menuButton,
    this.title, // Başlık parametresi
    this.isCollapsed = false, // Varsayılan olarak açık
    this.onToggleCollapse, // Aç/kapa ok callback'i
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        menuButton ??
            IconButton(
              icon: Icon(
                MdiIcons.menuOpen,
                size: 34,
                color: Colors.red,
              ),
              onPressed: onMenuPressed ?? () {
                debugPrint('Menu button pressed');
              },
            ),
        Expanded(
          child: Center(
            child: Text(
              title ?? "Dava  Aç ", // Parametre varsa onu kullan, yoksa varsayılan
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Aç/kapa ok butonu - Sağa taşındı
        if (onToggleCollapse != null)
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              size: 24,
              color: Colors.black,
            ),
            onPressed: onToggleCollapse,
            tooltip: isCollapsed ? 'Arayüzü Aç' : 'Arayüzü Kapat',
          ),
      ],
    );
  }
}
