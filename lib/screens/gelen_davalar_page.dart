import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/seyir_defteri_menu_items.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import '../widgets/gelen_dava_card.dart';
import '../services/hive_database_service.dart';
import '../services/dava_timer_service.dart';
import 'gelen_davalar_kactane.dart';
import '../providers/dava_provider.dart';
import '../theme/seyir_tokens.dart';

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
        child: AppExpandableIconMenu.seyirDefteri(
          items: buildSeyirDefteriMenuItems(
            context,
            userEmail: widget.userEmail,
          ),
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
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
                    userEmail: widget.userEmail,
                    onShowSavedDavalar: () {},
                  ),
                ),
                GelenDavalarHeadlineRow(menuButton: menuButton),
              ],
            );
          },
          body: _davaList.isEmpty
              ? const _GelenEmptyState()
              : ListView.builder(
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
  final Widget menuButton;

  const GelenDavalarHeadlineRow({
    super.key,
    required this.menuButton,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: kSeyirHeadlinePadding,
      child: Row(
        children: [
          menuButton,
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gelen Davalar',
                    style: palette.headline(weight: FontWeight.w600),
                  ),
                  const SizedBox(width: 7),
                  const _IncomingDavaCountBadge(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GelenEmptyState extends StatelessWidget {
  const _GelenEmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(SeyirTokens.space6),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: palette.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Gelen dava yok',
            style: palette.title(
              weight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size atanan davalar burada görünür',
            textAlign: TextAlign.center,
            style: palette.body(
              weight: FontWeight.w400,
              color: palette.textMuted,
            ),
          ),
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
    final palette = SeyirPalette.of(context);
    return Tooltip(
      message: 'Gelen dava özeti',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const GelenDavalarKactanePage(),
              ),
            );
          },
          child: SizedBox(
            width: SeyirTokens.tapTarget,
            height: SeyirTokens.tapTarget,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    MdiIcons.briefcaseArrowLeftRightOutline,
                    size: 26,
                    color: palette.textSecondary,
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
                            color: SeyirTokens.brand,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: palette.shadow,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: TextStyle(
                              color: palette.onSolid(SeyirTokens.brand),
                              fontSize: SeyirTokens.typeCaption,
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
      ),
    );
  }
}
