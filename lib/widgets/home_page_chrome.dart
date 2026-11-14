import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../screens/chat_page.dart';
import '../screens/dava_ac_page.dart' as dava_ac;
import '../screens/home_page.dart';
import '../theme/seyir_tokens.dart';
import '../utils/dialog_utils.dart';
import 'common_header_widgets.dart';
import 'seyir_defteri_menu_items.dart';
import 'shared/app_expandable_icon_menu.dart';

/// Üst şerit ve sol menü. Katlanma burada kalır. İkon listesi seyir defteri menüsündedir.
class HomePageChrome extends StatefulWidget {
  const HomePageChrome({
    super.key,
    required this.userEmail,
    required this.profileEmail,
    required this.targetUserEmail,
    required this.feed,
  });

  final String? userEmail;
  final String? profileEmail;
  final String? targetUserEmail;
  final Widget feed;

  @override
  State<HomePageChrome> createState() => _HomePageChromeState();
}

class _HomePageChromeState extends State<HomePageChrome> {
  bool isHeaderCollapsed = false;

  bool _onFeedScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! UserScrollNotification) return false;
    if (notification.direction == ScrollDirection.reverse &&
        !isHeaderCollapsed) {
      setState(() => isHeaderCollapsed = true);
    } else if (notification.direction == ScrollDirection.forward &&
        isHeaderCollapsed) {
      setState(() => isHeaderCollapsed = false);
    }
    return false;
  }

  void _toggleHeader() {
    setState(() => isHeaderCollapsed = !isHeaderCollapsed);
  }

  ButtonStyle _compactIconStyle(SeyirPalette palette) {
    return IconButton.styleFrom(
      foregroundColor: palette.textSecondary,
      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      fixedSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
  }

  Widget _brandMark(SeyirPalette palette) {
    final Color ink = palette.onSolid(SeyirTokens.brand);
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userEmail: widget.userEmail),
          ),
        );
      },
      borderRadius: SeyirTokens.radiusMdAll,
      child: SizedBox(
        width: SeyirTokens.tapTarget,
        height: SeyirTokens.tapTarget,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SeyirTokens.brand,
              borderRadius: SeyirTokens.radiusSmAll,
            ),
            child: Text(
              'W',
              style: palette.headline(color: ink),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactHeader(SeyirPalette palette, VoidCallback toggle) {
    final ButtonStyle iconStyle = _compactIconStyle(palette);
    return Row(
      children: [
        _brandMark(palette),
        IconButton(
          icon: const Icon(Icons.search, size: 22),
          onPressed: () {},
          style: iconStyle,
        ),
        IconButton(
          icon: Icon(MdiIcons.chatOutline, size: 22),
          style: iconStyle,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(userEmail: widget.userEmail),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(MdiIcons.menuOpen, size: 22),
          style: iconStyle,
          onPressed: toggle,
        ),
        Expanded(
          child: Text(
            'Seyir Defteri',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.title(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 22),
          onPressed: _toggleHeader,
          style: iconStyle,
          tooltip: 'Arayüzü Aç',
        ),
      ],
    );
  }

  Widget _expandedHeader(Widget menuButton) {
    return Column(
      children: [
        ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
        Padding(
          padding: kSeyirFriendRowPadding,
          child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
        ),
        Padding(
          padding: kSeyirProfilePadding,
          child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
            userEmail: widget.profileEmail,
            targetUserEmail: widget.targetUserEmail,
            onShowSavedDavalar: () {
              if (widget.userEmail != null) {
                showSavedDavalarDialog(context, widget.userEmail!);
              }
            },
          ),
        ),
        Padding(
          padding: kSeyirHeadlinePadding,
          child: dava_ac.TreeMenuPageheadlines(
            title: 'Seyir Defteri',
            isCollapsed: isHeaderCollapsed,
            onToggleCollapse: _toggleHeader,
            menuButton: menuButton,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return SafeArea(
      child: NotificationListener<ScrollNotification>(
        onNotification: _onFeedScroll,
        child: AppExpandableIconMenu.seyirDefteri(
          items: buildSeyirDefteriMenuItems(
            context,
            userEmail: widget.userEmail,
          ),
          headerBuilder: (
            BuildContext context,
            Widget menuButton,
            VoidCallback toggle,
            bool isOpen,
          ) {
            return AnimatedSize(
              duration: SeyirTokens.motion,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isHeaderCollapsed
                  ? _compactHeader(palette, toggle)
                  : _expandedHeader(menuButton),
            );
          },
          body: widget.feed,
        ),
      ),
    );
  }
}
