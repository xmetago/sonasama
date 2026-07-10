import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../screens/actigim_davalar_page.dart';
import '../screens/davaci_unlulur_page.dart';
import '../screens/gelen_davalar_page.dart';
import '../screens/haykir_page.dart';
import '../screens/katildigim_davalar_page.dart';
import '../screens/trend_insights_page.dart';
import '../screens/yargila_page.dart';

/// [CezalarPage] / [CezaYonetimPage]: kırmızı menü + ortalanmış başlık;
/// [onToggleCollapse] verilirse [DavaAcPage] [TreeMenuPageheadlines] ile aynı ok davranışı.
class CezalarMenuTitleRow extends StatelessWidget {
  final VoidCallback onToggleLeftNav;
  final String title;
  final bool isHeaderCollapsed;
  final VoidCallback? onToggleCollapse;

  const CezalarMenuTitleRow({
    super.key,
    required this.onToggleLeftNav,
    required this.title,
    this.isHeaderCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Image.asset(
              'lib/icons/menu_red.png',
              width: 24,
              height: 24,
            ),
            onPressed: onToggleLeftNav,
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(fontSize: 19),
              ),
            ),
          ),
          if (onToggleCollapse != null)
            IconButton(
              icon: Icon(
                isHeaderCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 24,
                color: Colors.black,
              ),
              onPressed: onToggleCollapse,
              tooltip: isHeaderCollapsed ? 'Arayüzü Aç' : 'Arayüzü Kapat',
            ),
        ],
      ),
    );
  }
}

/// [CezalarPage] sol açılır şerit ile aynı ikonlar ve navigasyon.
class CezalarLeftIconScrollColumn extends StatelessWidget {
  final String? userEmail;

  const CezalarLeftIconScrollColumn({
    super.key,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => GelenDavalarPage(userEmail: userEmail),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
            child: Icon(
              MdiIcons.briefcaseArrowLeftRight,
              size: 24,
              color: Colors.black54,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => YargilaPage(userEmail: userEmail),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: Image.asset('lib/icons/06_yargila_left_row_icon.png', width: 24, height: 24),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => KatildigimDavalarPage(userEmail: userEmail),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: Image.asset('lib/icons/06_left_row_katildigim_davalar_icon.png', width: 24, height: 24),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => ActigimDavalarPage(userEmail: userEmail),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: 24, height: 24),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => DavaciUnlulurPage(userEmail: userEmail),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: Image.asset('lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png', width: 24, height: 24),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => HaykirPage(userEmail: userEmail),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: Image.asset('lib/icons/06_left_row_haykirislarim.png', width: 24, height: 24),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => TrendInsightsPage(userEmail: userEmail),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
            child: Icon(
              MdiIcons.trendingUp,
              size: 24,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

/// [CezalarPage] orta 50px dikey ikon şeridi (çekiç, delil, ceza, kelepçe).
/// Geri sayfaya bağımlılık vermemek için navigasyon üst widget’tan gelir.
class CezalarMiddleVerticalIconRail extends StatelessWidget {
  final VoidCallback onDelilleriIncele;
  final VoidCallback onCezalarBriefcase;
  final VoidCallback onCezalarHandcuffs;

  const CezalarMiddleVerticalIconRail({
    super.key,
    required this.onDelilleriIncele,
    required this.onCezalarBriefcase,
    required this.onCezalarHandcuffs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
    );
  }
}
