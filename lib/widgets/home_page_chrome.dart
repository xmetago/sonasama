import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../theme/seyir_tokens.dart';
import '../utils/dialog_utils.dart';
import 'seyir_defteri_menu_items.dart';
import 'shared/app_expandable_icon_menu.dart';
import 'shared/app_page_header.dart';

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

  @override
  Widget build(BuildContext context) {
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
              child: AppPageHeader(
                title: 'Seyir Defteri',
                userEmail: widget.userEmail,
                profileEmail: widget.profileEmail,
                targetUserEmail: widget.targetUserEmail,
                isCollapsed: isHeaderCollapsed,
                onToggleCollapse: _toggleHeader,
                menuButton: menuButton,
                onToggleMenu: toggle,
                onShowSavedDavalar: () {
                  if (widget.userEmail != null) {
                    showSavedDavalarDialog(context, widget.userEmail!);
                  }
                },
              ),
            );
          },
          body: widget.feed,
        ),
      ),
    );
  }
}
