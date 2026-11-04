import 'package:flutter/material.dart';
import 'dart:async';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import '../widgets/gelen_dava_card.dart';
import 'yargila_page.dart' hide Dava, FiveCardCaseInformation, DashedLinePainter;
import 'actigim_davalar_page.dart' hide Dava, FiveCardCaseInformation;
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import 'haykir_page.dart' hide FiveCardCaseInformation;
import '../services/hive_database_service.dart';
import '../services/dava_timer_service.dart';
import 'gelen_davalar_kactane.dart';
import 'friendship_management_page.dart';
import '../providers/dava_provider.dart';

export '../widgets/gelen_dava_card.dart' show Dava, FiveCardCaseInformation, DashedLinePainter;

class GelenDavalarPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const GelenDavalarPage({super.key, this.userEmail});

  @override
  State<GelenDavalarPage> createState() => _GelenDavalarPageState();
}

class _GelenDavalarPageState extends State<GelenDavalarPage> {
  int? expandedCardIndex; // Hangi card'ın açık olduğunu kontrol eder
  List<Dava> _davaList = [];
  StreamSubscription? _incomingSub;
  DavaProvider? _davaProvider; // Provider referansını sakla

  @override
  void initState() {
    super.initState();
    _initializeProviders();

    // Geçici LOG: testyargic1'in incoming kayıtlarını konsola yazdır
    Future.microtask(() {
      HiveDatabaseService.debugPrintIncomingFor('testyargic1@gmail.com');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider referansını güvenli bir şekilde al
    _davaProvider ??= Provider.of<DavaProvider>(context, listen: false);
  }

  /// Provider'ları başlat ve verileri yükle
  void _initializeProviders() async {
    _davaProvider ??= Provider.of<DavaProvider>(context, listen: false);
    
    // Kullanıcı verilerini yükle
    if (widget.userEmail != null && _davaProvider != null) {
      await _davaProvider!.loadUserData(widget.userEmail!);
      
      // Canlı izlemeyi başlat
      _davaProvider!.startWatchingIncoming(widget.userEmail!);
    }
    
    // Eski veri yükleme metodunu çağır (geçiş için)
    _loadIncomingDavalar();
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    // Provider'dan canlı izlemeyi durdur (mounted kontrolü ile)
    if (mounted && _davaProvider != null) {
      _davaProvider!.stopWatchingIncoming();
    }
    super.dispose();
  }

  void _loadIncomingDavalar() {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      setState(() {
        _davaList = [];
      });
      return;
    }
    final incoming = HiveDatabaseService.getIncomingDavalar(widget.userEmail!);
    setState(() {
      _davaList = incoming.map((m) {
        // Güvenli tip dönüşümü
        final safeMap = <String, dynamic>{};
        m.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        
        // Tarih alanlarını parse et
        DateTime? createdAt;
        DateTime? acceptedAt;
        
        try {
          if (safeMap['createdAt'] != null) {
            createdAt = DateTime.parse(safeMap['createdAt'].toString());
          }
        } catch (e) {
          createdAt = null;
        }
        
        try {
          if (safeMap['acceptedAt'] != null) {
            acceptedAt = DateTime.parse(safeMap['acceptedAt'].toString());
          }
        } catch (e) {
          acceptedAt = null;
        }
        
        final davaliRaw = (safeMap['davali'] ?? '').toString();
        final davaliEmailRaw = (safeMap['davaliEmail'] ?? '').toString().trim();
        return Dava(
          id: (safeMap['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
          adi: (safeMap['adi'] ?? safeMap['davaAdi'] ?? '').toString(),
          davali: davaliRaw,
          mevkii: (safeMap['mevkii'] ?? '').toString(),
          kalanSure: (safeMap['kalanSure'] ?? '.../.../.....').toString(),
          profilResmi: (safeMap['profilResmi'] ?? 'lib/icons/03_davala_ana_icon.png').toString(),
          davaKonusu: (safeMap['davaKonusu'] ?? safeMap['adi'] ?? safeMap['davaAdi'] ?? '').toString(),
          davaci: (safeMap['davaci'] ?? '').toString(), // Davacı verisi eklendi
          createdAt: createdAt,
          acceptedAt: acceptedAt,
          lifecycleStatus: (safeMap['lifecycleStatus'] ?? DavaLifecycleStatuses.awaitingRole)
              .toString(),
          davaliEmail: davaliEmailRaw.isNotEmpty
              ? davaliEmailRaw
              : (davaliRaw.contains('@') ? davaliRaw : null),
          isAppealJudgeAssignment: safeMap['isAppealJudgeAssignment'] == true,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppExpandableIconMenu(
          expandBody: true,
          toggleTooltip: 'Sol menü',
          panelWidth: 56,
          curve: Curves.easeOutCubic,
          openGap: 10,
          panelPadding: const EdgeInsets.symmetric(vertical: 10),
          inset: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          openPanelDecoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E4EA)),
          ),
          items: [
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: GelenDavalarLeftNavColumn(userEmail: widget.userEmail),
            ),
          ],
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
            return Column(
              mainAxisSize: MainAxisSize.min,
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
                onShowSavedDavalar: () {
                },
              ),
            ),
            GelenDavalarHeadlineRow(
              onMenuPressed: toggle,
              menuButton: menuButton,
            ),
              ],
            );
          },
          body: ListView.builder(
                        itemCount: _davaList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: FiveCardCaseInformation(
                              dava: _davaList[index],
                              isExpanded: expandedCardIndex == index,
                              userEmail: widget.userEmail,
                              onTap: () {
                                setState(() {
                                  if (expandedCardIndex == index) {
                                    expandedCardIndex = null;
                                  } else {
                                    expandedCardIndex = index;
                                  }
                                });
                              },
                              onDavaRejected: () {
                                // Dava listeden kaldırıldığında UI'ı güncelle
                                setState(() {
                                  _davaList.removeAt(index);
                                  if (expandedCardIndex == index) {
                                    expandedCardIndex = null;
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
        ),
      ),
    );
  }
}

/// Menü, sayfa başlığı ve gelen dava sayısı rozetini tek satırda hizalar.
class GelenDavalarHeadlineRow extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final Widget? menuButton;

  const GelenDavalarHeadlineRow({
    super.key,
    required this.onMenuPressed,
    this.menuButton,
  });

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Color(0xFF2F3E35),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          menuButton ??
              IconButton(
                icon: Icon(MdiIcons.menuOpen, size: 34, color: Colors.red),
                onPressed: onMenuPressed,
                tooltip: 'Sol menü',
              ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text('|| GELEN DAVALAR ||', style: _titleStyle),
                const SizedBox(width: 7),
                const _IncomingDavaCountBadge(),
              ],
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

/// Özet sayfasına giden, sayı rozeti taşıyan ikon.
class _IncomingDavaCountBadge extends StatelessWidget {
  const _IncomingDavaCountBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Gelen dava özeti',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const GelenDavalarKactanePage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  MdiIcons.briefcaseArrowLeftRightOutline,
                  size: 26,
                  color: Colors.black54,
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Consumer<DavaProvider>(
                    builder: (context, davaProvider, child) {
                      final count = davaProvider.incomingDavaCount;
                      if (count <= 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3949AB),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gelen davalar sayfası sol şerit navigasyonu.
class GelenDavalarLeftNavColumn extends StatelessWidget {
  final String? userEmail;

  const GelenDavalarLeftNavColumn({super.key, this.userEmail});

  static const double _iconSize = 24;
  static const Color _iconColor = Colors.black54;

  Widget _navItem({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onTap,
    double top = 0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, top, 8, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: icon,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _navItem(
          context: context,
          top: 4,
          icon: Icon(MdiIcons.briefcaseArrowLeftRight, size: _iconSize, color: const Color(0xFF5C6BC0)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => GelenDavalarPage(userEmail: userEmail),
              ),
            );
          },
        ),
        _navItem(
          context: context,
          icon: Icon(MdiIcons.gavel, size: _iconSize, color: _iconColor),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => YargilaPage(userEmail: userEmail),
              ),
            );
          },
        ),
        _navItem(
          context: context,
          icon: Icon(MdiIcons.accountHeart, size: _iconSize, color: _iconColor),
          onTap: () {
            if (userEmail != null) {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => FriendshipManagementPage(userEmail: userEmail!),
                ),
              );
            }
          },
        ),
        _navItem(
          context: context,
          icon: Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: _iconSize, height: _iconSize),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => ActigimDavalarPage(userEmail: userEmail),
              ),
            );
          },
        ),
        _navItem(
          context: context,
          icon: Image.asset('lib/icons/06_left_row_unlulerin_actigi_davalar_iconu.png', width: _iconSize, height: _iconSize),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => DavaciUnlulurPage(userEmail: userEmail),
              ),
            );
          },
        ),
        _navItem(
          context: context,
          icon: Image.asset('lib/icons/06_left_row_haykirislarim.png', width: _iconSize, height: _iconSize),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => HaykirPage(userEmail: userEmail),
              ),
            );
          },
        ),
        _navItem(
          context: context,
          icon: Icon(MdiIcons.trendingUp, size: _iconSize, color: _iconColor),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => TrendInsightsPage(userEmail: userEmail),
              ),
            );
          },
        ),
      ],
    );
  }
}
