import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/common_header_widgets.dart';
import 'gelen_davalar_page.dart';
import 'yargila_page.dart';
import 'actigim_davalar_page.dart' hide Dava;
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import 'haykirislarim_page.dart';
import 'sekiz_hukum_page.dart';
import '../models/sekiz_hukum_arguments.dart';
import '../services/hive_database_service.dart';
import '../services/verified_users_service.dart';
import '../services/ceza_consensus_service.dart';
import '../services/hediye_consensus_service.dart';
import '../services/dava_consensus_service.dart';
import '../services/masraf_onay_service.dart';
import '../widgets/masraf_onay_panel.dart';
import '../services/dava_hukum_service.dart';
import '../services/katildigim_dava_istatistik_service.dart';
import '../models/hukum_sentiment.dart';
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../widgets/katildigim_dava_sayilari_section.dart';
import '../widgets/rol_hukum_kartlari_section.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/ilgililerin_seyir_defteri_widgeti.dart';
import '../widgets/expandable_comment_text.dart';

Map<String, Map<String, dynamic>> _mergeKatildigimHukumlerGroupedMaps(
  List<Map<String, Map<String, dynamic>>> parts,
) {
  final Map<String, Map<String, dynamic>> out = <String, Map<String, dynamic>>{};
  for (final Map<String, Map<String, dynamic>> part in parts) {
    for (final MapEntry<String, Map<String, dynamic>> e in part.entries) {
      final String roleFromRow =
          (e.value['userRole'] as String?)?.trim().isNotEmpty == true
              ? (e.value['userRole'] as String)
              : e.key;
      final String nk = normalizeRolKarari(roleFromRow);
      final String newText = (e.value['hukumText'] as String?)?.trim() ?? '';
      final Map<String, dynamic>? prev = out[nk];
      final String oldText = (prev?['hukumText'] as String?)?.trim() ?? '';
      if (prev == null) {
        out[nk] = Map<String, dynamic>.from(e.value)..['userRole'] = nk;
      } else if (newText.isNotEmpty &&
          (oldText.isEmpty || newText.length > oldText.length)) {
        out[nk] = Map<String, dynamic>.from(e.value)..['userRole'] = nk;
      }
    }
  }
  return out;
}

// Model for a case row
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
  bool showLeftIcons = false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
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
              child: Column(
                children: <Widget>[
                  AnimatedContainer(
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
                                  onPressed: () {
                                    setState(() {
                                      showLeftIcons = !showLeftIcons;
                                    });
                                  },
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
                                showSavedDavalarIcon: false,
                                headlineText: 'KATILDIĞIM DAVALAR',
                                headlineAssetPath: 'lib/icons/06_left_row_katildigim_davalar_icon.png',
                                headlineDavaCount: _katildigimDavalar.length,
                              ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: showLeftIcons ? 60 : 0,
                          child: showLeftIcons
                              ? SingleChildScrollView(
                                  child: Column(
                                    children: <Widget>[
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => GelenDavalarPage(userEmail: widget.userEmail),
                                            ),
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
                                            MaterialPageRoute(
                                              builder: (context) => YargilaPage(userEmail: widget.userEmail),
                                            ),
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
                                            MaterialPageRoute(
                                              builder: (context) => KatildigimDavalarPage(userEmail: widget.userEmail),
                                            ),
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
                                              builder: (context) => ActigimDavalarPage(userEmail: widget.userEmail),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                                          child: Image.asset('lib/icons/06_left_row_actigim_davalar_icon.png', width: 24, height: 24),
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
                        Expanded(
                          child: Column(
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FiveCardCaseInformation extends StatefulWidget {
  final Map<String, dynamic> davaData;
  final String? userEmail;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final bool isSeyirDefteri; // Seyir defterinde kullanılıyor mu?
  final VoidCallback? onDelete; // Silme callback'i (seyir defteri için)
  
  const FiveCardCaseInformation({
    super.key, 
    required this.davaData, 
    this.userEmail,
    this.onTap,
    this.onRefresh,
    this.isSeyirDefteri = false,
    this.onDelete,
  });

  @override
  State<FiveCardCaseInformation> createState() => _FiveCardCaseInformationState();
}

class _FiveCardCaseInformationState extends State<FiveCardCaseInformation>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool isExpanded = false;
  bool _kunyeExpanded = false;
  Timer? _countdownTimer;
  Duration? _remainingTime;
  DavaConsensusEvaluation? _consensusEvaluation;
  bool _isLoadingConsensus = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Ceza ve Masraf butonları için animasyon controller'ları
  AnimationController? _cezaPulseController;
  AnimationController? _masrafPulseController;
  AnimationController? _cezaGlowController;
  AnimationController? _masrafGlowController;
  Animation<double>? _cezaPulseAnimation;
  Animation<double>? _masrafPulseAnimation;
  Animation<double>? _cezaGlowAnimation;
  Animation<double>? _masrafGlowAnimation;
  
  // Rol bazlı hüküm kayıtları
  final Map<String, String> _rolHukumleri = <String, String>{};
  final Map<String, HukumSentiment> _rolSentimentleri = <String, HukumSentiment>{};
  final Map<String, bool> _rolFinalizasyonlari = <String, bool>{};
  final Map<String, String> _rolUserEmails = <String, String>{};
  final Map<String, String> _rolCreatedAts = <String, String>{};
  
  // Ceza ve masraf bilgileri
  String? _yargicCezaText;
  String? _effectiveCezaKaynak;
  List<String>? _hediyeOnayList;
  String? _effectiveHediyeKaynak;
  List<String>? _yargicMasraflar;
  bool _cezaOnaylandi = false;
  bool _masrafOnaylandi = false;
  bool _cezaIconPressed = false;
  
  // Performans optimizasyonu
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 2);
  
  // Provider senkronizasyonu
  int _lastHukumUpdateVersion = -1;

  final Map<String, String> _rolCezalari = <String, String>{};
  final Map<String, String> _rolMasraflari = <String, String>{};
  HukumSentiment? _selectedSentiment;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    // Ceza butonu için pulse animasyonu
    _cezaPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _cezaPulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _cezaPulseController!, curve: Curves.easeInOut),
    );
    
    // Ceza butonu için glow animasyonu
    _cezaGlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _cezaGlowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _cezaGlowController!, curve: Curves.easeInOut),
    );
    
    // Masraf butonu için pulse animasyonu
    _masrafPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _masrafPulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _masrafPulseController!, curve: Curves.easeInOut),
    );
    
    // Masraf butonu için glow animasyonu
    _masrafGlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _masrafGlowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _masrafGlowController!, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addObserver(this);
    
    // Provider'dan mevcut hüküm versiyonunu al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final davaProvider = Provider.of<DavaProvider>(context, listen: false);
          _lastHukumUpdateVersion = davaProvider.hukumUpdateVersion;
        } catch (e) {
          print('⚠️ [FiveCardCaseInformation] Provider bulunamadı: $e');
        }
      }
    });
    
    _initializeCountdown();
    _loadConsensusEvaluation();
    _startCountdownTimer();
    _loadExistingHukumler();
    _loadYargicCezaVeMasraf();
    _loadDavaActions(); // ✅ Dava aksiyonlarını yükle
  }
  
  /// Dava aksiyonlarını Hive'dan yükle
  void _loadDavaActions() {
    if (widget.userEmail == null) return;
    
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) return;
    
    setState(() {
      _davaActionStats = HiveDatabaseService.getDavaActionStats(davaId);
      _userDavaAction = HiveDatabaseService.getUserDavaAction(davaId, widget.userEmail!);
    });
    
    // Hüküm süresi dolduysa hüküm hesapla ve yükle
    if (_isHukumSuresiDoldu()) {
      DavaHukumService.calculateAndSaveHukum(davaId).then((hukumVerisi) {
        if (hukumVerisi != null && mounted) {
          setState(() {});
        }
      });
    }
  }
  
  /// Hüküm verisini getir
  Map<String, dynamic>? _getHukumVerisi() {
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) return null;
    
    // Önce dava verisinden kontrol et
    if (widget.davaData['hukumSonucu'] != null) {
      return {
        'hukumSonucu': widget.davaData['hukumSonucu'],
        'hukumTarihi': widget.davaData['hukumTarihi'],
        'hukumAciklamasi': widget.davaData['hukumAciklamasi'],
      };
    }
    
    // Hive'dan kontrol et
    return HiveDatabaseService.getDavaHukumVerisi(davaId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _animationController.dispose();
    _cezaPulseController?.dispose();
    _masrafPulseController?.dispose();
    _cezaGlowController?.dispose();
    _masrafGlowController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshAllDataIfNeeded();
    }
  }

  /// Tüm verileri yeniden yükle (senkronizasyon için)
  Future<void> _refreshAllDataIfNeeded() async {
    final now = DateTime.now();
    if (_lastRefreshTime != null && 
        now.difference(_lastRefreshTime!) < _refreshCooldown) {
      return;
    }
    
    _lastRefreshTime = now;
    await _refreshAllData();
  }

  /// Tüm verileri yeniden yükle
  Future<void> _refreshAllData() async {
    await _loadExistingHukumler();
    await _loadYargicCezaVeMasraf();
    await _loadConsensusEvaluation();
  }

  /// Geri sayımı başlat
  void _initializeCountdown() {
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) {
      _remainingTime = null;
      return;
    }

    // acceptedAt veya createdAt tarihini al
    final acceptedAtStr = widget.davaData['acceptedAt'] as String? ?? 
                          widget.davaData['createdAt'] as String?;
    if (acceptedAtStr == null || acceptedAtStr.isEmpty) {
      _remainingTime = null;
      return;
    }

    final acceptedAt = DateTime.tryParse(acceptedAtStr);
    if (acceptedAt == null) {
      _remainingTime = null;
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(acceptedAt);
    const totalDuration = Duration(hours: 168); // 7 gün = 168 saat

    if (elapsed >= totalDuration) {
      _remainingTime = Duration.zero;
    } else {
      _remainingTime = totalDuration - elapsed;
    }

    setState(() {});
  }

  /// Geri sayım timer'ını başlat
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == null || _remainingTime == Duration.zero) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime!.inSeconds > 0) {
          _remainingTime = Duration(seconds: _remainingTime!.inSeconds - 1);
        } else {
          _remainingTime = Duration.zero;
          timer.cancel();
        }
      });
    });
  }

  DateTime? _getOpenedAtForRolSection() {
    final String davaId = (widget.davaData['id'] as String? ??
            widget.davaData['davaId'] as String? ??
            '')
        .trim();
    if (davaId.isNotEmpty) {
      final List<Map<String, dynamic>> opened = HiveDatabaseService.getOpenedDavalar();
      final Map<String, dynamic> row = opened.firstWhere(
        (Map<String, dynamic> d) => d['id'] == davaId,
        orElse: () => <String, dynamic>{},
      );
      final String? s = row['openedAt'] as String?;
      if (s != null && s.isNotEmpty) {
        final DateTime? p = DateTime.tryParse(s);
        if (p != null) {
          return p;
        }
      }
    }
    for (final String key in <String>['openedAt', 'acceptedAt', 'createdAt']) {
      final String? s = widget.davaData[key] as String?;
      if (s != null && s.isNotEmpty) {
        final DateTime? p = DateTime.tryParse(s);
        if (p != null) {
          return p;
        }
      }
    }
    return null;
  }

  bool get _canEvaluateConsensus {
    final String id = (widget.davaData['id'] as String? ??
            widget.davaData['davaId'] as String? ??
            '')
        .trim();
    return id.isNotEmpty;
  }

  Future<void> _refreshConsensus() async {
    await _loadConsensusEvaluation();
  }

  /// Konsensus değerlendirmesini yükle
  Future<void> _loadConsensusEvaluation() async {
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) return;

    setState(() {
      _isLoadingConsensus = true;
    });

    try {
      DateTime? openedAt = _getOpenedAtForRolSection();
      final acceptedAtStr = widget.davaData['acceptedAt'] as String? ??
          widget.davaData['createdAt'] as String?;
      if (openedAt == null &&
          acceptedAtStr != null &&
          acceptedAtStr.isNotEmpty) {
        openedAt = DateTime.tryParse(acceptedAtStr);
      }

      final evaluation = await DavaConsensusService.evaluateConsensus(
        davaId: davaId,
        openedAt: openedAt,
      );

      if (mounted) {
        setState(() {
          _consensusEvaluation = evaluation;
          _isLoadingConsensus = false;
        });
      }
    } catch (e) {
      print('❌ [FiveCardCaseInformation] Konsensus yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoadingConsensus = false;
        });
      }
    }
  }

  /// Kalan süre metnini al
  String _getRemainingTimeText() {
    if (_remainingTime == null) return 'Süre hesaplanıyor...';
    if (_remainingTime == Duration.zero) return 'İlelebet Bitti';

    final hours = _remainingTime!.inHours;
    final minutes = _remainingTime!.inMinutes % 60;
    final seconds = _remainingTime!.inSeconds % 60;

    if (hours > 0) {
      return '$hours saat $minutes dakika';
    } else if (minutes > 0) {
      return '$minutes dakika $seconds saniye';
    } else {
      return '$seconds saniye';
    }
  }

  /// Dava açılış tarihini al ve formatla
  String _getDavaAcilisTarihi() {
    // Öncelik sırası: openedAt, createdAt, acceptedAt
    final openedAtStr = widget.davaData['openedAt'] as String?;
    final createdAtStr = widget.davaData['createdAt'] as String?;
    final acceptedAtStr = widget.davaData['acceptedAt'] as String?;
    
    String? dateStr = openedAtStr ?? createdAtStr ?? acceptedAtStr;
    
    if (dateStr == null || dateStr.isEmpty) {
      return 'Tarih bilgisi yok';
    }
    
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) {
        return dateStr;
      }
      
      // Format: "DD.MM.YYYY HH:mm"
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      
      return '$day.$month.$year $hour:$minute';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ı dinle - hüküm verileri güncellendiğinde otomatik yenile
    return Consumer<DavaProvider>(
      builder: (context, davaProvider, child) {
        // Provider değiştiğinde hüküm verilerini yeniden yükle
        final currentVersion = davaProvider.hukumUpdateVersion;
        
        if (_lastHukumUpdateVersion != currentVersion && mounted) {
          _lastHukumUpdateVersion = currentVersion;
          
          // Async olarak yükle
          Future.microtask(() async {
            if (mounted) {
              await _loadExistingHukumler();
              await _loadYargicCezaVeMasraf();
            }
          });
        }
        
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFDDE9E2),
                      width: 1.4,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF101815).withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        // Ana içerik
                        InkWell(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          onTap: widget.onTap,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDavaKunyeSection(),
                                if (_shouldShowCezaMasrafButtons()) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _buildCezaOnaylaButton()),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildMasrafOnayPanel()),
                                    ],
                                  ),
                                ],
                                if (!isExpanded) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _buildCollapsedQuickActions()),
                                      const SizedBox(width: 8),
                                      _buildVerdictEmojiIcon(),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Detayları aç / kapat
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8F5),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFDCE7E1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            onTap: () async {
                              final wasExpanded = isExpanded;
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                              if (!wasExpanded && isExpanded) {
                                await _refreshAllDataIfNeeded();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 24,
                                      color: const Color(0xFF1B2A23),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isExpanded ? 'Detayları Gizle' : 'Detayları Göster',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Genişletilmiş içerik
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState:
                              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAFCFB),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.isSeyirDefteri)
                                  _buildUserYorumSection()
                                else if (_hasUserHukum())
                                  _buildUserKararSection(),
                                if ((widget.isSeyirDefteri && _hasUserYorum()) ||
                                    (!widget.isSeyirDefteri && _hasUserHukum()))
                                  const SizedBox(height: 16),
                                // Dava Konusu
                                if ((widget.davaData['davaKonusu'] as String? ?? '').isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description,
                                              size: 18,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Dava Konusu',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          widget.davaData['davaKonusu'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Konsensus bilgileri
                                if (_consensusEvaluation != null &&
                                    _consensusEvaluation!.totalVotes > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.people,
                                              size: 18,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Yargıç Kararları',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildVoteInfo(
                                                'Olumlu',
                                                _consensusEvaluation!.positiveCount,
                                                Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildVoteInfo(
                                                'Olumsuz',
                                                _consensusEvaluation!.negativeCount,
                                                Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                RolHukumKartlariSection(
                                  davaId: () {
                                    final String id = (widget.davaData['id'] as String? ??
                                            widget.davaData['davaId'] as String? ??
                                            '')
                                        .trim();
                                    return id.isEmpty ? null : id;
                                  }(),
                                  openedAt: _getOpenedAtForRolSection(),
                                  userEmail: widget.userEmail,
                                  kullaniciGorev:
                                      widget.davaData['mevkii'] as String? ?? '',
                                  rolHukumleri: _rolHukumleri,
                                  rolSentimentleri: _rolSentimentleri,
                                  rolCezalari: _rolCezalari,
                                  rolMasraflari: _rolMasraflari,
                                  seciliSentiment: _selectedSentiment,
                                  consensusEvaluation: _consensusEvaluation,
                                  consensusLoading: _isLoadingConsensus,
                                  onConsensusRefresh: _canEvaluateConsensus
                                      ? () => unawaited(_refreshConsensus())
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Dava ID
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'ID: ${widget.davaData['id'] ?? widget.davaData['davaId'] ?? 'Bilinmeyen'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontFamily: 'monospace',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isDavaActive() {
    return widget.davaData['isOpened'] as bool? ?? true;
  }

  /// [ActigimDavaCard._buildDavaKunyeSection] ile aynı çizgi; katılımcıya özgü alanlar korunur.
  Widget _buildDavaKunyeSection() {
    const Color kunyeBorder = Color(0xFFDCE7E1);
    final String kategoriRaw =
        (widget.davaData['kategori'] as String? ?? '').trim();
    final String kategoriDisplay =
        kategoriRaw.isNotEmpty ? kategoriRaw : 'Belirtilmedi';
    final String davaAdi = widget.davaData['adi'] as String? ??
        widget.davaData['davaAdi'] as String? ??
        'Dava Adı';
    final bool isActive = _isDavaActive();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kunyeBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _kunyeExpanded = !_kunyeExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '|| Dava Künyesi ||',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: Color(0xFF1B2A23),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.08)
                            : Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? Colors.green : Colors.orange,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            isActive ? Icons.check_circle : Icons.pending_outlined,
                            size: 14,
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Aktif' : 'Beklemede',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _kunyeExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more,
                        color: Colors.grey.shade600,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: const Duration(milliseconds: 280),
            crossFadeState: _kunyeExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Divider(height: 20),
                  _buildKunyeInfoRow(
                    'Kategori',
                    kategoriDisplay,
                    MdiIcons.shapeOutline,
                    iconColor: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  _buildKunyeInfoRow(
                    'Dava Adı',
                    davaAdi,
                    MdiIcons.gavel,
                    iconColor: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  _buildKunyeInfoRow(
                    'Davacı',
                    widget.davaData['davaci'] as String? ?? 'Bilinmeyen',
                    MdiIcons.account,
                    iconColor: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  _buildKunyeInfoRow(
                    'Davalı',
                    widget.davaData['davali'] as String? ?? 'Bilinmeyen',
                    MdiIcons.accountOutline,
                    iconColor: Colors.green.shade700,
                  ),
                  if (!widget.isSeyirDefteri) ...<Widget>[
                    const Divider(height: 20),
                    _buildKunyeInfoRow(
                      'Benim Görevim',
                      _getUserRole(),
                      _getBenimGorevimKunyeIcon(),
                      iconColor: _getBenimGorevimKunyeIconColor(),
                    ),
                  ],
                  const Divider(height: 20),
                  _buildKunyeInfoRow(
                    'Hüküm',
                    _getHukumStatus(),
                    MdiIcons.scaleBalance,
                    iconColor: _getHukumStatusColor(),
                    valueWidget: _buildVerdictEmojiIcon(),
                  ),
                  if (_isHukumSuresiDoldu()) ...<Widget>[
                    const Divider(height: 20),
                    _buildHukumVerisiCard(),
                  ],
                  const Divider(height: 20),
                  _buildKunyeCountdownSection(),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildKunyeInfoRow(
    String label,
    String value,
    IconData icon, {
    required Color iconColor,
    Widget? valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              valueWidget ??
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatKunyeDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Widget _buildKunyeCountdownSection() {
    final DateTime? openedAt = _getOpenedAtForRolSection();
    final String openedAtText = openedAt != null
        ? _formatKunyeDateTime(openedAt)
        : _getDavaAcilisTarihi();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              MdiIcons.timerAlertOutline,
              size: 20,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dava Açılış Tarihi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    openedAtText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  if (_remainingTime != null &&
                      _remainingTime != Duration.zero) ...<Widget>[

                  ],
                ],
              ),
            ),
            if (openedAt != null)
              CountdownTimerWidget(
                startTime: openedAt,
                totalDuration: const Duration(hours: 168),
                showHourglass: true,
              ),
          ],
        ),
      ],
    );
  }

  /// Davacı tarafının nihai sonucunu belirler (Temyiz > Yargıç > Konsensus)
  bool? _getFinalDavaciVerdict() {
    final normalizedTemyiz = _normalizeRole('Temyiz Hakimi Kararı');
    final HukumSentiment? temyizSent = _rolSentimentleri[normalizedTemyiz];
    if (temyizSent != null) {
      return temyizSent == HukumSentiment.positive;
    }

    final normalizedYargic = _normalizeRole('Yargıç Kararı');
    final HukumSentiment? yargicSent = _rolSentimentleri[normalizedYargic];
    if (yargicSent != null) {
      return yargicSent == HukumSentiment.positive;
    }

    if (_consensusEvaluation != null && _consensusEvaluation!.totalVotes > 0) {
      if (_consensusEvaluation!.positiveCount > _consensusEvaluation!.negativeCount) {
        return true;
      }
      if (_consensusEvaluation!.negativeCount > _consensusEvaluation!.positiveCount) {
        return false;
      }
    }

    return null;
  }

  /// Hükmüm durumunu al (kullanıcının kendi hükmü)
  /// Kullanıcının görevine göre (Davacı/Davalı) ve dava sonucuna göre durumu belirler
  String _getHukumStatus() {
    if (_isLoadingConsensus) return 'Yükleniyor... ⏳';

    final bool? davaciHakli = _getFinalDavaciVerdict();
    if (davaciHakli == null) {
      return 'Beklemede ⏳';
    }

    final userRole = _getUserRole();
    final isDavaci = userRole.toLowerCase().contains('davacı') || userRole.toLowerCase().contains('davaci');
    final isDavali = userRole.toLowerCase().contains('davalı') || userRole.toLowerCase().contains('davali');

    if (isDavaci) {
      return davaciHakli ? 'Haklı ✅' : 'Haksız ❌';
    }

    if (isDavali) {
      return davaciHakli ? 'Haksız ❌' : 'Haklı ✅';
    }

    final userHukum = _getUserHukum();
    if (userHukum != null && userHukum.trim().isNotEmpty) {
      return 'Beklemede ⏳';
    }

    return 'Beklemede ⏳';
  }

  /// Hükmüm durumu rengini al
  Color _getHukumStatusColor() {
    final status = _getHukumStatus();
    if (status.contains('Haklı') || status.contains('✅')) {
      return Colors.green.shade700;
    } else if (status.contains('Haksız') || status.contains('❌')) {
      return Colors.red.shade700;
    } else if (status.contains('Beklemede') || status.contains('⏳')) {
      return Colors.orange.shade700;
    }
    return Colors.orange.shade700;
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final Color displayColor = color is MaterialColor ? color.shade700 : color;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: displayColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: displayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: displayColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (value.isNotEmpty && VerifiedUsersService.isVerified(value))
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),

        ],
      ),
    );

  }

  Widget _buildVoteInfo(String label, int count, Color color) {
    final Color displayColor = color is MaterialColor ? color.shade700 : color;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: displayColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: displayColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Hüküm verisi kartını oluştur
  Widget _buildHukumVerisiCard() {
    final hukumVerisi = _getHukumVerisi();
    
    if (hukumVerisi == null) {
      return const SizedBox.shrink();
    }
    
    final hukumSonucu = hukumVerisi['hukumSonucu'] as String? ?? '';
    final hukumAciklamasi = hukumVerisi['hukumAciklamasi'] as String? ?? '';
    final hukumTarihiStr = hukumVerisi['hukumTarihi'] as String?;
    
    final isBasarili = hukumSonucu == 'basarili';
    final cardColor = isBasarili ? Colors.green : Colors.red;
    final iconData = isBasarili ? Icons.check_circle : Icons.cancel;
    final sonucText = isBasarili ? 'Başarılı' : 'Başarısız';
    
    DateTime? hukumTarihi;
    if (hukumTarihiStr != null && hukumTarihiStr.isNotEmpty) {
      hukumTarihi = DateTime.tryParse(hukumTarihiStr);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                iconData,
                size: 24,
                color: cardColor.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Dava Sonucu: $sonucText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cardColor.shade700,
                ),
              ),
            ],
          ),
          if (hukumTarihi != null) ...[
            const SizedBox(height: 8),
            Text(
              'Hüküm Tarihi: ${hukumTarihi.day}/${hukumTarihi.month}/${hukumTarihi.year}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (hukumAciklamasi.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cardColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hüküm Açıklaması:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hukumAciklamasi,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Giriş yapan kullanıcının kayıtlı hüküm sentiment'i (ör. jüri oyu), e‑posta ile eşleşir.
  HukumSentiment? _getHukumSentimentForLoggedInUser() {
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      final userEmailLower = widget.userEmail!.toLowerCase();
      for (final MapEntry<String, HukumSentiment> e in _rolSentimentleri.entries) {
        final String email = _rolUserEmails[e.key] ?? '';
        if (email.toLowerCase() == userEmailLower) {
          return e.value;
        }
      }
    }
    return _selectedSentiment ?? _rolSentimentleri[_getUserNormalizedRole()];
  }

  /// Jüri, Yargıç ve Temyiz Hakimi vb.: 8-Hüküm'de kayıtlı bireysel sentiment gösterilir.
  bool _isPersonalHukumSentimentRole() {
    final r = _getUserRole().toLowerCase();
    return r.contains('jüri') ||
        r.contains('juri') ||
        r.contains('yargıç') ||
        r.contains('yargic') ||
        r.contains('temyiz');
  }

  /// Kapalı görünümde davacı sonucunu ikonla temsil eder.
  /// Jüri / Yargıç / Temyiz: kullanıcının kayıtlı hüküm yönü; oy/sentiment yoksa soluk nötr yüz.
  /// Diğer roller: nihai dava sonucu (konsensus vb.).
  Widget _buildVerdictEmojiIcon() {
    late final IconData iconData;
    late final Color iconColor;

    if (_isPersonalHukumSentimentRole()) {
      final HukumSentiment? self = _getHukumSentimentForLoggedInUser();
      if (self == HukumSentiment.positive) {
        iconData = Icons.sentiment_satisfied_alt;
        iconColor = Colors.green.shade600;
      } else if (self == HukumSentiment.negative) {
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = Colors.red.shade600;
      } else {
        iconData = Icons.sentiment_neutral;
        iconColor = Colors.grey.shade500;
      }
      return Icon(iconData, size: 38, color: iconColor);
    }

    final bool? verdict = _getFinalDavaciVerdict();
    if (verdict == true) {
      iconData = Icons.sentiment_satisfied_alt;
      iconColor = Colors.green.shade600;
    } else if (verdict == false) {
      iconData = Icons.sentiment_very_dissatisfied;
      iconColor = Colors.red.shade600;
    } else {
      iconData = Icons.sentiment_neutral;
      iconColor = Colors.grey.shade500;
    }

    return Icon(iconData, size: 38, color: iconColor);
  }

  // Dava aksiyon istatistikleri (Hive'dan yüklenecek)
  Map<String, dynamic> _davaActionStats = {
    'totalLikes': 0,
    'totalDislikes': 0,
    'totalComments': 0,
    'totalShares': 0,
  };
  
  // Kullanıcının dava için aksiyonları (Hive'dan yüklenecek)
  Map<String, dynamic> _userDavaAction = {
    'like': false,
    'dislike': false,
    'commentCount': 0,
    'sharedAt': null,
  };

  /// Hüküm süresi doldu mu kontrol et
  bool _isHukumSuresiDoldu() {
    final acceptedAtStr = widget.davaData['acceptedAt'] as String?;
    if (acceptedAtStr == null || acceptedAtStr.isEmpty) {
      return false;
    }
    
    final acceptedAt = DateTime.tryParse(acceptedAtStr);
    if (acceptedAt == null) {
      return false;
    }
    
    return DavaHukumService.isHukumSuresiDoldu(acceptedAt);
  }

  /// Kapalı görünümde diğer kullanıcıların kullanabileceği hızlı aksiyon ikonları
  Widget _buildCollapsedQuickActions() {
    final isHukumSuresiDoldu = _isHukumSuresiDoldu();
    
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.start,
      children: [
        _buildQuickActionIcon(
          icon: (_userDavaAction['like'] ?? false) ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
          tooltip: 'Destek ver',
          count: _davaActionStats['totalLikes'] ?? 0,
          isActive: _userDavaAction['like'] ?? false,
          isDisabled: isHukumSuresiDoldu,
          onTap: isHukumSuresiDoldu ? () {} : () => _handleQuickActionTap('like'),
        ),
        _buildQuickActionIcon(
          icon: (_userDavaAction['dislike'] ?? false) ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
          tooltip: 'Kına',
          count: _davaActionStats['totalDislikes'] ?? 0,
          isActive: _userDavaAction['dislike'] ?? false,
          isDisabled: isHukumSuresiDoldu,
          onTap: isHukumSuresiDoldu ? () {} : () => _handleQuickActionTap('dislike'),
        ),
        _buildQuickActionIcon(
          icon: Icons.mode_comment_outlined,
          tooltip: 'Yorum yap (${_userDavaAction['commentCount'] ?? 0}/19)',
          count: _davaActionStats['totalComments'] ?? 0,
          isActive: false,
          isDisabled: isHukumSuresiDoldu,
          onTap: isHukumSuresiDoldu ? () {} : () => _handleQuickActionTap('comment'),
        ),
        _buildQuickActionIcon(
          icon: (_userDavaAction['sharedAt'] != null) ? Icons.share : Icons.share_outlined,
          tooltip: 'Paylaş',
          count: _davaActionStats['totalShares'] ?? 0,
          isActive: _userDavaAction['sharedAt'] != null,
          isDisabled: false, // Paylaş her zaman aktif
          onTap: () => _handleQuickActionTap('share'),
        ),
      ],
    );
  }

  Widget _buildQuickActionIcon({
    required IconData icon,
    required String tooltip,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final iconColor = isDisabled 
        ? Colors.grey.shade400 
        : (isActive ? Colors.blue.shade700 : Colors.grey.shade700);
    
    return Padding(
      padding: const EdgeInsets.only(right: 35.0),
      child: InkResponse(
        radius: 20,
        onTap: isDisabled ? null : onTap,
        child: Tooltip(
          message: isDisabled
              ? '${DavaHukumService.hukumSuresiGun} gün doldu, bu işlem artık yapılamaz'
              : tooltip,
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hızlı aksiyon butonuna tıklandığında
  Future<void> _handleQuickActionTap(String type) async {
    if (widget.userEmail == null) {
      _showActionSnack('Lütfen giriş yapın');
      return;
    }
    
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) {
      _showActionSnack('Dava ID bulunamadı');
      return;
    }
    
    // Hüküm süresi kontrolü - destek, kına, yorum için
    if (type == 'like' || type == 'dislike' || type == 'comment') {
      if (_isHukumSuresiDoldu()) {
        _showActionSnack(
          '⚠️ ${DavaHukumService.hukumSuresiGun} gün doldu, bu işlem artık yapılamaz',
        );
        return;
      }
    }
    
    try {
      if (type == 'like') {
        await HiveDatabaseService.toggleDavaLike(davaId, widget.userEmail!, true);
        _showActionSnack('✅ Destek verildi');
      } else if (type == 'dislike') {
        await HiveDatabaseService.toggleDavaLike(davaId, widget.userEmail!, false);
        _showActionSnack('❌ Kına gönderildi');
      } else if (type == 'comment') {
        final userAction = HiveDatabaseService.getUserDavaAction(davaId, widget.userEmail!);
        final commentCount = userAction['commentCount'] ?? 0;
        
        if (commentCount >= 19) {
          _showActionSnack('⚠️ Maksimum yorum sayısına ulaşıldı (19/19)');
          return;
        }
        
        // Yorum yazma dialogunu aç
        _showYorumDialog(davaId);
      } else if (type == 'share') {
        final userAction = HiveDatabaseService.getUserDavaAction(davaId, widget.userEmail!);
        if (userAction['sharedAt'] != null) {
          _showActionSnack('ℹ️ Bu davayı daha önce paylaştınız');
          return;
        }
        
        await HiveDatabaseService.shareDava(davaId, widget.userEmail!);
        _showActionSnack('📤 Dava seyir defterinize eklendi');
      }
      
      // Verileri yeniden yükle
      _loadDavaActions();
      
      // Hüküm süresi dolduysa hüküm hesapla
      if (_isHukumSuresiDoldu()) {
        await DavaHukumService.calculateAndSaveHukum(davaId);
      }
      
      // Callback'i çağır (sayfa yenileme için)
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      print('❌ Hızlı aksiyon hatası: $e');
      _showActionSnack('❌ İşlem sırasında hata oluştu');
    }
  }

  void _showActionSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Yorum yazma dialogunu göster
  void _showYorumDialog(String davaId) {
    final TextEditingController yorumController = TextEditingController();
    bool isGizliTanik = false; // Gizli tanık checkbox state'i
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Yorum Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: yorumController,
                      decoration: const InputDecoration(
                        hintText: 'Yorumunuzu yazın...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    // Gizli Tanık checkbox'ı
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isGizliTanik,
                            onChanged: (bool? value) {
                              setState(() {
                                isGizliTanik = value ?? false;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isGizliTanik = !isGizliTanik;
                                });
                              },
                              child: const Text(
                                'Gizli Tanık olarak yorum yap',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isGizliTanik) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Yorumunuz "${HiveDatabaseService.gizliTanikDisplayName}" adıyla görünecektir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final yorumMetni = yorumController.text.trim();
                    if (yorumMetni.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen bir yorum yazın'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(dialogContext).pop();
                    
                    // Yorum sayısı kontrolü
                    final userAction = HiveDatabaseService.getUserDavaAction(davaId, widget.userEmail!);
                    final commentCount = userAction['commentCount'] ?? 0;
                    
                    if (commentCount >= 19) {
                      _showActionSnack('⚠️ Maksimum yorum sayısına ulaşıldı (19/19)');
                      return;
                    }
                    
                    // Yorumu kaydet
                    final success = await HiveDatabaseService.addDavaComment(
                      davaId, 
                      widget.userEmail!,
                      yorumMetni: yorumMetni,
                      isGizliTanik: isGizliTanik,
                    );
                    
                    if (success) {
                      final tanikBilgisi = isGizliTanik ? ' (Gizli Tanık olarak)' : '';
                      _showActionSnack('💬 Yorum eklendi (${commentCount + 1}/19)$tanikBilgisi');
                      // Verileri yeniden yükle
                      _loadDavaActions();
                      // Callback'i çağır (sayfa yenileme için)
                      if (widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                    } else {
                      // ✅ 19 saniye kuralı hatası
                      _showActionSnack('⚠️ 19 saniye kuralı: Lütfen 19 saniye geçmeden yorum yapamazsınız.');
                      _showActionSnack('⚠️ Yorum eklenemedi');
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Mevcut hükümleri yükle ([ActigimDavaCard] / [ModernHukumCard] ile uyumlu birleştirme)
  Future<void> _loadExistingHukumler() async {
    final String pid =
        (widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '').trim();
    final String davaAdi =
        (widget.davaData['adi'] as String? ?? widget.davaData['davaAdi'] as String? ?? '').trim();
    final String? hid = davaAdi.isNotEmpty ? 'dava_${davaAdi.hashCode}' : null;

    if (pid.isEmpty && (hid == null || hid.isEmpty)) {
      return;
    }

    try {
      final DavaProvider davaProvider = Provider.of<DavaProvider>(context, listen: false);
      final List<Map<String, Map<String, dynamic>>> idChunks =
          <Map<String, Map<String, dynamic>>>[];

      if (pid.isNotEmpty) {
        Map<String, Map<String, dynamic>> byPid =
            await davaProvider.getHukumlerByDavaId(pid, davaAdi: davaAdi);
        if (byPid.isEmpty) {
          byPid = await HiveDatabaseService.getHukumlerByDavaIdGrouped(
            pid,
            davaAdi: davaAdi.isNotEmpty ? davaAdi : null,
          );
        }
        if (byPid.isNotEmpty) {
          idChunks.add(byPid);
        }
      }
      if (hid != null && (pid.isEmpty || hid != pid)) {
        final Map<String, Map<String, dynamic>> byHid =
            await HiveDatabaseService.getHukumlerByDavaIdGrouped(
          hid,
          davaAdi: davaAdi.isNotEmpty ? davaAdi : null,
        );
        if (byHid.isNotEmpty) {
          idChunks.add(byHid);
        }
      }

      final Map<String, Map<String, dynamic>> existing =
          _mergeKatildigimHukumlerGroupedMaps(idChunks);

      if (!mounted) {
        return;
      }

      final String cezaPrimaryId = pid.isNotEmpty ? pid : (hid ?? '');
      Map<String, String> cezalarByEmail = <String, String>{};
      Map<String, String> masraflarByEmail = <String, String>{};
      if (cezaPrimaryId.isNotEmpty) {
        cezalarByEmail = Map<String, String>.from(
          await HiveDatabaseService.getCezaMapForDavaId(cezaPrimaryId),
        );
        masraflarByEmail = Map<String, String>.from(
          await HiveDatabaseService.getMasrafGiftLineMapForDavaId(cezaPrimaryId),
        );
      }
      if (hid != null) {
        final Map<String, String> cezaAlt =
            await HiveDatabaseService.getCezaMapForDavaId(hid);
        final Map<String, String> masrafAlt =
            await HiveDatabaseService.getMasrafGiftLineMapForDavaId(hid);
        for (final MapEntry<String, String> e in cezaAlt.entries) {
          cezalarByEmail.putIfAbsent(e.key, () => e.value);
        }
        for (final MapEntry<String, String> e in masrafAlt.entries) {
          masraflarByEmail.putIfAbsent(e.key, () => e.value);
        }
      }

      setState(() {
        _rolHukumleri
          ..clear()
          ..addEntries(existing.entries.where((MapEntry<String, Map<String, dynamic>> entry) {
            final dynamic text = entry.value['hukumText'];
            return (text is String) && text.trim().isNotEmpty;
          }).map((MapEntry<String, Map<String, dynamic>> entry) {
            final String normalizedKey = normalizeRolKarari(entry.key);
            return MapEntry<String, String>(
              normalizedKey,
              entry.value['hukumText'].toString(),
            );
          }));

        _rolSentimentleri.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry in existing.entries) {
          final String? sentimentValue = entry.value['hukumSentiment'] as String?;
          final HukumSentiment? sentiment = hukumSentimentFromStorage(sentimentValue);
          final String normalizedKey = normalizeRolKarari(entry.key);
          if (sentiment != null) {
            _rolSentimentleri[normalizedKey] = sentiment;
          }
        }

        _rolFinalizasyonlari.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry in existing.entries) {
          final String roleFromRow =
              (entry.value['userRole'] as String?)?.trim().isNotEmpty == true
                  ? (entry.value['userRole'] as String)
                  : entry.key;
          final String normalizedKey = normalizeRolKarari(roleFromRow);
          final bool fin = _readHiveBool(entry.value['isFinalized']);
          _rolFinalizasyonlari[normalizedKey] =
              (_rolFinalizasyonlari[normalizedKey] ?? false) || fin;
        }

        _rolUserEmails.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry in existing.entries) {
          final String roleFromRow =
              (entry.value['userRole'] as String?)?.trim().isNotEmpty == true
                  ? (entry.value['userRole'] as String)
                  : entry.key;
          final String normalizedKey = normalizeRolKarari(roleFromRow);
          _rolUserEmails[normalizedKey] = entry.value['userEmail']?.toString() ?? '';
        }

        _rolCreatedAts.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry in existing.entries) {
          final String roleFromRow =
              (entry.value['userRole'] as String?)?.trim().isNotEmpty == true
                  ? (entry.value['userRole'] as String)
                  : entry.key;
          final String normalizedKey = normalizeRolKarari(roleFromRow);
          _rolCreatedAts[normalizedKey] = entry.value['createdAt']?.toString() ?? '';
        }

        _rolCezalari.clear();
        _rolMasraflari.clear();
        for (final MapEntry<String, Map<String, dynamic>> entry in existing.entries) {
          final String roleFromRow =
              (entry.value['userRole'] as String?)?.trim().isNotEmpty == true
                  ? (entry.value['userRole'] as String)
                  : entry.key;
          final String normalizedKey = normalizeRolKarari(roleFromRow);
          final String email = (entry.value['userEmail'] as String? ?? '').trim();
          if (email.isNotEmpty) {
            final String emailKey = email.toLowerCase();
            final String? ceza = cezalarByEmail[emailKey];
            final String? masraf = masraflarByEmail[emailKey];
            if (ceza != null && ceza.trim().isNotEmpty) {
              _rolCezalari[normalizedKey] = ceza.trim();
            }
            if (masraf != null && masraf.trim().isNotEmpty) {
              _rolMasraflari[normalizedKey] = masraf.trim();
            }
          }
        }

        final String normalizedUserRole =
            normalizeRolKarari(widget.davaData['mevkii'] as String? ?? '');
        _selectedSentiment = _rolSentimentleri[normalizedUserRole];
      });
    } catch (e) {
      print('❌ [FiveCardCaseInformation] Hükümler yüklenirken hata: $e');
    }
  }

  static bool _readHiveBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value != 0;
    }
    if (value is String) {
      final String s = value.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return false;
  }

  String _normalizeRole(String rolAdi) => normalizeRolKarari(rolAdi);

  /// Geçerli ceza, masraf (davalı) ve hediye (davacı) — konsensus ile senkron.
  Future<void> _loadYargicCezaVeMasraf() async {
    final String davaId =
        widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    final String davaAdi = widget.davaData['adi'] ?? widget.davaData['davaAdi'] ?? '';

    if (davaId.isEmpty) {
      return;
    }

    try {
      final CezaDavaLoadResult cezaLoad =
          await CezaConsensusService.loadEffectiveCezaForDava(
        davaId: davaId,
        davaAdi: davaAdi.toString(),
      );
      final List<String>? masraflar =
          await CezaConsensusService.loadMasraflarForDava(
        loadResult: cezaLoad,
        davaId: davaId,
        davaAdi: davaAdi.toString(),
      );

      final HediyeDavaLoadResult hediyeLoad =
          await HediyeConsensusService.loadEffectiveHediyeForDava(
        davaId: davaId,
        davaAdi: davaAdi.toString(),
      );
      final List<String>? hediyeler =
          await HediyeConsensusService.loadHediyeListForDava(
        loadResult: hediyeLoad,
        davaId: davaId,
        davaAdi: davaAdi.toString(),
      );

      if (!mounted) {
        return;
      }
      final String? cezaText = cezaLoad.effective.cezaText;
      final String cezaKaynak = cezaLoad.effective.sourceLabel();
      final String hediyeKaynak = hediyeLoad.effective.sourceLabel();
      setState(() {
        _yargicCezaText =
            (cezaText != null && cezaText.trim().isNotEmpty) ? cezaText.trim() : null;
        _effectiveCezaKaynak = cezaKaynak.isNotEmpty ? cezaKaynak : null;
        _yargicMasraflar = masraflar;
        _hediyeOnayList = hediyeler;
        _effectiveHediyeKaynak = hediyeKaynak.isNotEmpty ? hediyeKaynak : null;
      });
    } catch (e) {
      print('❌ [FiveCardCaseInformation] Ceza/masraf/hediye yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _yargicCezaText = null;
          _effectiveCezaKaynak = null;
          _yargicMasraflar = null;
          _hediyeOnayList = null;
          _effectiveHediyeKaynak = null;
        });
      }
    }
  }

  /// Davacının haklı olup olmadığını kontrol eder
  bool _isDavaciHakli() {
    return _getFinalDavaciVerdict() ?? false;
  }

  String _cezaOnayGosterimMetni(bool hasCeza) {
    if (!hasCeza) {
      return _cezaOnaylandi ? 'Onaylandı' : 'Ceza bekleniyor';
    }
    final String metin = _yargicCezaText!.length > 25
        ? '${_yargicCezaText!.substring(0, 25)}...'
        : _yargicCezaText!;
    final String? kaynak = _effectiveCezaKaynak;
    if (kaynak != null && kaynak.isNotEmpty) {
      return '$metin · $kaynak';
    }
    return metin;
  }

  /// Ceza ve Masraf butonlarının gösterilip gösterilmeyeceğini belirler
  bool _shouldShowCezaMasrafButtons() {
    final bool hasCezaOrMasraf = (_yargicCezaText != null && _yargicCezaText!.isNotEmpty) ||
        (_yargicMasraflar != null && _yargicMasraflar!.isNotEmpty) ||
        (_hediyeOnayList != null && _hediyeOnayList!.isNotEmpty);
    return hasCezaOrMasraf;
  }

  /// Cezanı Onayla/Kabul Et butonunu oluşturur
  Widget _buildCezaOnaylaButton() {
    final bool hasCeza = _yargicCezaText != null && _yargicCezaText!.isNotEmpty;
    final bool isEnabled = hasCeza && !_cezaOnaylandi;
    final bool davaciHakli = _isDavaciHakli();
    final String buttonText = davaciHakli 
        ? (_cezaOnaylandi ? 'Ceza Kabul Edildi ✅' : 'CEZANI KABUL ET')
        : (_cezaOnaylandi ? 'Ceza Onaylandı ✅' : 'CEZASINI ONAYLA');

    if (_cezaPulseController == null || _cezaGlowController == null || 
        _cezaPulseAnimation == null || _cezaGlowAnimation == null) {
      return _buildSimpleCezaButton(hasCeza, isEnabled, buttonText);
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([_cezaPulseController!, _cezaGlowController!]),
      builder: (context, child) {
        return Transform.scale(
          scale: isEnabled ? _cezaPulseAnimation!.value : 1.0,
          child: GestureDetector(
            onTap: isEnabled ? () => _onCezaOnayla() : null,
            onTapDown: isEnabled
                ? (_) => setState(() => _cezaIconPressed = true)
                : null,
            onTapUp: isEnabled
                ? (_) => setState(() => _cezaIconPressed = false)
                : null,
            onTapCancel: isEnabled
                ? () => setState(() => _cezaIconPressed = false)
                : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade700,
                          Colors.red.shade900,
                        ],
                      )
                    : null,
                color: isEnabled ? null : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled ? Colors.red.shade300 : Colors.grey.withOpacity(0.3),
                  width: isEnabled ? 2.5 : 1,
                ),
                boxShadow: isEnabled && _cezaGlowAnimation != null
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(_cezaGlowAnimation!.value),
                          blurRadius: 20 * _cezaGlowAnimation!.value,
                          spreadRadius: 5 * _cezaGlowAnimation!.value,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildInteractiveIconBadge(
                        icon: MdiIcons.handcuffs,
                        isEnabled: isEnabled,
                        pressed: _cezaIconPressed,
                        settled: _cezaOnaylandi,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isEnabled ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _cezaOnayGosterimMetni(hasCeza),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.white : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// KURAL SETİ (Nihai) uyarınca Masraf onay panelini döndürür.
  ///
  /// Bu sayfa Davalı tarafıdır — Davalı login user olarak ekrana bakıyor:
  ///
  /// - Durum 1 (Davacı haklı, Davalı ÜYE) → **MASRAFLARI ONAYLA** butonu
  ///   görünür ve aktiftir; Davalı bastığında −Sarı −Yeşil düşer (yeşil
  ///   negatife düşebilir), Davacı'ya +Yeşil eklenir.
  /// - Durum 2 (Davalı üye değil) → Davalı sistemde yok, bu sayfa zaten
  ///   açılmaz.
  /// - Durum 3 (Davacı haksız, Davalı ÜYE) → Davacı basacak; bu sayfada
  ///   Davalı **MASRAF/UYAR** butonunu görür (19 günde bir hatırlatma).
  /// - Durum 4 (Davacı haksız, Davalı üye değil) → Davalı sistemde yok, bu
  ///   sayfa zaten açılmaz.
  Widget _buildMasrafOnayPanel() {
    final bool davaciHakli = _isDavaciHakli();
    final String davaciJudgeName =
        (widget.davaData['davaci'] as String?)?.trim() ?? '';
    final String davaliJudgeName =
        (widget.davaData['davali'] as String?)?.trim() ?? '';
    final String davaId =
        (widget.davaData['id'] as String? ??
                widget.davaData['davaId'] as String? ??
                '')
            .trim();
    final String davaAdi =
        (widget.davaData['davaAdi'] as String? ??
                widget.davaData['adi'] as String? ??
                '')
            .trim();

    if (davaId.isEmpty || davaciJudgeName.isEmpty || davaliJudgeName.isEmpty) {
      // Eksik veri → eski animasyonlu butonu fallback olarak göster.
      return _buildMasrafOnaylaButton();
    }

    final decision = MasrafOnayService.decide(
      davaciHakli: davaciHakli,
      davaciJudgeName: davaciJudgeName,
      davaliJudgeName: davaliJudgeName,
    );

    final String? currentJudgeName = widget.userEmail == null
        ? null
        : HiveDatabaseService.getRegistrationByEmail(widget.userEmail!)
            ?.judgeName;

    return MasrafOnayPanel(
      davaId: davaId,
      davaAdi: davaAdi,
      decision: decision,
      currentUserEmail: widget.userEmail,
      currentUserJudgeName: currentJudgeName,
      onStateChanged: () {
        if (mounted) {
          setState(() {
            _masrafOnaylandi = true;
          });
        }
      },
    );
  }

  /// Masrafları Onayla/Kabul Et butonunu oluşturur (eski sürüm — fallback).
  Widget _buildMasrafOnaylaButton() {
    final bool hasMasraf = _yargicMasraflar != null && _yargicMasraflar!.isNotEmpty;
    final bool isEnabled = hasMasraf && !_masrafOnaylandi;
    final bool davaciHakli = _isDavaciHakli();
    final String buttonText = davaciHakli
        ? (_masrafOnaylandi ? 'Masraf Kabul Edildi ✅' : 'MASRAFLARI KABUL ET')
        : (_masrafOnaylandi ? 'Masraf Onaylandı ✅' : 'MASRAFLARI ONAYLA');

    if (_masrafPulseController == null || _masrafGlowController == null || 
        _masrafPulseAnimation == null || _masrafGlowAnimation == null) {
      return _buildSimpleMasrafButton(hasMasraf, isEnabled, buttonText);
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([_masrafPulseController!, _masrafGlowController!]),
      builder: (context, child) {
        return Transform.scale(
          scale: isEnabled ? _masrafPulseAnimation!.value : 1.0,
          child: GestureDetector(
            onTap: isEnabled ? () => _onMasrafOnayla() : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade700,
                          Colors.deepPurple.shade900,
                        ],
                      )
                    : null,
                color: isEnabled ? null : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled ? Colors.purple.shade300 : Colors.grey.withOpacity(0.3),
                  width: isEnabled ? 2.5 : 1,
                ),
                boxShadow: isEnabled && _masrafGlowAnimation != null
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(_masrafGlowAnimation!.value),
                          blurRadius: 20 * _masrafGlowAnimation!.value,
                          spreadRadius: 5 * _masrafGlowAnimation!.value,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isEnabled ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          MdiIcons.giftOpenOutline,
                          size: 24,
                          color: isEnabled ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isEnabled ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Basit ceza butonu (animasyon controller'ları yoksa)
  Widget _buildSimpleCezaButton(bool hasCeza, bool isEnabled, String buttonText) {
    return GestureDetector(
      onTap: isEnabled ? () => _onCezaOnayla() : null,
      onTapDown: isEnabled
          ? (_) => setState(() => _cezaIconPressed = true)
          : null,
      onTapUp: isEnabled
          ? (_) => setState(() => _cezaIconPressed = false)
          : null,
      onTapCancel: isEnabled
          ? () => setState(() => _cezaIconPressed = false)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade700,
                    Colors.red.shade900,
                  ],
                )
              : null,
          color: isEnabled ? null : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? Colors.red.shade300 : Colors.grey.withOpacity(0.3),
            width: isEnabled ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildInteractiveIconBadge(
              icon: MdiIcons.handcuffs,
              isEnabled: isEnabled,
              pressed: _cezaIconPressed,
              settled: _cezaOnaylandi,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cezaOnayGosterimMetni(hasCeza),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.white70 : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveIconBadge({
    required IconData icon,
    required bool isEnabled,
    required bool pressed,
    required bool settled,
  }) {
    final bool secondState = pressed || settled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? Colors.white.withOpacity(0.85) : Colors.grey.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          children: <Widget>[
            AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: secondState ? 1 : 0,
              child: Align(
                alignment: Alignment.topLeft,
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 11,
                  color: isEnabled ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              alignment:
                  secondState ? const Alignment(0.0, 0.15) : Alignment.topLeft,
              child: Padding(
                padding: secondState
                    ? const EdgeInsets.only(left: 6, top: 6)
                    : EdgeInsets.zero,
                child: Icon(
                  icon,
                  size: 18,
                  color: isEnabled ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Basit masraf butonu (animasyon controller'ları yoksa)
  Widget _buildSimpleMasrafButton(bool hasMasraf, bool isEnabled, String buttonText) {
    return GestureDetector(
      onTap: isEnabled ? () => _onMasrafOnayla() : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade700,
                    Colors.deepPurple.shade900,
                  ],
                )
              : null,
          color: isEnabled ? null : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? Colors.purple.shade300 : Colors.grey.withOpacity(0.3),
            width: isEnabled ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                MdiIcons.giftOpenOutline,
                size: 24,
                color: isEnabled ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ceza onaylama işlemi
  void _onCezaOnayla() {
    if (_yargicCezaText == null || _yargicCezaText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onaylanacak ceza bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cezayı Onayla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"$_yargicCezaText" cezasını onaylıyor musunuz?'),
              if (_effectiveCezaKaynak != null &&
                  _effectiveCezaKaynak!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Kaynak: $_effectiveCezaKaynak',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cezaOnaylandi = true;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Ceza onaylandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );
  }

  /// Masraf onaylama işlemi
  void _onMasrafOnayla() {
    if (_yargicMasraflar == null || _yargicMasraflar!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onaylanacak masraf bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Masrafları Onayla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_yargicMasraflar!.length} masraf onaylanacak:'),
              const SizedBox(height: 8),
              ..._yargicMasraflar!.map((masraf) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $masraf'),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _masrafOnaylandi = true;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Masraflar onaylandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );
  }

  /// Kullanıcının görevini al
  String _getUserRole() {
    return widget.davaData['mevkii'] as String? ?? 'Katılımcı';
  }

  /// Kullanıcının görevine göre normalize edilmiş rol adını al
  String _getUserNormalizedRole() {
    return normalizeRolKarari(_getUserRole());
  }

  /// Kullanıcının verdiği hükmü al
  /// Bu metod, giriş yapan kullanıcının (widget.userEmail) bu davada verdiği hükmü bulur
  String? _getUserHukum() {
    // Kullanıcı email'i yoksa hüküm bulunamaz
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return null;
    }
    
    final userEmailLower = widget.userEmail!.toLowerCase();
    
    // Öncelik 1: Kullanıcının email'ine göre direkt ara (en güvenilir yöntem)
    // Çünkü bir davada birden fazla kişi aynı görevde olabilir
    for (final entry in _rolHukumleri.entries) {
      final hukumUserEmail = _rolUserEmails[entry.key] ?? '';
      if (hukumUserEmail.toLowerCase() == userEmailLower) {
        // Bu kullanıcının hükmü bulundu
        return entry.value;
      }
    }
    
    // Öncelik 2: Kullanıcının görevine göre ara (fallback)
    // Eğer email ile bulunamazsa, görevine göre dene
    final normalizedRole = _getUserNormalizedRole();
    String? hukum = _rolHukumleri[normalizedRole];
    
    // Bulunan hükmün gerçekten bu kullanıcıya ait olduğunu doğrula
    if (hukum != null) {
      final hukumUserEmail = _rolUserEmails[normalizedRole] ?? '';
      if (hukumUserEmail.toLowerCase() != userEmailLower) {
        // Bu hüküm başka bir kullanıcıya ait, null döndür
        hukum = null;
      }
    }
    
    return hukum;
  }

  /// Kullanıcının hüküm verip vermediğini kontrol et
  bool _hasUserHukum() {
    return _getUserHukum() != null && _getUserHukum()!.trim().isNotEmpty;
  }

  /// Kullanıcının bu davada yorumu var mı kontrol et
  bool _hasUserYorum() {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return false;
    }
    
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) {
      return false;
    }
    
    final userAction = HiveDatabaseService.getUserDavaAction(davaId, widget.userEmail!);
    final yorumlar = userAction['yorumlar'] as List<dynamic>?;
    
    if (yorumlar == null || yorumlar.isEmpty) {
      return false;
    }
    
    // İlk yorumu bul (parentId olmayan, yani ana yorum)
    final firstComment = yorumlar.firstWhere(
      (yorum) {
        final yorumMap = Map<String, dynamic>.from(yorum as Map);
        return yorumMap['parentId'] == null || (yorumMap['parentId'] as String?)?.isEmpty == true;
      },
      orElse: () => null,
    );
    
    return firstComment != null;
  }

  /// Kullanıcının bu davadaki ilk yorumunu al
  Map<String, dynamic>? _getUserFirstComment() {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return null;
    }
    
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) {
      return null;
    }
    
    final userAction = HiveDatabaseService.getUserDavaAction(davaId, widget.userEmail!);
    final yorumlar = userAction['yorumlar'] as List<dynamic>?;
    
    if (yorumlar == null || yorumlar.isEmpty) {
      return null;
    }
    
    // İlk yorumu bul (parentId olmayan, yani ana yorum)
    try {
      final firstComment = yorumlar.firstWhere(
        (yorum) {
          final yorumMap = Map<String, dynamic>.from(yorum as Map);
          return yorumMap['parentId'] == null || (yorumMap['parentId'] as String?)?.isEmpty == true;
        },
      );
      
      return Map<String, dynamic>.from(firstComment as Map);
    } catch (e) {
      return null;
    }
  }

  /// Kullanıcının görev kartını oluşturur (vurgulu)
  Widget _buildUserRoleCard() {
    final userRole = _getUserRole();
    IconData roleIcon = _getRoleIcon(userRole);
    Color badgeIconColor = Colors.white;
    if (_isPersonalHukumSentimentRole()) {
      final HukumSentiment? s = _getHukumSentimentForLoggedInUser();
      if (s == HukumSentiment.positive) {
        roleIcon = Icons.sentiment_satisfied_alt;
      } else if (s == HukumSentiment.negative) {
        roleIcon = Icons.sentiment_very_dissatisfied;
      } else {
        roleIcon = Icons.sentiment_neutral;
        badgeIconColor = Colors.white.withOpacity(0.55);
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.deepPurple.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.purple.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  roleIcon,
                  size: 18,
                  color: badgeIconColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Benim Görevim',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            userRole,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Künye — Benim Görevim satırı ikonu (jüri / yargıç / temyiz: hüküm yönü; diğerleri: görev tipi).
  IconData _getBenimGorevimKunyeIcon() {
    if (!_isPersonalHukumSentimentRole()) {
      return _getRoleIcon(_getUserRole());
    }
    final HukumSentiment? s = _getHukumSentimentForLoggedInUser();
    if (s == HukumSentiment.positive) {
      return Icons.sentiment_satisfied_alt;
    }
    if (s == HukumSentiment.negative) {
      return Icons.sentiment_very_dissatisfied;
    }
    return Icons.sentiment_neutral;
  }

  Color _getBenimGorevimKunyeIconColor() {
    if (!_isPersonalHukumSentimentRole()) {
      return Colors.purple.shade700;
    }
    final HukumSentiment? s = _getHukumSentimentForLoggedInUser();
    if (s == HukumSentiment.positive) {
      return Colors.green.shade700;
    }
    if (s == HukumSentiment.negative) {
      return Colors.red.shade700;
    }
    return Colors.grey.shade500;
  }

  /// Görev tipine göre ikon al
  IconData _getRoleIcon(String role) {
    final roleLower = role.toLowerCase();
    if (roleLower.contains('yargıç') || roleLower.contains('yargic')) {
      return MdiIcons.gavel;
    } else if (roleLower.contains('temyiz')) {
      return MdiIcons.scaleBalance;
    } else if (roleLower.contains('jüri') || roleLower.contains('juri')) {
      return MdiIcons.accountGroup;
    } else if (roleLower.contains('avukat')) {
      return MdiIcons.accountTie;
    } else if (roleLower.contains('şahit') || roleLower.contains('sahit')) {
      return MdiIcons.account;
    } else if (roleLower.contains('davacı') || roleLower.contains('davaci')) {
      return Icons.person;
    } else if (roleLower.contains('davalı') || roleLower.contains('davali')) {
      return Icons.person_outline;
    }
    return Icons.work;
  }

  /// Kullanıcının yorumu bölümünü oluşturur (seyir defteri için)
  Widget _buildUserYorumSection() {
    final firstComment = _getUserFirstComment();
    
    if (firstComment == null) {
      return const SizedBox.shrink();
    }
    
    final yorumMetni = firstComment['yorum']?.toString() ?? '';
    if (yorumMetni.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final yorumTarihi = firstComment['tarih']?.toString() ?? '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.lightBlue.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.comment,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benim Yorumum',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    if (yorumTarihi.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatCommentDate(yorumTarihi),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: ExpandableCommentText(
              text: yorumMetni,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 3,
              linkColor: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Yorum tarihini formatla
  String _formatCommentDate(String dateStr) {
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) {
        return dateStr;
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return dateStr;
    }
  }

  /// Kullanıcının kararı bölümünü oluşturur (sadece karar varsa gösterilir)
  Widget _buildUserKararSection() {
    final userHukum = _getUserHukum();
    final userRole = _getUserRole();
    final normalizedRole = _getUserNormalizedRole();
    
    if (userHukum == null || userHukum.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.lightGreen.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  MdiIcons.fileCheck,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benim Kararım',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      userRole,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showUserHukumDialog(normalizedRole, userHukum),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.visibility,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              userHukum.length > 150 
                  ? '${userHukum.substring(0, 150)}...' 
                  : userHukum,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Kullanıcının hükmü dialog'unu göster
  void _showUserHukumDialog(String normalizedRole, String hukumText) {
    final String userEmail = _rolUserEmails[normalizedRole] ?? widget.userEmail ?? '';
    final String createdAt = _rolCreatedAts[normalizedRole] ?? '';
    String displayName = 'Bilinmeyen Yargıç';
    
    if (userEmail.isNotEmpty) {
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      displayName = user?.judgeName ?? userEmail.split('@').first;
    }

    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.tryParse(createdAt);
        if (date != null) {
          formattedDate = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final double screenHeight = MediaQuery.of(context).size.height;
        final double maxHeight = screenHeight * 0.8;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.green.shade50,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Icon(
                              MdiIcons.fileCheck,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Benim Kararım - ${_getUserRole()}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (displayName.isNotEmpty || formattedDate.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      displayName.isNotEmpty && formattedDate.isNotEmpty
                                          ? '$displayName • $formattedDate'
                                          : displayName.isNotEmpty
                                              ? displayName
                                              : formattedDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        hukumText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToSekizHukumPage();
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        'Kararı Düzenle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Sekiz Hüküm sayfasına yönlendir
  void _navigateToSekizHukumPage() {
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    final davaAdi = widget.davaData['adi'] ?? widget.davaData['davaAdi'] ?? 'Dava Adı';
    final davaDavali = widget.davaData['davali'] ?? 'Davalı';
    final davaDavaci = widget.davaData['davaci'] ?? 'Davacı';
    final davaGorev = _getUserRole();
    final kalanSure = _getRemainingTimeText();
    
    // openedAt veya acceptedAt tarihini al
    final openedAtStr = widget.davaData['openedAt'] as String? ?? 
                        widget.davaData['acceptedAt'] as String? ??
                        widget.davaData['createdAt'] as String?;
    DateTime? openedAt;
    if (openedAtStr != null && openedAtStr.isNotEmpty) {
      openedAt = DateTime.tryParse(openedAtStr);
    }

    final arguments = SekizHukumArguments(
      davaId: davaId,
      davaAdi: davaAdi,
      davaDavali: davaDavali,
      davaDavaci: davaDavaci,
      davaGorev: davaGorev,
      kalanSure: kalanSure,
      openedAt: openedAt,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SekizHukumPage(
          userEmail: widget.userEmail,
          arguments: arguments,
        ),
      ),
    ).then((_) {
      // Sayfa geri döndüğünde verileri yeniden yükle
      if (mounted) {
        _refreshAllDataIfNeeded();
      }
    });
  }
}