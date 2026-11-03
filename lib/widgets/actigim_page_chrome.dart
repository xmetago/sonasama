import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../screens/davaci_unlulur_page.dart';
import '../screens/gelen_davalar_page.dart';
import '../screens/haykirislarim_page.dart';
import '../screens/katildigim_davalar_page.dart' hide Dava, FiveCardCaseInformation;
import '../screens/trend_insights_page.dart';
import '../screens/yargila_page.dart' hide Dava, FiveCardCaseInformation;
import 'common_header_widgets.dart';
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
  bool showLeftIcons = false;
  late bool isHeaderCollapsed;

  @override
  void initState() {
    super.initState();
    isHeaderCollapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isHeaderCollapsed ? 40 : null,
              child: isHeaderCollapsed
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              MdiIcons.menuOpen,
                              size: 18,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                showLeftIcons = !showLeftIcons;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '|| AÇTIĞIM DAVALAR ||',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Color(0xFF2F3E35),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: Colors.black,
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
                          onMenuPressed: () {
                            setState(() {
                              showLeftIcons = !showLeftIcons;
                            });
                          },
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: showLeftIcons ? 60 : 0,
                    child: showLeftIcons
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => GelenDavalarPage(userEmail: widget.userEmail)),
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
                                      MaterialPageRoute(builder: (context) => YargilaPage(userEmail: widget.userEmail)),
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
                                      MaterialPageRoute(builder: (context) => KatildigimDavalarPage(userEmail: widget.userEmail)),
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
                                      MaterialPageRoute(
                                        builder: (context) => DavaciUnlulurPage(userEmail: widget.userEmail),
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
                                      MaterialPageRoute(
                                        builder: (context) => HaykirislarimPage(userEmail: widget.userEmail),
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
                                      MaterialPageRoute(
                                        builder: (context) => TrendInsightsPage(userEmail: widget.userEmail),
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
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(child: widget.listPane),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
