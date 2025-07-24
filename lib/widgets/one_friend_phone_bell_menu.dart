import 'package:flutter/material.dart';

/// OneFriendPhoneBellMenu: Arkadaş, Telefon, Bildirim ve Menü ikonlarını yatayda gösteren widget
/// Material 3 uyumlu, responsive ve sade bir tasarıma sahiptir.
class OneFriendPhoneBellMenu extends StatelessWidget {
  final void Function()? onFriendsTap;
  final void Function()? onPhoneTap;
  final void Function()? onBellTap;
  final void Function()? onMenuTap;

  const OneFriendPhoneBellMenu({
    Key? key,
    this.onFriendsTap,
    this.onPhoneTap,
    this.onBellTap,
    this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Arkadaşlar ikonu
        Flexible(
          child: IconButton(
            icon: Image.asset('lib/icons/02_top_row_friends.png', width: 24, height: 24),
            onPressed: onFriendsTap,
            tooltip: 'Arkadaşlar',
          ),
        ),
        // Telefon ikonu
        Flexible(
          child: IconButton(
            icon: Image.asset('lib/icons/02_top_row_telefon_icon.png', width: 24, height: 24),
            onPressed: onPhoneTap,
            tooltip: 'Telefon',
          ),
        ),
        // Bildirim ikonu
        Flexible(
          child: IconButton(
            icon: Image.asset('lib/icons/02_top_row_bildirim_icon.png', width: 24, height: 24),
            onPressed: onBellTap,
            tooltip: 'Bildirimler',
          ),
        ),
        // Menü ikonu
        const Flexible(
          child: Icon(Icons.menu_open_rounded, size: 28),
        ),
      ],
    );
  }
} 