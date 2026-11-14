import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../../screens/chat_page.dart';
import '../../screens/home_page.dart';
import '../../theme/seyir_tokens.dart';
import '../common_header_widgets.dart';
import '../dava_ac_page_headline.dart';
import '../seyir_defteri_menu_items.dart';

/// Ana sayfa ve Dava Aç'ın ortak üst şeridi.
///
/// Açık halde dört satır, kaydırınca 44px ikonlu kompakt satır.
/// Katlanma durumu sayfada kalır; bu widget yalnızca çizer.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    required this.userEmail,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.menuButton,
    required this.onToggleMenu,
    this.profileEmail,
    this.targetUserEmail,
    this.onShowSavedDavalar,
    this.onDateUpdate,
  });

  final String title;
  final String? userEmail;
  final String? profileEmail;
  final String? targetUserEmail;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Widget menuButton;
  final VoidCallback onToggleMenu;
  final VoidCallback? onShowSavedDavalar;
  final void Function(String date)? onDateUpdate;

  ButtonStyle _compactIconStyle(SeyirPalette palette) {
    return IconButton.styleFrom(
      foregroundColor: palette.textSecondary,
      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      fixedSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
  }

  Widget _brandMark(BuildContext context, SeyirPalette palette) {
    final Color ink = palette.onSolid(SeyirTokens.brand);
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userEmail: userEmail),
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

  Widget _compactHeader(BuildContext context, SeyirPalette palette) {
    final ButtonStyle iconStyle = _compactIconStyle(palette);
    return Row(
      children: [
        _brandMark(context, palette),
        IconButton(
          icon: const Icon(Icons.search, size: 22),
          onPressed: () {},
          style: iconStyle,
        ),
        IconButton(
          icon: const Icon(MdiIcons.chatOutline, size: 22),
          style: iconStyle,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(userEmail: userEmail),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(MdiIcons.menuOpen, size: 22),
          style: iconStyle,
          onPressed: onToggleMenu,
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.title(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 22),
          onPressed: onToggleCollapse,
          style: iconStyle,
          tooltip: 'Arayüzü Aç',
        ),
      ],
    );
  }

  Widget _expandedHeader(SeyirPalette palette) {
    return Column(
      children: [
        ZeroWhoboomSearchMessage(userEmail: userEmail),
        Padding(
          padding: kSeyirFriendRowPadding,
          child: OneFriendPhoneBellMenu(userEmail: userEmail),
        ),
        Padding(
          padding: kSeyirProfilePadding,
          child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
            userEmail: profileEmail,
            targetUserEmail: targetUserEmail,
            onDateUpdate: onDateUpdate,
            onShowSavedDavalar: onShowSavedDavalar,
          ),
        ),
        Padding(
          padding: kSeyirHeadlinePadding,
          child: TreeMenuPageheadlines(
            title: title,
            isCollapsed: isCollapsed,
            onToggleCollapse: onToggleCollapse,
            menuButton: menuButton,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return isCollapsed
        ? _compactHeader(context, palette)
        : _expandedHeader(palette);
  }
}
