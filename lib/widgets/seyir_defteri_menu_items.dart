import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../screens/actigim_davalar_page.dart';
import '../screens/davaci_unlulur_page.dart';
import '../screens/gelen_davalar_page.dart';
import '../screens/haykirislarim_page.dart';
import '../screens/hesap_gizlilik_ayarlari_page.dart';
import '../screens/katildigim_davalar_page.dart' as katildigim_page;
import '../screens/saved_haykirlar_page.dart';
import '../screens/statistics_dashboard_page.dart';
import '../screens/trend_insights_page.dart';
import '../screens/yargila_page.dart';
import 'shared/app_expandable_icon_menu.dart';

/// Arkadaş satırı: dikey 4.
const EdgeInsets kSeyirFriendRowPadding = EdgeInsets.symmetric(vertical: 4);

/// Profil satırı: dikey 2, yatay 4.
const EdgeInsets kSeyirProfilePadding = EdgeInsets.symmetric(vertical: 2, horizontal: 4);

/// Menü düğmesinin oturduğu başlık satırı: dikey 4, yatay 8.
const EdgeInsets kSeyirHeadlinePadding = EdgeInsets.symmetric(vertical: 4, horizontal: 8);

/// Seyir defteri sol şeridindeki ikonlar. Ana sayfa ve gelen davalar aynı listeyi kullanır.
List<AppExpandableIconMenuItem> buildSeyirDefteriMenuItems(
  BuildContext context, {
  String? userEmail,
}) {
  return [
    AppExpandableIconMenuItem(
      onTap: () {},
      customChild: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GelenDavalarPage(userEmail: userEmail),
            ),
          );
        },
        child: const Padding(
          padding: kSeyirMenuFirstIconPadding,
          child: _SeyirIncomingMenuIcon(),
        ),
      ),
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      assetIcon: 'lib/icons/06_yargila_left_row_icon.png',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YargilaPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      assetIcon: 'lib/icons/06_left_row_katildigim_davalar_icon.png',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                katildigim_page.KatildigimDavalarPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      assetIcon: 'lib/icons/06_left_row_actigim_davalar_icon.png',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActigimDavalarPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      assetIcon: 'lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DavaciUnlulurPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      assetIcon: 'lib/icons/06_left_row_haykirislarim.png',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HaykirislarimPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      icon: MdiIcons.trendingUp,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrendInsightsPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      icon: MdiIcons.bookmarkMultipleOutline,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SavedHaykirlarPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      icon: MdiIcons.chartBar,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StatisticsDashboardPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      icon: MdiIcons.cog,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HesapGizlilikAyarlariPage(userEmail: userEmail),
          ),
        );
      },
    ),
    AppExpandableIconMenuItem(
      padding: kSeyirMenuIconPadding,
      icon: MdiIcons.logout,
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Uygulamadan Çıkış'),
              content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Çıkış'),
                ),
              ],
            );
          },
        );

        if (shouldLogout != true) return;

        Provider.of<AuthProvider>(context, listen: false).logout();

        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      },
    ),
  ];
}

/// Gelen dava varken sol şeritteki çanta ikonunu 500 ms aralıkla yakar.
class _SeyirIncomingMenuIcon extends StatefulWidget {
  const _SeyirIncomingMenuIcon();

  @override
  State<_SeyirIncomingMenuIcon> createState() => _SeyirIncomingMenuIconState();
}

class _SeyirIncomingMenuIconState extends State<_SeyirIncomingMenuIcon> {
  bool _highlightIncomingIcon = false;
  bool _hasIncomingDavaForBlink = false;
  Timer? _incomingIconBlinkTimer;

  @override
  void dispose() {
    _incomingIconBlinkTimer?.cancel();
    super.dispose();
  }

  void _updateIncomingIconBlinkState(bool shouldBlink) {
    if (_hasIncomingDavaForBlink == shouldBlink) return;
    _hasIncomingDavaForBlink = shouldBlink;
    _incomingIconBlinkTimer?.cancel();

    if (!shouldBlink) {
      if (mounted) {
        setState(() {
          _highlightIncomingIcon = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _highlightIncomingIcon = true;
      });
    }

    _incomingIconBlinkTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_hasIncomingDavaForBlink) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _highlightIncomingIcon = false;
          });
        }
        return;
      }
      setState(() {
        _highlightIncomingIcon = !_highlightIncomingIcon;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DavaProvider>(
      builder: (context, davaProvider, child) {
        final shouldBlink = davaProvider.incomingDavaCount > 0;
        if (_hasIncomingDavaForBlink != shouldBlink) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _updateIncomingIconBlinkState(shouldBlink);
          });
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _highlightIncomingIcon || _hasIncomingDavaForBlink
                ? Colors.blue.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _highlightIncomingIcon || _hasIncomingDavaForBlink
                  ? Colors.blueAccent
                  : Colors.transparent,
              width: _highlightIncomingIcon
                  ? 3
                  : (_hasIncomingDavaForBlink ? 1.5 : 0),
            ),
            boxShadow: _highlightIncomingIcon
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.45),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            MdiIcons.briefcaseArrowLeftRight,
            size: 24,
            color: Colors.black54,
          ),
        );
      },
    );
  }
}
