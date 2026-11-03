import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../utils/dialog_utils.dart';
import 'common_header_widgets.dart';
import '../screens/actigim_davalar_page.dart';
import '../screens/chat_page.dart';
import '../screens/davaci_unlulur_page.dart';
import '../screens/dava_ac_page.dart' as dava_ac;
import '../screens/gelen_davalar_page.dart';
import '../screens/haykirislarim_page.dart';
import '../screens/hesap_gizlilik_ayarlari_page.dart';
import '../screens/home_page.dart';
import '../screens/katildigim_davalar_page.dart' as katildigim_page;
import '../screens/saved_haykirlar_page.dart';
import '../screens/statistics_dashboard_page.dart';
import '../screens/trend_insights_page.dart';
import '../screens/yargila_page.dart';

/// Üst şerit ve sol menü. Katlanma, menü ve gelen-dava yanıp sönmesi burada kalır.
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
  bool showLeftIcons =
      false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
  bool isHeaderCollapsed =
      false; // Üst arayüzün küçültülüp küçültülmediğini kontrol eder
  bool _highlightIncomingIcon = false; // Gelen davalar ikonu için yanıp sönme efekti
  bool _hasIncomingDavaForBlink = false; // Yanıp sönme gerektiren gelen dava var mı?
  Timer? _incomingIconBlinkTimer; // Gelen davalar ikonunun blink timer'ı

  @override
  void dispose() {
    _incomingIconBlinkTimer?.cancel();
    super.dispose();
  }

  /// Gelen dava varlığını baz alarak sol menü ikonunda yanıp sönmeyi yönetir.
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
    return SafeArea(
            child: Column(
              children: [
                // Üst Arayüz Bölümü - Ok kapalıyken tek satır halinde küçülür
                AnimatedContainer(
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
                                onTap: () {
                                  setState(() {
                                    showLeftIcons = !showLeftIcons;
                                  });
                                },
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: OneFriendPhoneBellMenu(
                                  userEmail: widget.userEmail),
                            ),
                            // ROW 3: Profil Bölümü - Adım 3: Padding optimize edildi
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 4.0),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              child: dava_ac.TreeMenuPageheadlines(
                                title:
                                    " || SEYİR DEFTERİ ||", // HomePage için özel başlık
                                isCollapsed: isHeaderCollapsed,
                                onToggleCollapse: () {
                                  setState(() {
                                    isHeaderCollapsed = !isHeaderCollapsed;
                                  });
                                },
                                onMenuPressed: () {
                                  setState(() {
                                    showLeftIcons = !showLeftIcons;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                ),
                // ROW 5: 6 Icon Solda, Sağda Text Yazma Alanı (Scrollable with ListTile)
                Expanded(
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
                                    // Adım 5: Sol menü ikonlarının padding'leri optimize edildi
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  GelenDavalarPage(
                                                      userEmail:
                                                          widget.userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 8.0, 8.0, 8.0),
                                        child: Consumer<DavaProvider>(
                                          builder: (context, davaProvider, child) {
                                            final shouldBlink =
                                                davaProvider.incomingDavaCount > 0;
                                            if (_hasIncomingDavaForBlink !=
                                                shouldBlink) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                if (!mounted) return;
                                                _updateIncomingIconBlinkState(
                                                    shouldBlink);
                                              });
                                            }

                                            return AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: _highlightIncomingIcon ||
                                                        _hasIncomingDavaForBlink
                                                    ? Colors.blue.withOpacity(0.08)
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _highlightIncomingIcon ||
                                                          _hasIncomingDavaForBlink
                                                      ? Colors.blueAccent
                                                      : Colors.transparent,
                                                  width: _highlightIncomingIcon
                                                      ? 3
                                                      : (_hasIncomingDavaForBlink
                                                          ? 1.5
                                                          : 0),
                                                ),
                                                boxShadow: _highlightIncomingIcon
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.blue
                                                              .withOpacity(0.45),
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
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => YargilaPage(
                                                  userEmail: widget.userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_yargila_left_row_icon.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  katildigim_page
                                                      .KatildigimDavalarPage(
                                                          userEmail: widget
                                                              .userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_katildigim_davalar_icon.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ActigimDavalarPage(
                                                      userEmail:
                                                          widget.userEmail)),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_actigim_davalar_icon.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DavaciUnlulurPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                HaykirislarimPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Image.asset(
                                            'lib/icons/06_left_row_haykirislarim.png',
                                            width: 24,
                                            height: 24),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TrendInsightsPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.trendingUp,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SavedHaykirlarPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.bookmarkMultipleOutline,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StatisticsDashboardPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.chartBar,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                HesapGizlilikAyarlariPage(
                                                    userEmail:
                                                        widget.userEmail),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.cog,
                                          size: 24,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final shouldLogout =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              title: const Text(
                                                  'Uygulamadan Çıkış'),
                                              content: const Text(
                                                  'Çıkış yapmak istediğinize emin misiniz?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                          dialogContext)
                                                      .pop(false),
                                                  child: const Text('İptal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(
                                                          dialogContext)
                                                      .pop(true),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  child: const Text('Çıkış'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (shouldLogout != true) return;

                                        Provider.of<AuthProvider>(context,
                                                listen: false)
                                            .logout();

                                        if (!context.mounted) return;
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                                '/login', (route) => false);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 48.0, 8.0, 8.0),
                                        child: Icon(
                                          MdiIcons.logout,
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
                      Expanded(
                        child: Column(
                          children: [
                            // Home feed içerikleri
                            Expanded(
                              child: widget.feed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
