import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../utils/dialog_utils.dart';
import 'common_header_widgets.dart';
import 'seyir_defteri_menu_items.dart';
import 'shared/app_expandable_icon_menu.dart';
import '../screens/chat_page.dart';
import '../screens/dava_ac_page.dart' as dava_ac;
import '../screens/home_page.dart';

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
  bool isHeaderCollapsed =
      false; // Üst arayüzün küçültülüp küçültülmediğini kontrol eder

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppExpandableIconMenu.seyirDefteri(
        items: buildSeyirDefteriMenuItems(
          context,
          userEmail: widget.userEmail,
        ),
        headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
          return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isHeaderCollapsed ? 40 : null,
                  child: isHeaderCollapsed
                      ? // Tek satır halinde küçültülmüş görünüm - Kompakt UI
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Kompakt WhoBoom logosu
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HomePage(userEmail: widget.userEmail),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF059669), Colors.green],
                                    ),
                                  ),
                                  child: const Text(
                                    'WB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Kompakt arama ikonu
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.search, size: 16),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 4),
                              // Kompakt chat ikonu
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatPage(userEmail: widget.userEmail),
                                    ),
                                  );
                                },
                                child: Icon(
                                  MdiIcons.chatOutline,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Kompakt menü ikonu
                              GestureDetector(
                                onTap: toggle,
                                child: Icon(
                                  MdiIcons.menuOpen,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Kompakt başlık
                              const Expanded(
                                child: Text(
                                  'SEYİR DEFTERİ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Aç/kapa ok butonu
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
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
                      : // Normal görünüm
                      Column(
                          children: [
                            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu - Adım 1: Padding azaltıldı
                            ZeroWhoboomSearchMessage(
                                userEmail: widget.userEmail),
                            // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu - Adım 2: Vertical padding azaltıldı
                            Padding(
                              padding: kSeyirFriendRowPadding,
                              child: OneFriendPhoneBellMenu(
                                  userEmail: widget.userEmail),
                            ),
                            // ROW 3: Profil Bölümü - Adım 3: Padding optimize edildi
                            Padding(
                              padding: kSeyirProfilePadding,
                              child:
                                  SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                                userEmail:
                                    widget.profileEmail,
                                targetUserEmail:
                                    widget.targetUserEmail,
                                onShowSavedDavalar: () {
                                  // Global utility fonksiyonunu kullan
                                  if (widget.userEmail != null) {
                                    showSavedDavalarDialog(
                                        context, widget.userEmail!);
                                  }
                                },
                              ),
                            ),
                            // ROW 4: Hamburger Iconu, Seyir Defteri Başlığı - Adım 4: Padding azaltıldı
                            Padding(
                              padding: kSeyirHeadlinePadding,
                              child: dava_ac.TreeMenuPageheadlines(
                                title:
                                    " || SEYİR DEFTERİ ||", // HomePage için özel başlık
                                isCollapsed: isHeaderCollapsed,
                                onToggleCollapse: () {
                                  setState(() {
                                    isHeaderCollapsed = !isHeaderCollapsed;
                                  });
                                },
                                menuButton: menuButton,
                              ),
                            ),
                          ],
                        ),
                );
        },
        body: widget.feed,
      ),
    );
  }
}
