import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/common_header_widgets.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import 'gelen_davalar_page.dart' hide FiveCardCaseInformation;
import 'yargila_page.dart' hide Dava, FiveCardCaseInformation;
import 'actigim_davalar_page.dart' hide Dava, FiveCardCaseInformation;
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import 'haykirislarim_page.dart';
import '../services/hive_database_service.dart';
import '../services/katildigim_dava_istatistik_service.dart';
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../widgets/katildigim_dava_sayilari_section.dart';
import '../widgets/ilgililerin_seyir_defteri_widgeti.dart';
export '../widgets/katildigim_case_card.dart' show FiveCardCaseInformation;

class Dava {
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  const Dava({
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
  });
}



class KatildigimDavalarPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final bool initiallyCollapsed;

  const KatildigimDavalarPage({
    super.key,
    this.userEmail,
    this.initiallyCollapsed = false,
  });

  @override
  State<KatildigimDavalarPage> createState() => _KatildigimDavalarPageState();
}

class _KatildigimDavalarPageState extends State<KatildigimDavalarPage> {
  List<Map<String, dynamic>> _katildigimDavalar = []; // Gerçek veriler için
  final Map<String, bool> _seyirDefteriCollapsedByDavaId = <String, bool>{};
  int _lastSyncedProviderKatildigimLen = 0;
  late bool isHeaderCollapsed;

  int _lastHukumUpdateVersion = -1;
  DateTime? _lastListRefreshTime;
  static const Duration _listRefreshCooldown = Duration(seconds: 2);

  // İstatistikler
  int _katildigimSayisi = 0;
  int _hakliOldugumSayisi = 0;
  int _haksizOldugumSayisi = 0;
  int _banaAcilanSayisi = 0;

  @override
  void initState() {
    super.initState();
    isHeaderCollapsed = widget.initiallyCollapsed;
    _loadKatildigimDavalar();
    _calculateStatistics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        _lastHukumUpdateVersion = davaProvider.hukumUpdateVersion;
      } catch (_) {}
    });
  }

  Future<void> _purgeAndReloadKatildigimFromHive() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return;
    await HiveDatabaseService.purgeLegacyKatildigimTestRows(widget.userEmail!);
    if (!mounted) return;
    final davalar =
        await HiveDatabaseService.getSekizRolKatilimKayitlari(widget.userEmail!);
    davalar.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime? aDate = DateTime.tryParse(
        (a['openedAt'] ?? a['createdAt'] ?? '').toString(),
      );
      final DateTime? bDate = DateTime.tryParse(
        (b['openedAt'] ?? b['createdAt'] ?? '').toString(),
      );
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    setState(() {
      _katildigimDavalar = davalar;
    });
    print('✅ Katıldığım davalar yüklendi (8 rol): ${davalar.length} dava');
    unawaited(_calculateStatistics());
  }

  Widget _buildKatildigimSeyirDefteriCard(Map<String, dynamic> davaData) {
    final String davaId =
        (davaData['id'] ?? davaData['davaId'] ?? '').toString().trim();
    final String? openedAtRaw =
        (davaData['openedAt'] ?? davaData['createdAt'])?.toString();
    DateTime? openedAt;
    if (openedAtRaw != null && openedAtRaw.isNotEmpty) {
      openedAt = DateTime.tryParse(openedAtRaw);
    }
    final bool collapsed = _seyirDefteriCollapsedByDavaId[davaId] ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: IlgililerinSeyirDefteriWidgeti(
          davaId: davaId.isEmpty ? null : davaId,
          userEmail: widget.userEmail,
          davaAdi: (davaData['adi'] ?? davaData['davaAdi'])?.toString(),
          davaci: davaData['davaci']?.toString(),
          davali: davaData['davali']?.toString(),
          kategori: davaData['kategori']?.toString(),
          davaKonusu: davaData['davaKonusu']?.toString(),
          openedAt: openedAt,
          kullaniciGorev:
              (davaData['mevkii'] ?? davaData['userRole'])?.toString(),
          collapsed: collapsed,
          onToggleCollapse: davaId.isEmpty
              ? null
              : () {
                  setState(() {
                    _seyirDefteriCollapsedByDavaId[davaId] = !collapsed;
                  });
                },
          onClose: () {},
        ),
      ),
    );
  }

  /// Hive'dan listeyi yeniler.
  void _reloadKatildigimDavalarFromHive() {
    unawaited(_purgeAndReloadKatildigimFromHive());
  }

  /// Katıldığım davaları yükle
  void _loadKatildigimDavalar() {
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      unawaited(_purgeAndReloadKatildigimFromHive());
    }
  }

  static const KatildigimDavaIstatistikService _istatistikService =
      KatildigimDavaIstatistikService();

  /// İstatistikleri Hive katılım / hüküm / davalı kayıtlarından hesaplar.
  Future<void> _calculateStatistics() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return;
    }

    try {
      final stats = await _istatistikService.compute(widget.userEmail!);
      if (!mounted) return;
      setState(() {
        _katildigimSayisi = stats.katildigim;
        _hakliOldugumSayisi = stats.hakliOldugum;
        _haksizOldugumSayisi = stats.haksizOldugum;
        _banaAcilanSayisi = stats.banaAcilan;
      });
    } catch (e) {
      print('❌ İstatistik hesaplama hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DavaProvider>(
      builder: (context, authProvider, davaProvider, child) {
        if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
          final int providerLen = davaProvider.katildigimDavalar.length;
          if (providerLen > 0 && providerLen != _lastSyncedProviderKatildigimLen) {
            _lastSyncedProviderKatildigimLen = providerLen;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _reloadKatildigimDavalarFromHive();
              }
            });
          }
        }

        final int currentVersion = davaProvider.hukumUpdateVersion;
        if (_lastHukumUpdateVersion != currentVersion) {
          final DateTime now = DateTime.now();
          if (_lastListRefreshTime == null ||
              now.difference(_lastListRefreshTime!) >= _listRefreshCooldown) {
            _lastHukumUpdateVersion = currentVersion;
            _lastListRefreshTime = now;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _reloadKatildigimDavalarFromHive();
              }
            });
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: AppExpandableIconMenu(
                toggleTooltip: 'Sol menü',
                bodyPadding: const EdgeInsets.all(8),
                items: _katildigimMenuItems(),
                headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isHeaderCollapsed ? 40 : null,
                    child: isHeaderCollapsed
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            child: Row(
                              children: <Widget>[
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    MdiIcons.menuOpen,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                  onPressed: toggle,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    '|| KATILDIĞIM DAVALAR ||',
                                    style: TextStyle(
                                      fontSize: 10,
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
                            children: <Widget>[
                              ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                                  userEmail: widget.userEmail,
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
                                showSavedDavalarIcon: false,
                                headlineText: 'KATILDIĞIM DAVALAR',
                                headlineAssetPath: 'lib/icons/06_left_row_katildigim_davalar_icon.png',
                                headlineDavaCount: _katildigimDavalar.length,
                              ),
                            ],
                          ),
                  );
                },
                body: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: KatildigimDavaSayilariSection(
                                  katildigim: _katildigimSayisi,
                                  hakli: _hakliOldugumSayisi,
                                  haksiz: _haksizOldugumSayisi,
                                  banaAcilan: _banaAcilanSayisi,
                                ),
                              ),
                              if (_katildigimDavalar.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.folder_open,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Henüz rol ile katıldığınız dava yok',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Jüri, yargıç, temyiz hakimi, şahit veya avukat olarak kabul ettiğiniz davalar burada görünür',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _katildigimDavalar.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final Map<String, dynamic> davaData =
                                        _katildigimDavalar[index];
                                    return _buildKatildigimSeyirDefteriCard(davaData);
                                  },
                                ),
                            ],
                          ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<AppExpandableIconMenuItem> _katildigimMenuItems() {
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
        assetIcon: 'lib/icons/06_left_row_actigim_davalar_icon.png',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ActigimDavalarPage(userEmail: widget.userEmail)),
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
