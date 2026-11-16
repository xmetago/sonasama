import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../theme/seyir_tokens.dart';

import '../screens/davaci_unlulur_page.dart';
import '../screens/gelen_davalar_page.dart';
import '../screens/haykirislarim_page.dart';
import '../screens/katildigim_davalar_page.dart' hide Dava, FiveCardCaseInformation;
import '../screens/trend_insights_page.dart';
import '../screens/yargila_page.dart' hide Dava, FiveCardCaseInformation;
import 'common_header_widgets.dart';
import 'shared/app_expandable_icon_menu.dart';
import 'tree_menu_page_headlines.dart';

/// Üst şerit ve sol ikon sütunu. Aç/kapa burada kalır; liste [listPane] olarak gelir.
class ActigimPageChrome extends StatefulWidget {
  const ActigimPageChrome({
    super.key,
    required this.userEmail,
    required this.initiallyCollapsed,
    required this.highlightSaveIcon,
    required this.hasPendingSavedDava,
    required this.headlineDavaCount,
    required this.onShowSavedDavalar,
    required this.rejectedSection,
    required this.listPane,
  });

  final String? userEmail;
  final bool initiallyCollapsed;
  final bool highlightSaveIcon;
  final bool hasPendingSavedDava;
  final int headlineDavaCount;
  final VoidCallback? onShowSavedDavalar;
  final Widget? rejectedSection;
  final Widget listPane;

  @override
  State<ActigimPageChrome> createState() => _ActigimPageChromeState();
}

class _ActigimPageChromeState extends State<ActigimPageChrome> {
  late bool isHeaderCollapsed;

  @override
  void initState() {
    super.initState();
    isHeaderCollapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final ButtonStyle collapsedTap = IconButton.styleFrom(
      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      fixedSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: AppExpandableIconMenu(
          toggleTooltip: 'Sol menü',
          bodyPadding: const EdgeInsets.all(8),
          items: _actigimMenuItems(),
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
            return Column(
              children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isHeaderCollapsed ? SeyirTokens.tapTarget : null,
              child: isHeaderCollapsed
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            style: collapsedTap,
                            icon: Icon(
                              MdiIcons.menuOpen,
                              size: 18,
                              color: palette.textSecondary,
                            ),
                            onPressed: toggle,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '|| AÇTIĞIM DAVALAR ||',
                              style: TextStyle(
                                fontSize: SeyirTokens.typeCaption,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            style: collapsedTap,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: palette.textPrimary,
                            ),
                            onPressed: () {
                              setState(() {
                                isHeaderCollapsed = !isHeaderCollapsed;
                              });
                            },
                            tooltip: 'Arayüzü Aç',
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                            userEmail: widget.userEmail,
                            onShowSavedDavalar: widget.onShowSavedDavalar,
                          ),
                        ),
                        TreeMenuPageheadlines(
                          menuButton: menuButton,
                          onToggleCollapse: () {
                            setState(() {
                              isHeaderCollapsed = !isHeaderCollapsed;
                            });
                          },
                          isCollapsed: isHeaderCollapsed,
                          onShowSavedDavalar: widget.onShowSavedDavalar,
                          highlightSaveIcon: widget.highlightSaveIcon,
                          hasPendingSavedDava: widget.hasPendingSavedDava,
                          headlineDavaCount: widget.headlineDavaCount,
                        ),
                      ],
                    ),
            ),
            if (widget.rejectedSection != null) widget.rejectedSection!,
              ],
            );
          },
          body: widget.listPane,
        ),
      ),
    );
  }

  List<AppExpandableIconMenuItem> _actigimMenuItems() {
    return [
      AppExpandableIconMenuItem(
        icon: MdiIcons.briefcaseArrowLeftRight,
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GelenDavalarPage(userEmail: widget.userEmail)),
          );
        },
      ),
      AppExpandableIconMenuItem(
        assetIcon: 'lib/icons/06_yargila_left_row_icon.png',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => YargilaPage(userEmail: widget.userEmail)),
          );
        },
      ),
      AppExpandableIconMenuItem(
        assetIcon: 'lib/icons/06_left_row_katildigim_davalar_icon.png',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KatildigimDavalarPage(userEmail: widget.userEmail)),
          );
        },
      ),
      AppExpandableIconMenuItem(
        assetIcon: 'lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DavaciUnlulurPage(userEmail: widget.userEmail)),
          );
        },
      ),
      AppExpandableIconMenuItem(
        assetIcon: 'lib/icons/06_left_row_haykirislarim.png',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HaykirislarimPage(userEmail: widget.userEmail)),
          );
        },
      ),
      AppExpandableIconMenuItem(
        icon: MdiIcons.trendingUp,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TrendInsightsPage(userEmail: widget.userEmail)),
          );
        },
      ),
    ];
  }
}
