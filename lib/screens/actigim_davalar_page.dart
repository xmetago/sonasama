import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/common_header_widgets.dart';
import 'gelen_davalar_page.dart';
import 'yargila_page.dart';
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import '../services/hive_database_service.dart';
import '../services/dava_consensus_service.dart';
import '../services/evidence_service.dart';
import '../models/evidence_model.dart';
import '../models/hukum_sentiment.dart';
import '../utils/dialog_utils.dart';
import '../models/dava.dart' as dava_model;
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import 'delil_listesi_ekrani.dart';

import 'dava_ac_page.dart'; // New import for dava açma
import 'katildigim_davalar_page.dart';
import 'haykirislarim_page.dart';

// Dava modeli (dava_ac_page.dart ile uyumlu)
class Dava {
  final String id;
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String davaKonusu;
  final String davaci; // Davacı bilgisi alanı eklendi
  final bool isOpened;

  Dava({
    required this.id,
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    this.davaKonusu = '',
    this.davaci = '', // Varsayılan boş değer
    this.isOpened = false,
  });
}

class ActigimDavalarPage extends StatefulWidget {
  final String? userEmail;

  const ActigimDavalarPage({super.key, this.userEmail});

  @override
  State<ActigimDavalarPage> createState() => _ActigimDavalarPageState();
}

class _ActigimDavalarPageState extends State<ActigimDavalarPage> {
  bool showLeftIcons = false;
  List<Dava> davaList = [];
  List<Dava> rejectedDavaList = []; // Red edilen davalar

  // Provider senkronizasyonu için: Son yüklenen hüküm versiyonu
  int _lastHukumUpdateVersion = -1;
  // Performans optimizasyonu: Son refresh zamanı
  DateTime? _lastListRefreshTime;
  static const Duration _listRefreshCooldown = Duration(seconds: 2); // 2 saniye cooldown

  @override
  void initState() {
    super.initState();
    _loadOpenedDavalar();
    _loadRejectedDavalar();
    
    // Provider versiyonunu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        _lastHukumUpdateVersion = davaProvider.hukumUpdateVersion;
        print('🔍 [ActigimDavalarPage] initState: Provider versiyonu = $_lastHukumUpdateVersion');
      } catch (e) {
        print('⚠️ [ActigimDavalarPage] initState: Provider bulunamadı: $e');
      }
    });
  }


  // Açılan davaları ve beklemede davaları yükle
  void _loadOpenedDavalar() {
    final openedDavalar = HiveDatabaseService.getOpenedDavalar();
    final savedDavalar = HiveDatabaseService.getSavedDavalar();
    
    // Tüm davaları birleştir
    final allDavalar = [...openedDavalar, ...savedDavalar];
    
    setState(() {
      davaList = allDavalar.map((davaMap) => Dava(
        id: davaMap['id'] ?? '',
        adi: davaMap['davaAdi'] ?? davaMap['adi'] ?? '',
        davali: davaMap['davali'] ?? '',
        mevkii: davaMap['mevkii'] ?? '',
        kalanSure: davaMap['kalanSure'] ?? '',
        profilResmi: davaMap['profilResmi'] ?? '',
        davaKonusu: davaMap['davaKonusu'] ?? '',
        davaci: davaMap['davaci'] ?? '', // Davacı bilgisi eklendi
        isOpened: davaMap['isOpened'] ?? false,
      )).toList();
    });
  }

  // Red edilen davaları yükle
  void _loadRejectedDavalar() async {
    try {
      final rejectedDavalar = await HiveDatabaseService.getRejectedDavalar(widget.userEmail ?? '');
      setState(() {
        rejectedDavaList = rejectedDavalar.map((davaMap) => Dava(
          id: davaMap['id'] ?? '',
          adi: davaMap['adi'] ?? '',
          davali: davaMap['davali'] ?? '',
          mevkii: davaMap['mevkii'] ?? '',
          kalanSure: davaMap['kalanSure'] ?? '',
          profilResmi: davaMap['profilResmi'] ?? '',
          davaKonusu: davaMap['davaKonusu'] ?? '',
          davaci: davaMap['davaci'] ?? '',
          isOpened: false, // Red edilen davalar açık değil
        )).toList();
      });
    } catch (e) {
      print('Red edilen davalar yüklenirken hata: $e');
    }
  }

  // Modern alert gösterme fonksiyonu (kullanılmıyor ama korunuyor)
  // ignore: unused_element
  void _showModernAlert(BuildContext context, String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'TAMAM',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DavaProvider>(
      builder: (context, authProvider, davaProvider, child) {
        // Provider değişikliklerini dinle - liste otomatik senkronizasyonu için
        final currentVersion = davaProvider.hukumUpdateVersion;
        
        // Eğer versiyon değiştiyse ve cooldown geçtiyse, listeyi yeniden yükle
        if (_lastHukumUpdateVersion != currentVersion) {
          final now = DateTime.now();
          if (_lastListRefreshTime == null || 
              now.difference(_lastListRefreshTime!) >= _listRefreshCooldown) {
            print('🔄 [ActigimDavalarPage] Provider versiyonu değişti: $_lastHukumUpdateVersion -> $currentVersion');
            _lastHukumUpdateVersion = currentVersion;
            _lastListRefreshTime = now;
            
            // Widget build tamamlandıktan sonra listeyi yeniden yükle (performans için)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                print('✅ [ActigimDavalarPage] Liste yeniden yüklenecek (versiyon: $currentVersion)');
                _loadOpenedDavalar();
              }
            });
          }
        }
        
        return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
              ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
              // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
              ),
              // ROW 3: Profil Bölümü
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                  userEmail: widget.userEmail,
                  onShowSavedDavalar: () {
                    // Global utility fonksiyonunu kullan
                    if (widget.userEmail != null) {
                      showSavedDavalarDialog(context, widget.userEmail!);
                    }
                  },
                ),
              ),
              // ROW 4: Hamburger Iconu, Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TreeMenuPageheadlines(
                  onMenuPressed: () {
                    setState(() {
                      showLeftIcons = !showLeftIcons;
                    });
                  },
                ),
              ),
              // ROW 5: Red Edilen Davalar Bölümü (FiveCardCaseInformation widget kullanarak)
              if (rejectedDavaList.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Başlık
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red.shade700, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'RED EDİLEN DAVALAR (${rejectedDavaList.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Red edilen dava kartları
                      ...rejectedDavaList.map((dava) => InactiveDavaCard(dava: dava)),
                    ],
                  ),
                ),
              ],

              // ROW 6: 6 Icon Solda, Sağda Text Yazma Alanı (Scrollable with ListTile)
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

                    Expanded(
                      child: Column(
                        children: [


                          // Dava listesi
                          if (davaList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Henüz dava açmadınız',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: davaList.length,
                              itemBuilder: (context, index) {
                                final dava = davaList[index];
                                return ActigimDavaCard(
                                  key: ValueKey(dava.id), // Dava ID'sine göre key
                                  dava: dava,
                                  userEmail: widget.userEmail,
                                  onTap: () async {
                                    // Beklemede davalar için düzenleme moduna geç
                                    if (dava.adi == 'Beklemede' && !dava.isOpened) {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => DavaAcPage(
                                            userEmail: widget.userEmail,
                                            editDava: dava_model.Dava(
                                              id: dava.id,
                                              davaAdi: dava.adi,
                                              davaci: dava.davaci,
                                              davali: dava.davali,
                                              mevkii: dava.mevkii,
                                              kalanSure: dava.kalanSure,
                                              profilResmi: dava.profilResmi,
                                              davaKonusu: dava.davaKonusu,
                                              kategori: '',
                                              isOpened: dava.isOpened,
                                            ),
                                          ),
                                        ),
                                      );
                                      // Sayfa geri döndüğünde verileri yeniden yükle
                                      if (mounted) {
                                        _loadOpenedDavalar();
                                      }
                                    }
                                  },
                                );
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

class TreeMenuPageheadlines extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  
  const TreeMenuPageheadlines({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            MdiIcons.menuOpen,
            size: 34,
            color: Colors.red,
          ),
          onPressed: onMenuPressed ?? () {
            print("Menu button pressed");
          },
        ),
        const Expanded(
          child: Center(
            child: Text(
              "AÇTIĞIM DAVALAR",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modern Dava Kartı Widget'ı - Açtığım Davalar için
/// 168 saatlik geri sayım, hüküm durumu ve modern UI ile
class ActigimDavaCard extends StatefulWidget {
  final Dava dava;
  final String? userEmail;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh; // Verileri yeniden yüklemek için callback

  const ActigimDavaCard({
    super.key,
    required this.dava,
    this.userEmail,
    this.onTap,
    this.onRefresh,
  });

  @override
  State<ActigimDavaCard> createState() => _ActigimDavaCardState();
}

class _ActigimDavaCardState extends State<ActigimDavaCard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool isExpanded = false;
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
  final Map<String, String> _rolUserEmails = <String, String>{}; // Hüküm veren kullanıcı email'leri
  final Map<String, String> _rolCreatedAts = <String, String>{}; // Hüküm oluşturulma tarihleri
  List<EvidenceModel> _deliller = [];
  final EvidenceService _evidenceService = EvidenceService();
  
  // Ceza ve masraf bilgileri (Yargıç veya Temyiz Hakimi için)
  String? _yargicCezaText; // Yargıç veya Temyiz Hakimi'nin belirlediği ceza
  List<String>? _yargicMasraflar; // Yargıç veya Temyiz Hakimi'nin belirlediği masraflar
  bool _cezaOnaylandi = false; // Ceza onaylandı mı?
  bool _masrafOnaylandi = false; // Masraf onaylandı mı?
  
  // Performans optimizasyonu: Son refresh zamanı
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 2); // 2 saniye cooldown
  
  // Provider senkronizasyonu için: Son yüklenen hüküm versiyonu (Provider değişikliklerini takip etmek için)
  int _lastHukumUpdateVersion = -1;

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
    
    // Ceza butonu için pulse animasyonu (sürekli büyüyüp küçülme)
    _cezaPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _cezaPulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _cezaPulseController!, curve: Curves.easeInOut),
    );
    
    // Ceza butonu için glow animasyonu (parlak ışık efekti)
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
    
    // WidgetsBindingObserver'ı ekle
    WidgetsBinding.instance.addObserver(this);
    
    // Provider'dan mevcut hüküm versiyonunu al (ilk yükleme için)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final davaProvider = Provider.of<DavaProvider>(context, listen: false);
          _lastHukumUpdateVersion = davaProvider.hukumUpdateVersion;
          print('🔍 [ActigimDavaCard] initState: Provider versiyonu = $_lastHukumUpdateVersion');
        } catch (e) {
          print('⚠️ [ActigimDavaCard] initState: Provider bulunamadı: $e');
        }
      }
    });
    
    _initializeCountdown();
    _loadConsensusEvaluation();
    _startCountdownTimer();
    _loadExistingHukumler();
    _loadYargicCezaVeMasraf(); // Yargıç veya Temyiz Hakimi'nin ceza ve masraf bilgilerini yükle
    // _loadEvidences(); // Kaldırıldı - sadece okunabilir mod
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
    // Uygulama foreground'a döndüğünde verileri yeniden yükle (performans için cooldown kontrolü)
    if (state == AppLifecycleState.resumed) {
      _refreshAllDataIfNeeded();
    }
  }

  /// Tüm verileri yeniden yükle (senkronizasyon için) - Performans optimizasyonu ile
  Future<void> _refreshAllDataIfNeeded() async {
    // Cooldown kontrolü: Son refresh'ten 2 saniye geçmediyse refresh yapma
    final now = DateTime.now();
    if (_lastRefreshTime != null && 
        now.difference(_lastRefreshTime!) < _refreshCooldown) {
      print('⏭️ [ActigimDavaCard] Refresh cooldown aktif, atlanıyor');
      return;
    }
    
    _lastRefreshTime = now;
    await _refreshAllData();
  }

  /// Tüm verileri yeniden yükle (senkronizasyon için)
  Future<void> _refreshAllData() async {
    await _loadExistingHukumler();
    await _loadYargicCezaVeMasraf();
    await _loadConsensusEvaluation();
  }

  /// Geri sayımı başlat
  void _initializeCountdown() {
    if (!widget.dava.isOpened) {
      print('⏰ [ActigimDavaCard] Dava açılmamış, geri sayım başlatılmıyor');
      _remainingTime = null;
      return;
    }

    // openedAt tarihini al
    final openedDavalar = HiveDatabaseService.getOpenedDavalar();
    final davaData = openedDavalar.firstWhere(
      (d) => d['id'] == widget.dava.id,
      orElse: () => {},
    );

    final openedAtStr = davaData['openedAt'] as String?;
    if (openedAtStr == null || openedAtStr.isEmpty) {
      print('⚠️ [ActigimDavaCard] openedAt bulunamadı: ${widget.dava.id}');
      _remainingTime = null;
      return;
    }

    final openedAt = DateTime.tryParse(openedAtStr);
    if (openedAt == null) {
      print('❌ [ActigimDavaCard] openedAt parse edilemedi: $openedAtStr');
      _remainingTime = null;
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(openedAt);
    const totalDuration = Duration(hours: 168); // 7 gün = 168 saat

    if (elapsed >= totalDuration) {
      _remainingTime = Duration.zero;
      print('⏰ [ActigimDavaCard] Süre doldu! (İlelebet Bitti)');
    } else {
      _remainingTime = totalDuration - elapsed;
      final hours = _remainingTime!.inHours;
      final minutes = _remainingTime!.inMinutes % 60;
      print('⏰ [ActigimDavaCard] Geri sayım başlatıldı: $hours saat $minutes dakika kaldı');
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

  /// Konsensus değerlendirmesini yükle
  Future<void> _loadConsensusEvaluation() async {
    if (widget.dava.id.isEmpty) return;

    setState(() {
      _isLoadingConsensus = true;
    });

    try {
      // openedAt tarihini al
      final openedDavalar = HiveDatabaseService.getOpenedDavalar();
      final davaData = openedDavalar.firstWhere(
        (d) => d['id'] == widget.dava.id,
        orElse: () => {},
      );

      final openedAtStr = davaData['openedAt'] as String?;
      DateTime? openedAt;
      if (openedAtStr != null && openedAtStr.isNotEmpty) {
        openedAt = DateTime.tryParse(openedAtStr);
      }

      // Debug: Konsensus yükleme bilgilerini yazdır
      print('🔍 [ActigimDavaCard] Konsensus yükleniyor...');
      print('   - Dava ID: ${widget.dava.id}');
      print('   - OpenedAt: $openedAtStr');
      print('   - Parsed DateTime: $openedAt');

      final evaluation = await DavaConsensusService.evaluateConsensus(
        davaId: widget.dava.id,
        openedAt: openedAt,
      );

      // Debug: Konsensus sonuçlarını yazdır
      print('✅ [ActigimDavaCard] Konsensus yüklendi:');
      print('   - Olumlu: ${evaluation.positiveCount}');
      print('   - Olumsuz: ${evaluation.negativeCount}');
      print('   - Toplam: ${evaluation.totalVotes}');
      print('   - Karar: ${evaluation.verdictLabel}');
      print('   - Kalan Süre: ${evaluation.remainingLabel ?? "Süre doldu"}');

      if (mounted) {
        setState(() {
          _consensusEvaluation = evaluation;
          _isLoadingConsensus = false;
        });
      }
    } catch (e) {
      print('❌ [ActigimDavaCard] Konsensus yüklenirken hata: $e');
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

  /// Hüküm durumunu al
  String _getHukumStatus() {
    if (_isLoadingConsensus) return 'Yükleniyor...';
    
    // Öncelik sırası: 1) Yargıç Kararı, 2) Temyiz Hakimi Kararı, 3) Consensus (Çoğunluk)
    // Rol adlarını normalize ederek kontrol et
    final normalizedYargic = _normalizeRole('Yargıç Kararı');
    final normalizedTemyiz = _normalizeRole('Temyiz Hakimi Kararı');
    
    bool hasYargicKarari = _rolHukumleri.containsKey(normalizedYargic);
    bool hasTemyizHakimiKarari = _rolHukumleri.containsKey(normalizedTemyiz);
    
    // 1. Yargıç Kararı varsa → Yargıç'ın sentiment'ine göre
    if (hasYargicKarari) {
      final sentiment = _rolSentimentleri[normalizedYargic];
      if (sentiment != null) {
        // Sentiment'e göre belirle
        if (sentiment == HukumSentiment.positive) {
          // Davacı haklı - 72 saat kontrolü yap
          if (_shouldShowUzlasma()) {
            return 'UZLAŞMA';
          }
          return 'Haklı Davacı';
        } else if (sentiment == HukumSentiment.negative) {
          return 'Haksız Davacı';
        }
      }
    }
    
    // 2. Temyiz Hakimi Kararı varsa → Temyiz Hakimi'nin sentiment'ine göre
    if (hasTemyizHakimiKarari) {
      final sentiment = _rolSentimentleri[normalizedTemyiz];
      if (sentiment != null) {
        // Sentiment'e göre belirle
        if (sentiment == HukumSentiment.positive) {
          // Davacı haklı - 72 saat kontrolü yap
          if (_shouldShowUzlasma()) {
            return 'UZLAŞMA';
          }
          return 'Haklı Davacı';
        } else if (sentiment == HukumSentiment.negative) {
          return 'Haksız Davacı';
        }
      }
    }
    
    // 3. Consensus (Çoğunluğun verdiği ortak karar)
    if (_consensusEvaluation == null) return 'Beklemede';

    // Eğer hiç hüküm yoksa
    if (_consensusEvaluation!.totalVotes == 0) {
      return 'Beklemede';
    }

    // Consensus'a göre belirle
    // positiveCount = davalı haksız (Haklı Davacı)
    // negativeCount = davacı haksız (Haklı Davalı)
    if (_consensusEvaluation!.positiveCount > _consensusEvaluation!.negativeCount) {
      // Davacı haklı - 72 saat kontrolü yap
      if (_shouldShowUzlasma()) {
        return 'UZLAŞMA';
      }
      return 'Haklı Davacı';
    } else if (_consensusEvaluation!.negativeCount > _consensusEvaluation!.positiveCount) {
      return 'Haksız Davacı';
    } else {
      // Eşitlik durumu
      return 'Beklemede';
    }
  }

  /// 72 saat geçti mi ve ceza/masraf onaylanmadı mı kontrolü (UZLAŞMA durumu için)
  bool _shouldShowUzlasma() {
    // Davacı haklı olmalı (Yargıç, Temyiz Hakimi veya Consensus'a göre)
    bool davaciHakli = false;
    
    // Önce Yargıç kararını kontrol et
    final normalizedYargic = _normalizeRole('Yargıç Kararı');
    if (_rolHukumleri.containsKey(normalizedYargic)) {
      final sentiment = _rolSentimentleri[normalizedYargic];
      if (sentiment == HukumSentiment.positive) {
        davaciHakli = true;
      }
    } else {
      // Temyiz Hakimi kararını kontrol et
      final normalizedTemyiz = _normalizeRole('Temyiz Hakimi Kararı');
      if (_rolHukumleri.containsKey(normalizedTemyiz)) {
        final sentiment = _rolSentimentleri[normalizedTemyiz];
        if (sentiment == HukumSentiment.positive) {
          davaciHakli = true;
        }
      } else {
        // Consensus'a göre kontrol et
        davaciHakli = _isDavaciHakli();
      }
    }
    
    if (!davaciHakli) return false;
    
    // Ceza veya masraf onaylanmışsa UZLAŞMA değil
    if (_cezaOnaylandi || _masrafOnaylandi) return false;
    
    // 72 saat geçmiş mi kontrol et
    try {
      final openedDavalar = HiveDatabaseService.getOpenedDavalar();
      final davaData = openedDavalar.firstWhere(
        (d) => d['id'] == widget.dava.id,
        orElse: () => {},
      );
      
      final openedAtStr = davaData['openedAt'] as String?;
      if (openedAtStr == null || openedAtStr.isEmpty) {
        return false; // Tarih yoksa UZLAŞMA gösterme
      }
      
      final openedAt = DateTime.tryParse(openedAtStr);
      if (openedAt == null) {
        return false; // Parse edilemezse UZLAŞMA gösterme
      }
      
      final now = DateTime.now();
      final elapsed = now.difference(openedAt);
      const seventyTwoHours = Duration(hours: 72);
      
      // 72 saat geçmişse UZLAŞMA göster
      return elapsed >= seventyTwoHours;
    } catch (e) {
      print('⚠️ [ActigimDavaCard] UZLAŞMA kontrolü sırasında hata: $e');
      return false;
    }
  }

  /// Hüküm durumu rengini al
  Color _getHukumStatusColor() {
    final status = _getHukumStatus();
    switch (status) {
      case 'Haklı Davacı':
        return Colors.green.shade700;
      case 'Haksız Davacı':
        return Colors.red.shade700;
      case 'UZLAŞMA':
        return Colors.purple.shade700;
      case 'Beklemede':
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ı dinle - hüküm verileri güncellendiğinde otomatik yenile
    return Consumer<DavaProvider>(
      builder: (context, davaProvider, child) {
        // Provider değiştiğinde hüküm verilerini yeniden yükle
        // Performans için: Sadece hüküm versiyonu değiştiğinde yükle
        final currentVersion = davaProvider.hukumUpdateVersion;
        
        // Debug: Versiyon değişikliğini logla
        if (_lastHukumUpdateVersion != currentVersion) {
          print('🔄 [ActigimDavaCard] Provider versiyonu değişti: $_lastHukumUpdateVersion -> $currentVersion');
        }
        
        if (_lastHukumUpdateVersion != currentVersion && mounted) {
          _lastHukumUpdateVersion = currentVersion;
          print('✅ [ActigimDavaCard] Hükümler yeniden yüklenecek (versiyon: $currentVersion)');
          
          // Async olarak yükle - build metodunu bloklamamak için
          // ÖNEMLİ: Bu callback içinde setState() çağrılacak, bu yüzden widget rebuild olacak
          Future.microtask(() async {
            if (mounted) {
              print('🔄 [ActigimDavaCard] Veriler yükleniyor... (versiyon: $currentVersion)');
              await _loadExistingHukumler();
              await _loadYargicCezaVeMasraf(); // Ceza ve masraf bilgilerini de yeniden yükle
              print('✅ [ActigimDavaCard] Veriler yüklendi, widget rebuild olacak');
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
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.blue.withOpacity(0.02),
                    ],
                  ),
                ),
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
                            // Başlık satırı - Dava Adı ve Durum
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.gavel,
                                          size: 20,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.dava.adi,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Durum badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.dava.isOpened
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: widget.dava.isOpened
                                          ? Colors.green
                                          : Colors.orange,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.dava.isOpened
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        size: 16,
                                        color: widget.dava.isOpened
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.dava.isOpened ? 'Aktif' : 'Beklemede',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: widget.dava.isOpened
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Bilgi kartları - Grid yapısı
                            Row(
                              children: [
                                // Davacı (Tıklanabilir - Hediye dialog'u için)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showHediyeDialog('davaci'),
                                  child: _buildInfoCard(
                                    icon: Icons.person,
                                    label: 'Davacı',
                                    value: widget.dava.davaci.isNotEmpty
                                        ? widget.dava.davaci
                                        : 'Bilinmeyen Yargıç',
                                    color: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Davalı (Tıklanabilir - Hediye dialog'u için)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showHediyeDialog('davali'),
                                  child: _buildInfoCard(
                                    icon: Icons.person_outline,
                                    label: 'Davalı',
                                    value: widget.dava.davali,
                                    color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Ceza ve Masraf butonları (sadece yargıç kararı varsa ve davacı haklı/haksız durumuna göre)
                            if (_shouldShowCezaMasrafButtons())
                            Row(
                              children: [
                                  // Ceza Butonu (Davacı haklıysa "Kabul Et", haksızsa "Onayla")
                                Expanded(
                                  child: _buildCezaOnaylaButton(),
                                ),
                                const SizedBox(width: 8),
                                  // Masraf Butonu (Davacı haklıysa "Kabul Et", haksızsa "Onayla")
                                Expanded(
                                  child: _buildMasrafOnaylaButton(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Görev - Her zaman "Davacı"
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.work,
                                    label: 'Görev',
                                    value: 'Davacı',
                                    color: Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Hüküm Durumu
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.balance,
                                    label: 'Hüküm',
                                    value: _getHukumStatus(),
                                    color: _getHukumStatusColor(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Kalan Süre - Büyük ve vurgulu
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _remainingTime == Duration.zero
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _remainingTime == Duration.zero
                                      ? Colors.red
                                      : Colors.orange,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _remainingTime == Duration.zero
                                        ? Icons.timer_off
                                        : MdiIcons.timerAlertOutline,
                                    size: 24,
                                    color: _remainingTime == Duration.zero
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kalan Süre',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getRemainingTimeText(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _remainingTime == Duration.zero
                                                ? Colors.red.shade700
                                                : Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Dava Açılış Tarihi
                            if (widget.dava.isOpened) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dava Açılış Tarihi:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.dava.kalanSure,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Genişletme/daraltma butonu
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.05),
                            Colors.blue.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.blue.withOpacity(0.1),
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
                          // Detaylar açıldığında verileri yeniden yükle (senkronizasyon için)
                          // Performans: Sadece detaylar açılırken refresh yap (kapanırken yapma)
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
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isExpanded ? 'Detayları Gizle' : 'Detayları Göster',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withOpacity(0.02),
                              Colors.blue.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dava Konusu
                            if (widget.dava.davaKonusu.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
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
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Dava Konusu',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.dava.davaKonusu,
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

                            // Rol Kartları Bölümü
                            _buildRoleCardsSection(),
                            const SizedBox(height: 16),

                            // Deliller Bölümü (Kaldırıldı - sadece okunabilir mod)
                            // if (_deliller.isNotEmpty) ...[
                            //   _buildEvidencesSection(),
                            //   const SizedBox(height: 16),
                            // ],

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
                                      'ID: ${widget.dava.id}',
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
      }, // AnimatedBuilder builder callback kapanışı
    ); // AnimatedBuilder widget kapanışı
      }, // Consumer builder callback kapanışı
    ); // Consumer widget kapanışı
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // MaterialColor ise shade700 kullan, değilse direkt color kullan
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
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: displayColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVoteInfo(String label, int count, Color color) {
    // MaterialColor ise shade700 kullan, değilse direkt color kullan
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

  /// Mevcut hükümleri yükle (Provider üzerinden - senkronizasyon için)
  Future<void> _loadExistingHukumler() async {
    if (widget.dava.id.isEmpty) {
      print('❌ [ActigimDavaCard] Dava ID boş!');
      return;
    }

    print('🔍 [ActigimDavaCard] ========== HÜKÜMLER YÜKLENİYOR ==========');
    print('   - Dava ID: "${widget.dava.id}"');
    print('   - Dava Adı: "${widget.dava.adi}"');
    print('   - Mevcut versiyon: $_lastHukumUpdateVersion');
    print('   - Alternatif ID (hash): "dava_${widget.dava.adi.hashCode}"');

    try {
      // Provider üzerinden hükümleri yükle (senkronizasyon için)
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      Map<String, Map<String, dynamic>> existing = await davaProvider.getHukumlerByDavaId(widget.dava.id, davaAdi: widget.dava.adi);
      
      // Eğer Provider'dan bulunamazsa, doğrudan Hive'dan yükle (geriye dönük uyumluluk)
      if (existing.isEmpty) {
        existing = await HiveDatabaseService.getHukumlerByDavaIdGrouped(widget.dava.id, davaAdi: widget.dava.adi);
      }
      
      // Eğer bulunamazsa, alternatif ID formatını dene (modern_hukum_card.dart'da kullanılan format)
      if (existing.isEmpty && widget.dava.adi.isNotEmpty) {
        final alternativeId = 'dava_${widget.dava.adi.hashCode}';
        print('   ⚠️ Gerçek ID ile bulunamadı, alternatif ID deneniyor: "$alternativeId"');
        existing = await HiveDatabaseService.getHukumlerByDavaIdGrouped(alternativeId);
        if (existing.isNotEmpty) {
          print('   ✅ Alternatif ID ile bulundu!');
        }
      }

      if (!mounted) {
        print('⚠️ [ActigimDavaCard] Widget unmounted, yükleme iptal edildi');
        return;
      }

      // Debug: Veritabanından gelen verileri yazdır
      print('🔍 [ActigimDavaCard] Veritabanından gelen hükümler (${existing.length} adet):');
      if (existing.isEmpty) {
        print('   ⚠️ Hiç hüküm bulunamadı!');
        print('   💡 Kontrol edilmesi gerekenler:');
        print('      - Dava ID doğru mu? "${widget.dava.id}"');
        print('      - Hüküm kaydedilirken hangi ID kullanıldı?');
        
        // Eğer gerçek ID ile bulunamadıysa, dava adının hash'ini kullanarak ara
        if (existing.isEmpty && widget.dava.adi.isNotEmpty) {
          try {
            // Veritabanındaki tüm key'leri al
            final allKeys = await HiveDatabaseService.getAllHukumKeys(limit: 100);
            
            // Dava adının hash'ini hesapla (farklı formatlar için)
            final davaAdiHash = widget.dava.adi.hashCode;
            final davaAdiHashWithoutComma = widget.dava.adi.replaceAll(',', '').trim().hashCode;
            final davaAdiHashClean = widget.dava.adi.replaceAll(RegExp(r'[^\w\s]'), '').trim().hashCode;
            
            print('   🔍 Dava adı hash\'leri:');
            print('      - Orijinal: $davaAdiHash');
            print('      - Virgülsüz: $davaAdiHashWithoutComma');
            print('      - Temizlenmiş: $davaAdiHashClean');
            
            // Key'lerden dava ID'sini çıkar ve hash'leri karşılaştır
            String? matchedDavaId;
            for (final key in allKeys) {
              // Key formatı: "davaId_userRole"
              final parts = key.split('_');
              if (parts.length >= 2) {
                final extractedDavaId = parts.sublist(0, parts.length - 1).join('_');
                
                // Eğer dava ID'si "dava_" ile başlıyorsa, hash'i çıkar
                if (extractedDavaId.startsWith('dava_')) {
                  final hashStr = extractedDavaId.replaceFirst('dava_', '');
                  final hash = int.tryParse(hashStr);
                  
                  if (hash != null && 
                      (hash == davaAdiHash || 
                       hash == davaAdiHashWithoutComma || 
                       hash == davaAdiHashClean)) {
                    print('   ✅ Hash eşleşmesi bulundu! Key: "$key", Dava ID: "$extractedDavaId"');
                    matchedDavaId = extractedDavaId;
                    break;
                  }
                }
              }
            }
            
            // Eşleşen ID ile hükümleri yükle
            if (matchedDavaId != null) {
              final testResult = await HiveDatabaseService.getHukumlerByDavaIdGrouped(matchedDavaId);
              if (testResult.isNotEmpty) {
                print('   ✅ "$matchedDavaId" ile ${testResult.length} hüküm bulundu!');
                existing = testResult;
              }
            }
            
            // Hala bulunamadıysa, olası ID formatlarını dene
            if (existing.isEmpty) {
              final possibleIds = <String>[
                widget.dava.id,
                if (widget.dava.adi.isNotEmpty) 'dava_${widget.dava.adi.hashCode}',
                // Dava adından virgülü kaldırıp tekrar dene
                if (widget.dava.adi.isNotEmpty) 'dava_${widget.dava.adi.replaceAll(',', '').trim().hashCode}',
                // Dava adından tüm noktalama işaretlerini kaldırıp tekrar dene
                if (widget.dava.adi.isNotEmpty) 'dava_${widget.dava.adi.replaceAll(RegExp(r'[^\w\s]'), '').trim().hashCode}',
              ];
              
              print('   🔍 Olası ID formatları deneniyor:');
              for (final possibleId in possibleIds) {
                if (possibleId.isEmpty) continue;
                final testResult = await HiveDatabaseService.getHukumlerByDavaIdGrouped(possibleId);
                if (testResult.isNotEmpty) {
                  print('   ✅ "$possibleId" ile ${testResult.length} hüküm bulundu!');
                  existing = testResult;
                  break;
                }
              }
            }
          } catch (e) {
            print('   ❌ Hash eşleştirme sırasında hata: $e');
          }
        }
      }
      
      if (existing.isNotEmpty) {
        for (final entry in existing.entries) {
          print('   - Key: "${entry.key}"');
          final hukumTextStr = entry.value['hukumText']?.toString() ?? '';
          final preview = hukumTextStr.length > 50 ? hukumTextStr.substring(0, 50) : hukumTextStr;
          print('   - Hüküm: $preview...');
          print('   - UserEmail: ${entry.value['userEmail']}');
          print('   - CreatedAt: ${entry.value['createdAt']}');
        }
      }

      print('✅ [ActigimDavaCard] ${existing.length} hüküm bulundu, setState() çağrılıyor...');

      setState(() {
        // Hüküm metinlerini yükle (key'ler zaten normalize edilmiş - getHukumlerByDavaIdGrouped'den geliyor)
        _rolHukumleri.clear();
        _rolHukumleri.addEntries(existing.entries.where((entry) {
          final dynamic text = entry.value['hukumText'];
          return (text is String) && text.trim().isNotEmpty;
        }).map((entry) {
          // Key zaten normalize edilmiş (modern_hukum_card.dart'ta normalize edilmiş olarak kaydediliyor)
          // Ama yine de normalize edelim ki tutarlı olsun (eğer eski veriler varsa)
          final String normalizedKey = _normalizeRole(entry.key);
          print('   ✅ Key: "${entry.key}" -> Normalize: "$normalizedKey"');
          print('   🔍 [ActigimDavaCard] Hüküm yükleniyor: "$normalizedKey" = "${entry.value['hukumText'].toString().substring(0, entry.value['hukumText'].toString().length > 30 ? 30 : entry.value['hukumText'].toString().length)}..."');
          return MapEntry(
            normalizedKey,
            entry.value['hukumText'].toString(),
          );
        }));
        
        print('🔍 [ActigimDavaCard] Yüklenen hüküm sayısı: ${_rolHukumleri.length}');
        print('🔍 [ActigimDavaCard] Hüküm key\'leri: ${_rolHukumleri.keys.toList()}');

        // Debug: Normalize edilmiş map'i yazdır
        print('🔍 [ActigimDavaCard] Normalize edilmiş hükümler:');
        for (final entry in _rolHukumleri.entries) {
          print('   - Key: "${entry.key}"');
          print('   - Hüküm: ${entry.value.substring(0, entry.value.length > 50 ? 50 : entry.value.length)}...');
        }

        // Sentiment'leri yükle (normalize edilmiş key'ler ile)
        _rolSentimentleri.clear();
        print('🔍 [ActigimDavaCard] Sentimentler yükleniyor...');
        for (final entry in existing.entries) {
          final String? sentimentValue = entry.value['hukumSentiment'] as String?;
          final HukumSentiment? sentiment = hukumSentimentFromStorage(sentimentValue);
          
          // Veritabanından gelen rol adını normalize et (modern_hukum_card.dart ile senkronize)
          final String normalizedKey = _normalizeRole(entry.key);
          
          if (sentiment != null) {
            _rolSentimentleri[normalizedKey] = sentiment;
            print('   ✅ Sentiment yüklendi: "$normalizedKey" -> ${sentiment.storageValue}');
          } else {
            print('   ⚠️ Sentiment bulunamadı: "$normalizedKey" (value: $sentimentValue)');
          }
        }
        print('🔍 [ActigimDavaCard] Toplam ${_rolSentimentleri.length} sentiment yüklendi');

        // Finalizasyon durumlarını yükle (normalize edilmiş key'ler ile)
        _rolFinalizasyonlari.clear();
        _rolFinalizasyonlari.addEntries(existing.entries.map((entry) {
          // Veritabanından gelen rol adını normalize et (modern_hukum_card.dart ile senkronize)
          final String normalizedKey = _normalizeRole(entry.key);
          return MapEntry(
            normalizedKey,
            (entry.value['isFinalized'] as bool?) ?? false,
          );
        }));

        // Kullanıcı email'lerini yükle (normalize edilmiş key'ler ile)
        _rolUserEmails.clear();
        _rolUserEmails.addEntries(existing.entries.map((entry) {
          // Veritabanından gelen rol adını normalize et (modern_hukum_card.dart ile senkronize)
          final String normalizedKey = _normalizeRole(entry.key);
          return MapEntry(
            normalizedKey,
            entry.value['userEmail']?.toString() ?? '',
          );
        }));

        // Oluşturulma tarihlerini yükle (normalize edilmiş key'ler ile)
        _rolCreatedAts.clear();
        _rolCreatedAts.addEntries(existing.entries.map((entry) {
          // Veritabanından gelen rol adını normalize et (modern_hukum_card.dart ile senkronize)
          final String normalizedKey = _normalizeRole(entry.key);
          return MapEntry(
            normalizedKey,
            entry.value['createdAt']?.toString() ?? '',
          );
        }));
        
        print('✅ [ActigimDavaCard] setState() tamamlandı!');
        print('   - Yüklenen hüküm sayısı: ${_rolHukumleri.length}');
        print('   - Yüklenen sentiment sayısı: ${_rolSentimentleri.length}');
        print('🔍 [ActigimDavaCard] ========== HÜKÜMLER YÜKLEME TAMAMLANDI ==========');
      });
    } catch (e) {
      print('❌ [ActigimDavaCard] Hükümler yüklenirken hata: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Delilleri yükle (KALDIRILDI - Sadece okunabilir mod)
  // ignore: unused_element
  Future<void> _loadEvidences() async {
    if (widget.dava.id.isEmpty) return;

    try {
      await _evidenceService.initialize();
      final evidences = _evidenceService.getEvidenceByDavaId(widget.dava.id);

      if (mounted) {
        setState(() {
          _deliller = evidences;
        });
      }
    } catch (e) {
      print('❌ [ActigimDavaCard] Deliller yüklenirken hata: $e');
    }
  }

  /// Rol adını normalize et
  String _normalizeRole(String rolAdi) {
    final String trimmed = rolAdi.trim();
    if (trimmed.isEmpty) {
      return 'Görev Kararı';
    }
    return trimmed.endsWith('Kararı') ? trimmed : '$trimmed Kararı';
  }

  /// Yargıç veya Temyiz Hakimi'nin ceza ve masraf bilgilerini yükle
  Future<void> _loadYargicCezaVeMasraf() async {
    if (widget.dava.id.isEmpty) {
      print('❌ [ActigimDavaCard] Dava ID boş, ceza/masraf yüklenemiyor!');
      return;
    }

    print('🔍 [ActigimDavaCard] Ceza/Masraf yükleniyor...');
    print('   - Dava ID: "${widget.dava.id}"');
    print('   - Dava Adı: "${widget.dava.adi}"');

    try {
      // Önce gerçek dava ID'si ile dene
      String davaIdToUse = widget.dava.id;
      
      // Yargıç veya Temyiz Hakimi kararını kontrol et
      print('   🔍 Yargıç Kararı aranıyor (davaId: $davaIdToUse)...');
      Map<String, dynamic>? yargicKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
        davaIdToUse,
        'Yargıç Kararı',
        davaAdi: widget.dava.adi,
      );
      
      // Eğer bulunamazsa, alternatif ID formatını dene (geriye dönük uyumluluk için)
      if (yargicKarari == null && widget.dava.adi.isNotEmpty) {
        final alternativeId = 'dava_${widget.dava.adi.hashCode}';
        print('   ⚠️ Gerçek ID ile bulunamadı, alternatif ID deneniyor: "$alternativeId"');
        yargicKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
          alternativeId,
          'Yargıç Kararı',
          davaAdi: widget.dava.adi,
        );
        if (yargicKarari != null) {
          davaIdToUse = alternativeId;
          print('   ✅ Alternatif ID ile Yargıç Kararı bulundu!');
        }
      }
      print('   ${yargicKarari != null ? "✅" : "❌"} Yargıç Kararı: ${yargicKarari != null ? "Bulundu" : "Bulunamadı"}');
      
      print('   🔍 Temyiz Hakimi Kararı aranıyor (davaId: $davaIdToUse)...');
      Map<String, dynamic>? temyizKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
        davaIdToUse,
        'Temyiz Hakimi Kararı',
        davaAdi: widget.dava.adi,
      );
      
      // Eğer bulunamazsa, alternatif ID formatını dene (geriye dönük uyumluluk için)
      if (temyizKarari == null && widget.dava.adi.isNotEmpty && davaIdToUse == widget.dava.id) {
        final alternativeId = 'dava_${widget.dava.adi.hashCode}';
        print('   ⚠️ Gerçek ID ile bulunamadı, alternatif ID deneniyor: "$alternativeId"');
        temyizKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
          alternativeId,
          'Temyiz Hakimi Kararı',
          davaAdi: widget.dava.adi,
        );
        if (temyizKarari != null) {
          davaIdToUse = alternativeId;
          print('   ✅ Alternatif ID ile Temyiz Hakimi Kararı bulundu!');
        }
      }
      print('   ${temyizKarari != null ? "✅" : "❌"} Temyiz Hakimi Kararı: ${temyizKarari != null ? "Bulundu" : "Bulunamadı"}');

      // En son verilen kararı al (Temyiz Hakimi öncelikli)
      // isFinalized kontrolünü kaldırdık - herhangi bir karar varsa ceza/masraf yüklenecek
      final Map<String, dynamic>? sonKarar;
      if (temyizKarari != null) {
        sonKarar = temyizKarari;
      } else if (yargicKarari != null) {
        sonKarar = yargicKarari;
      } else {
        sonKarar = null;
      }

      if (sonKarar != null) {
        final String userEmail = sonKarar['userEmail']?.toString() ?? '';
        print('   ✅ Karar bulundu!');
        print('   - UserEmail: $userEmail');
        print('   - Karar Rolü: ${sonKarar['userRole']}');
        print('   - IsFinalized: ${sonKarar['isFinalized']}');
        
        if (mounted) {
          // Ceza bilgisini al (bulunan dava ID'si ile)
          print('   🔍 Ceza aranıyor (davaId: $davaIdToUse, userEmail: $userEmail)...');
          String? cezaText = await HiveDatabaseService.getCeza(
            davaId: davaIdToUse,
            userEmail: userEmail,
          );
          
          // Eğer bulunamazsa, alternatif ID ile dene
          if (cezaText == null && davaIdToUse == widget.dava.id && widget.dava.adi.isNotEmpty) {
            final alternativeId = 'dava_${widget.dava.adi.hashCode}';
            print('   ⚠️ Gerçek ID ile ceza bulunamadı, alternatif ID deneniyor: "$alternativeId"');
            cezaText = await HiveDatabaseService.getCeza(
              davaId: alternativeId,
              userEmail: userEmail,
            );
            if (cezaText != null) {
              print('   ✅ Alternatif ID ile ceza bulundu!');
            }
          }
          print('   ${cezaText != null ? "✅" : "❌"} Ceza: ${cezaText ?? "Bulunamadı"}');
          
          // Masraf bilgilerini al (bulunan dava ID'si ile)
          print('   🔍 Masraf aranıyor (davaId: $davaIdToUse, userEmail: $userEmail)...');
          List<String>? masraflar = await HiveDatabaseService.getMasrafExpenses(
            davaId: davaIdToUse,
            userEmail: userEmail,
          );
          
          // Eğer bulunamazsa, alternatif ID ile dene
          if (masraflar == null && davaIdToUse == widget.dava.id && widget.dava.adi.isNotEmpty) {
            final alternativeId = 'dava_${widget.dava.adi.hashCode}';
            print('   ⚠️ Gerçek ID ile masraf bulunamadı, alternatif ID deneniyor: "$alternativeId"');
            masraflar = await HiveDatabaseService.getMasrafExpenses(
              davaId: alternativeId,
              userEmail: userEmail,
            );
            if (masraflar != null) {
              print('   ✅ Alternatif ID ile masraf bulundu!');
            }
          }
          print('   ${masraflar != null ? "✅" : "❌"} Masraf: ${masraflar?.length ?? 0} adet');
          
          if (mounted) {
            setState(() {
              _yargicCezaText = cezaText;
              _yargicMasraflar = masraflar;
            });
            
            print('✅ [ActigimDavaCard] Ceza/Masraf state güncellendi:');
            print('   - Ceza: ${cezaText ?? "Yok"}');
            print('   - Masraf: ${masraflar?.length ?? 0} adet');
          }
        }
      } else {
        print('   ❌ Karar bulunamadı!');
        // Karar yoksa ceza ve masraf bilgilerini temizle
        if (mounted) {
          setState(() {
            _yargicCezaText = null;
            _yargicMasraflar = null;
          });
        }
      }
    } catch (e) {
      print('❌ [ActigimDavaCard] Yargıç ceza/masraf yüklenirken hata: $e');
    }
  }

  /// Davacının haklı olup olmadığını kontrol eder
  bool _isDavaciHakli() {
    if (_consensusEvaluation == null) return false;
    // positiveCount = davalı haksız (Haklı Davacı)
    // negativeCount = davacı haksız (Haklı Davalı)
    return _consensusEvaluation!.positiveCount > _consensusEvaluation!.negativeCount;
  }

  /// Ceza ve Masraf butonlarının gösterilip gösterilmeyeceğini belirler
  bool _shouldShowCezaMasrafButtons() {
    // Sadece yargıç kararı varsa ve ceza/masraf belirlenmişse göster
    final bool hasYargicKarari = _rolHukumleri.containsKey('Yargıç Kararı') || 
                                  _rolHukumleri.containsKey('yargıç kararı');
    final bool hasCezaOrMasraf = (_yargicCezaText != null && _yargicCezaText!.isNotEmpty) ||
                                  (_yargicMasraflar != null && _yargicMasraflar!.isNotEmpty);
    return hasYargicKarari && hasCezaOrMasraf;
  }

  /// Cezanı Onayla/Kabul Et butonunu oluşturur (Oyunsal ve Animasyonlu)
  Widget _buildCezaOnaylaButton() {
    final bool hasCeza = _yargicCezaText != null && _yargicCezaText!.isNotEmpty;
    final bool isEnabled = hasCeza && !_cezaOnaylandi;
    final bool davaciHakli = _isDavaciHakli();
    final String buttonText = davaciHakli 
        ? (_cezaOnaylandi ? 'Ceza Kabul Edildi ✅' : 'CEZANI KABUL ET')
        : (_cezaOnaylandi ? 'Ceza Onaylandı ✅' : 'CEZASINI ONAYLA');

    // Animasyon controller'ları yoksa basit widget döndür
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
            color: isEnabled
                      ? Colors.red.shade300
                : Colors.grey.withOpacity(0.3),
                  width: isEnabled ? 2.5 : 1,
                ),
                boxShadow: isEnabled && _cezaGlowAnimation != null
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(_cezaGlowAnimation!.value),
                          blurRadius: 20 * _cezaGlowAnimation!.value,
                          spreadRadius: 5 * _cezaGlowAnimation!.value,
                        ),
                        BoxShadow(
                          color: Colors.red.shade300.withOpacity(_cezaGlowAnimation!.value * 0.5),
                          blurRadius: 30 * _cezaGlowAnimation!.value,
                          spreadRadius: 8 * _cezaGlowAnimation!.value,
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
                          color: isEnabled
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                  MdiIcons.handcuffs,
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
                      shadows: isEnabled
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEnabled
                              ? (hasCeza ? Icons.check_circle : Icons.access_time)
                              : Icons.block,
                          size: 16,
                          color: isEnabled
                              ? (hasCeza ? Colors.white : Colors.white70)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
              hasCeza
                                ? (_yargicCezaText!.length > 25
                                    ? '${_yargicCezaText!.substring(0, 25)}...'
                      : _yargicCezaText!)
                  : (_cezaOnaylandi ? 'Onaylandı' : 'Ceza bekleniyor'),
              style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isEnabled ? Colors.white : Colors.grey.shade600,
                              shadows: isEnabled
                                  ? [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0.5, 0.5),
                                      ),
                                    ]
                                  : null,
                            ),
                            maxLines: 2,
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
        );
      },
    );
  }

  /// Masrafları Onayla/Kabul Et butonunu oluşturur (Oyunsal ve Animasyonlu)
  Widget _buildMasrafOnaylaButton() {
    final bool hasMasraf = _yargicMasraflar != null && _yargicMasraflar!.isNotEmpty;
    final bool isEnabled = hasMasraf && !_masrafOnaylandi;
    final bool davaciHakli = _isDavaciHakli();
    final String buttonText = davaciHakli
        ? (_masrafOnaylandi ? 'Masraf Kabul Edildi ✅' : 'MASRAFLARI KABUL ET')
        : (_masrafOnaylandi ? 'Masraf Onaylandı ✅' : 'MASRAFLARI ONAYLA');

    // Animasyon controller'ları yoksa basit widget döndür
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
            color: isEnabled
                      ? Colors.purple.shade300
                : Colors.grey.withOpacity(0.3),
                  width: isEnabled ? 2.5 : 1,
                ),
                boxShadow: isEnabled && _masrafGlowAnimation != null
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(_masrafGlowAnimation!.value),
                          blurRadius: 20 * _masrafGlowAnimation!.value,
                          spreadRadius: 5 * _masrafGlowAnimation!.value,
                        ),
                        BoxShadow(
                          color: Colors.purple.shade300.withOpacity(_masrafGlowAnimation!.value * 0.5),
                          blurRadius: 30 * _masrafGlowAnimation!.value,
                          spreadRadius: 8 * _masrafGlowAnimation!.value,
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
                          color: isEnabled
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
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
                      shadows: isEnabled
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEnabled
                              ? (hasMasraf ? Icons.check_circle : Icons.access_time)
                              : Icons.block,
                  size: 16,
                          color: isEnabled
                              ? (hasMasraf ? Colors.white : Colors.white70)
                              : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasMasraf
                                ? '${_yargicMasraflar!.length} masraf seçildi'
                                : (_masrafOnaylandi ? 'Onaylandı' : 'Masraf bekleniyor'),
                  style: TextStyle(
                              fontSize: 12,
                    fontWeight: FontWeight.w600,
                              color: isEnabled ? Colors.white : Colors.grey.shade600,
                              shadows: isEnabled
                                  ? [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0.5, 0.5),
                                      ),
                                    ]
                                  : null,
                            ),
                            maxLines: 2,
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
        );
      },
    );
  }

  /// Basit ceza butonu (animasyon controller'ları yoksa)
  Widget _buildSimpleCezaButton(bool hasCeza, bool isEnabled, String buttonText) {
    return GestureDetector(
      onTap: isEnabled ? () => _onCezaOnayla() : null,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    MdiIcons.handcuffs,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isEnabled
                        ? (hasCeza ? Icons.check_circle : Icons.access_time)
                        : Icons.block,
                    size: 16,
                    color: isEnabled
                        ? (hasCeza ? Colors.white : Colors.white70)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasCeza
                          ? (_yargicCezaText!.length > 25
                              ? '${_yargicCezaText!.substring(0, 25)}...'
                              : _yargicCezaText!)
                          : (_cezaOnaylandi ? 'Onaylandı' : 'Ceza bekleniyor'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.white : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isEnabled
                        ? (hasMasraf ? Icons.check_circle : Icons.access_time)
                        : Icons.block,
                    size: 16,
                    color: isEnabled
                        ? (hasMasraf ? Colors.white : Colors.white70)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
              hasMasraf
                  ? '${_yargicMasraflar!.length} masraf seçildi'
                  : (_masrafOnaylandi ? 'Onaylandı' : 'Masraf bekleniyor'),
              style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.white : Colors.grey.shade600,
                      ),
                      maxLines: 2,
              overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
          content: Text('"$_yargicCezaText" cezasını onaylıyor musunuz?'),
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

  /// Rol kartları listesini oluşturur
  Widget _buildRoleCardsSection() {
    final List<Map<String, dynamic>> roles = <Map<String, dynamic>>[
      {'title': 'Temyiz Hakimi Kararı', 'icon': MdiIcons.scaleBalance},
      {'title': 'Yargıç Kararı', 'icon': MdiIcons.gavel},
      {'title': '1. Jüri Kararı', 'icon': MdiIcons.accountGroup},
      {'title': '2. Jüri Kararı', 'icon': MdiIcons.accountMultiple},
      {'title': 'Davacı Avukatı Kararı', 'icon': MdiIcons.accountTie},
      {'title': 'Davalı Avukatı Kararı', 'icon': MdiIcons.accountTieOutline},
      {'title': 'Davacı Şahidi Kararı', 'icon': MdiIcons.account},
      {'title': 'Davalı Şahidi Kararı', 'icon': MdiIcons.accountOutline},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Rol Kararları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rol kartlarını göster - _rolHukumleri map'i güncellendiğinde otomatik rebuild olacak
          Builder(
            builder: (context) {
              // Debug: Mevcut hüküm sayısını logla
              if (_rolHukumleri.isNotEmpty) {
                print('🔍 [ActigimDavaCard] _buildRoleCardsSection: ${_rolHukumleri.length} hüküm var, key\'ler: ${_rolHukumleri.keys.toList()}');
              }
              
              return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: roles.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildRoleCard(
                roles[index]['title'] as String,
                roles[index]['icon'] as IconData,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Tekil rol kartını oluşturur (Sadece okunabilir - sekiz_hukum_page.dart gibi)
  Widget _buildRoleCard(String title, IconData icon) {
    final String normalizedTitle = _normalizeRole(title);
    final String? hukumText = _rolHukumleri[normalizedTitle];
    final bool hasHukum = (hukumText?.trim().isNotEmpty ?? false);
    final HukumSentiment? sentiment = _rolSentimentleri[normalizedTitle];
    
    // Debug: Her build'de rol kartı durumunu kontrol et (sadece hüküm varsa)
    if (hasHukum) {
      print('🔍 [ActigimDavaCard] _buildRoleCard: "$normalizedTitle" -> hasHukum: $hasHukum, sentiment: ${sentiment?.storageValue ?? "null"}');
      print('   📝 Hüküm metni uzunluğu: ${hukumText?.length ?? 0}');
    } else {
      // Debug: Hüküm yoksa da ara sıra log yaz (spam'i önlemek için)
      if (_rolHukumleri.isNotEmpty) {
        print('⚠️ [ActigimDavaCard] _buildRoleCard: "$normalizedTitle" -> hasHukum: false (Mevcut key\'ler: ${_rolHukumleri.keys.toList()})');
      }
    }

    // Trailing widget'ları oluştur (sekiz_hukum_page.dart gibi)
    final List<Widget> trailingWidgets = _buildRoleTrailingWidgets(title, hasHukum, normalizedTitle, sentiment);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasHukum ? Colors.green.shade400 : Colors.blue.shade200,
          width: hasHukum ? 2 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasHukum ? Colors.green.shade700 : Colors.blue.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasHukum ? Colors.green.shade700 : Colors.grey.shade900,
              ),
            ),
          ),
          ...trailingWidgets,
        ],
      ),
    );
  }

  /// Rol satırının sağ tarafındaki ikon alanını oluşturur (sekiz_hukum_page.dart gibi)
  List<Widget> _buildRoleTrailingWidgets(
    String title,
    bool hasHukum,
    String normalizedTitle,
    HukumSentiment? sentiment,
  ) {
    // Debug: Sentiment durumunu kontrol et
    if (hasHukum) {
      print('🔍 [ActigimDavaCard] _buildRoleTrailingWidgets:');
      print('   - Rol: "$normalizedTitle"');
      print('   - HasHukum: $hasHukum');
      print('   - Sentiment: ${sentiment?.storageValue ?? "null"}');
      print('   - _rolSentimentleri keys: ${_rolSentimentleri.keys.toList()}');
    }
    
    // Eğer sentiment seçilmişse, sentiment ikonunu göster
    if (sentiment != null) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: sentiment.color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sentiment.color, width: 1.5),
          ),
          child: Icon(
            sentiment.icon,
            size: 24,
            color: sentiment.color,
          ),
        ),
        const SizedBox(width: 8),
        _buildRoleDialogButton(normalizedTitle, hasHukum),
      ];
    }

    // Sentiment seçilmemişse, varsayılan ikonları göster
    return <Widget>[
      Icon(
        MdiIcons.emoticonHappyOutline,
        size: 24,
        color: Colors.orange,
      ),
      const SizedBox(width: 4),
      Icon(
        MdiIcons.emoticonCryOutline,
        size: 24,
        color: Colors.blue,
      ),
      const SizedBox(width: 4),
      _buildRoleDialogButton(normalizedTitle, hasHukum),
    ];
  }

  /// Rol kartında hükmü görüntüleyen aksiyon ikonunu üretir (Sadece okunabilir)
  Widget _buildRoleDialogButton(String normalizedTitle, bool hasHukum) {
    return GestureDetector(
      onTap: hasHukum ? () => _showHukumDialog(normalizedTitle) : null,
      child: Icon(
        MdiIcons.fileCheckOutline,
        size: 30,
        color: hasHukum ? Colors.green.shade700 : Colors.brown,
      ),
    );
  }

  /// Hüküm giriş dialog'unu göster (KALDIRILDI - Sadece okunabilir mod)
  // ignore: unused_element
  void _showHukumInputDialog(String roleTitle, String normalizedRole) {
    final TextEditingController hukumController = TextEditingController();
    HukumSentiment? selectedSentiment;
    bool isFinalized = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$roleTitle - Hüküm Yaz',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Delilleri göster (nakletme için)
                      if (_deliller.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 18,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delilleri Karara Naklet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._deliller.map((delil) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    final delilText = '${delil.title}: ${delil.description}';
                                    hukumController.text += '\n$delilText';
                                    setDialogState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getEvidenceIcon(delil.type),
                                          size: 16,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            delil.title,
                                            style: const TextStyle(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 16,
                                          color: Colors.orange.shade700,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: hukumController,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Hüküm Metni',
                          hintText: 'Hükmünüzü buraya yazın...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sentiment seçimi
                      Text(
                        'Hüküm Yönü:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedSentiment = HukumSentiment.positive;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedSentiment == HukumSentiment.positive
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedSentiment == HukumSentiment.positive
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      MdiIcons.emoticonHappyOutline,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Olumlu'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedSentiment = HukumSentiment.negative;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedSentiment == HukumSentiment.negative
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedSentiment == HukumSentiment.negative
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      MdiIcons.emoticonCryOutline,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Olumsuz'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Finalize checkbox
                      CheckboxListTile(
                        title: const Text('Hükmü Nihai Hale Getir'),
                        value: isFinalized,
                        onChanged: (value) {
                          setDialogState(() {
                            isFinalized = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Kaydet butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: hukumController.text.trim().isNotEmpty &&
                                  selectedSentiment != null
                              ? () async {
                                  await _saveHukum(
                                    normalizedRole,
                                    hukumController.text,
                                    selectedSentiment!,
                                    isFinalized,
                                  );
                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Hükmü Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Hüküm kaydet (KALDIRILDI - Sadece okunabilir mod)
  // ignore: unused_element
  Future<void> _saveHukum(
    String normalizedRole,
    String hukumText,
    HukumSentiment sentiment,
    bool isFinalized,
  ) async {
    try {
      const prefix = 'whoboom sakinleri adına, gereği düşünüldü: ';
      final fullText = hukumText.startsWith(prefix) ? hukumText : '$prefix$hukumText';

      await HiveDatabaseService.saveHukum(
        davaId: widget.dava.id,
        userRole: normalizedRole,
        hukumText: fullText,
        userEmail: widget.userEmail ?? '',
        hukumSentiment: sentiment.storageValue,
        isFinalized: isFinalized,
      );

      setState(() {
        _rolHukumleri[normalizedRole] = fullText;
        _rolSentimentleri[normalizedRole] = sentiment;
        _rolFinalizasyonlari[normalizedRole] = isFinalized;
      });

      // Konsensus'u yenile
      await _loadConsensusEvaluation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $normalizedRole için hüküm kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [ActigimDavaCard] Hüküm kaydedilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hüküm kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Hüküm dialog'unu göster (sekiz_hukum_page.dart gibi - sadece okunabilir)
  void _showHukumDialog(String normalizedRole) {
    print('🔍 [ActigimDavaCard] Hüküm dialog açılıyor:');
    print('   - Normalize edilmiş rol: "$normalizedRole"');
    print('   - Mevcut hükümler: ${_rolHukumleri.keys.toList()}');
    
    // Önce normalize edilmiş key ile dene
    String? hukumText = _rolHukumleri[normalizedRole];
    
    // Eğer bulunamazsa, alternatif key'leri dene (geriye dönük uyumluluk için)
    if (hukumText == null || hukumText.trim().isEmpty) {
      // "Yargıç Kararı" -> "Yargıç" dene
      final String withoutKarari = normalizedRole.replaceAll(' Kararı', '').trim();
      if (withoutKarari.isNotEmpty && withoutKarari != normalizedRole) {
        hukumText = _rolHukumleri[withoutKarari];
        if (hukumText != null && hukumText.trim().isNotEmpty) {
          print('   ✅ Alternatif key ile bulundu: "$withoutKarari"');
        }
      }
    }
    
    // Hala bulunamazsa, tüm key'leri kontrol et (fuzzy match)
    if (hukumText == null || hukumText.trim().isEmpty) {
      final String searchTerm = normalizedRole.toLowerCase();
      for (final entry in _rolHukumleri.entries) {
        if (entry.key.toLowerCase().contains(searchTerm) || 
            searchTerm.contains(entry.key.toLowerCase())) {
          hukumText = entry.value;
          print('   ✅ Fuzzy match ile bulundu: "${entry.key}"');
          break;
        }
      }
    }
    
    if (hukumText == null || hukumText.trim().isEmpty) {
      print('❌ [ActigimDavaCard] Hüküm bulunamadı veya boş!');
      print('   - Aranan key: "$normalizedRole"');
      print('   - Mevcut keys: ${_rolHukumleri.keys.toList()}');
      
      // Kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hüküm bulunamadı: $normalizedRole'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // hukumText artık null olamaz (yukarıdaki kontrollerden geçti)
    final String finalHukumText = hukumText;
    print('✅ [ActigimDavaCard] Hüküm bulundu: ${finalHukumText.substring(0, finalHukumText.length > 50 ? 50 : finalHukumText.length)}...');

    // Hüküm veren kullanıcı bilgisini al
    // Fuzzy match durumunda doğru key'i bul
    String actualKey = normalizedRole;
    if (!_rolUserEmails.containsKey(normalizedRole)) {
      // Alternatif key'leri dene
      final String withoutKarari = normalizedRole.replaceAll(' Kararı', '').trim();
      if (_rolUserEmails.containsKey(withoutKarari)) {
        actualKey = withoutKarari;
      } else {
        // Fuzzy match ile bulunan key'i kullan
        for (final entry in _rolHukumleri.entries) {
          if (entry.value == finalHukumText) {
            actualKey = entry.key;
            break;
          }
        }
      }
    }
    
    final String userEmail = _rolUserEmails[actualKey] ?? '';
    final String createdAt = _rolCreatedAts[actualKey] ?? '';
    String displayName = 'Bilinmeyen Yargıç';
    
    if (userEmail.isNotEmpty) {
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      displayName = user?.judgeName ?? userEmail.split('@').first;
    }

    // Tarih formatla
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
                                    normalizedRole,
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
                        finalHukumText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
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

  /// Delil ikonunu al
  IconData _getEvidenceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_library;
      case 'text':
        return Icons.text_fields;
      case 'link':
        return Icons.link;
      default:
        return Icons.attach_file;
    }
  }

  /// Hediye dialog'unu göster
  void _showHediyeDialog(String taraf) {
    // HAKLI tarafı belirle
    final bool davaciHakli = _isDavaciHakli();
    final bool hediyeAlinacakKisiDavaci = davaciHakli;
    
    // Sadece HAKLI taraf için dialog göster
    if (taraf == 'davaci' && !hediyeAlinacakKisiDavaci) {
      // Davacı haklı değilse, dialog gösterilmez
      return;
    }
    if (taraf == 'davali' && hediyeAlinacakKisiDavaci) {
      // Davalı haklı değilse, dialog gösterilmez
      return;
    }
    
    // Kullanıcı kontrolü - Sadece hediye alınacak kişi için aktif
    final hediyeAlinacakKisiAdi = hediyeAlinacakKisiDavaci 
        ? widget.dava.davaci 
        : widget.dava.davali;
    
    // Kullanıcı email'ini kontrol et
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return;
    }
    
    // Kullanıcı kontrolü - Sadece hediye alınacak kişi için aktif
    final currentUser = HiveDatabaseService.getRegistrationByEmail(widget.userEmail!);
    if (currentUser == null) {
      return;
    }
    
    // Kullanıcı hediye alınacak kişi değilse, dialog gösterilmez
    // judgeName veya email ile kontrol et
    if (currentUser.judgeName != hediyeAlinacakKisiAdi) {
      // Bu kullanıcı için dialog inaktif
      return;
    }
    
    // Hediye alınacak kişinin email'ini kullan (currentUser'ın email'i)
    final hediyeAlinacakKisiEmail = currentUser.email;
    
    // Hediye durumunu kontrol et
    final hediyeDurumu = HiveDatabaseService.getHediyeDurumu(
      widget.dava.id,
      hediyeAlinacakKisiEmail,
    );
    
    final bool evetTiklandi = hediyeDurumu?['evetTiklandi'] as bool? ?? false;
    
    // EVET tıklanmışsa dialog gösterilmez
    if (evetTiklandi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Hediye zaten alındı olarak işaretlendi'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    
    // Son uyarı tarihini kontrol et
    final sonUyariTarihiStr = hediyeDurumu?['sonUyariTarihi'] as String?;
    DateTime? sonUyariTarihi;
    if (sonUyariTarihiStr != null) {
      sonUyariTarihi = DateTime.tryParse(sonUyariTarihiStr);
    }
    
    final bool uyarButonuAktif = sonUyariTarihi == null || 
        DateTime.now().difference(sonUyariTarihi).inDays >= 19;
    
    // Hediye alınacak kişi bilgilerini al
    final hediyeAlinacakKisiRol = hediyeAlinacakKisiDavaci ? 'Davacı' : 'Davalı';
    
    // Dava tarihini al
    final openedDavalar = HiveDatabaseService.getOpenedDavalar();
    final davaData = openedDavalar.firstWhere(
      (d) => d['id'] == widget.dava.id,
      orElse: () => {},
    );
    final openedAtStr = davaData['openedAt'] as String?;
    String davaTarihi = 'Bilinmeyen Tarih';
    if (openedAtStr != null && openedAtStr.isNotEmpty) {
      final openedAt = DateTime.tryParse(openedAtStr);
      if (openedAt != null) {
        davaTarihi = '${openedAt.day.toString().padLeft(2, '0')}.${openedAt.month.toString().padLeft(2, '0')}.${openedAt.year}';
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık ve Kapat İkonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'HEDİYENİ ALDIN MI?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Çizgi
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade300,
                        Colors.green.shade300,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // EVET Butonu
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Dialog'u önce kapat
                          Navigator.of(context).pop();
                          
                          await HiveDatabaseService.saveHediyeDurumu(
                            davaId: widget.dava.id,
                            userEmail: hediyeAlinacakKisiEmail,
                            evetTiklandi: true,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Hediye alındı olarak işaretlendi'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'EVET',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // UYAR Butonu
                    Expanded(
                      child: ElevatedButton(
                        onPressed: uyarButonuAktif ? () async {
                          // Dialog'u önce kapat
                          Navigator.of(context).pop();
                          
                          final success = await HiveDatabaseService.sendUyari(
                            davaId: widget.dava.id,
                            userEmail: widget.userEmail!,
                            davaci: widget.dava.davaci,
                            davali: widget.dava.davali,
                            davaAdi: widget.dava.adi,
                            davaTarihi: davaTarihi,
                            hediyeAlinacakKisiRol: hediyeAlinacakKisiRol,
                            hediyeAlinacakKisiAdi: hediyeAlinacakKisiDavaci 
                                ? widget.dava.davaci 
                                : widget.dava.davali,
                          );
                          
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Uyarı gönderildi'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            if (sonUyariTarihi != null) {
                              final kalanGun = 19 - DateTime.now().difference(sonUyariTarihi).inDays;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('⚠️ 19 günlük cooldown aktif, kalan gün: $kalanGun'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Uyarı gönderilemedi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: uyarButonuAktif 
                              ? Colors.orange.shade600 
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'UYAR !',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!uyarButonuAktif && sonUyariTarihi != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Son uyarı: ${DateTime.now().difference(sonUyariTarihi).inDays} gün önce\n19 günlük cooldown aktif',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Deliller bölümünü oluştur (KALDIRILDI - Sadece okunabilir mod)
  // ignore: unused_element
  Widget _buildEvidencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 18,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Deliller (${_deliller.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._deliller.take(3).map((delil) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _getEvidenceIcon(delil.type),
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delil.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (delil.description.isNotEmpty)
                          Text(
                            delil.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
          if (_deliller.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DelilListesiEkrani(
                        davaId: widget.dava.id,
                        userEmail: widget.userEmail,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Tüm Delilleri Gör (${_deliller.length})',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FiveCardCaseInformation extends StatefulWidget {
  final Dava dava;
  final VoidCallback? onTap;

  const FiveCardCaseInformation({super.key, required this.dava, this.onTap});

  @override
  State<FiveCardCaseInformation> createState() => _FiveCardCaseInformationState();
}

class _FiveCardCaseInformationState extends State<FiveCardCaseInformation>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false; // Varsayılan olarak daraltılmış
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.withOpacity(0.02),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Ana içerik
                    InkWell(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      onTap: () {
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                          widget.onTap?.call();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sol taraf - Profil resmi ve durum ikonları
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Üst durum ikonu
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          MdiIcons.homeFlood,
                                          size: 16,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Aktif',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Profil resmi
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        widget.dava.profilResmi,
                                        width: 60,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Alt durum ikonu
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          MdiIcons.giftOpen,
                                          size: 16,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Beklemede',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Sağ taraf - Dava bilgileri
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Dava adı
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.gavel,
                                          size: 16,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.dava.adi,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Davacı bilgisi
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Davacı:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[600],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.dava.davaci.isNotEmpty ? widget.dava.davaci : 'Bilinmeyen Yargıç',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Davalı bilgisi
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Davalı:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      Expanded(
                                        child: Text(
                                          widget.dava.davali,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Oy verme butonları
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () {},
                                              icon: Icon(
                                                Icons.thumb_down_alt_outlined,
                                                size: 18,
                                                color: Colors.red[600],
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 24,
                                                minHeight: 24,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {},
                                              icon: Icon(
                                                Icons.thumb_up_alt_outlined,
                                                size: 18,
                                                color: Colors.green[600],
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 24,
                                                minHeight: 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Görev bilgisi
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.work_outline,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Görev:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.dava.mevkii,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Dava Açılış Tarihi
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Dava Açılış Tarihi:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.dava.kalanSure, // Dava açılış tarihi için kalanSure kullanılıyor
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Kalan süre
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          MdiIcons.timerAlertOutline,
                                          size: 16,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Kalan Süre:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.dava.kalanSure,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Hüküm durumu
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.insert_emoticon,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Hüküm:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Beklemede',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Genişletme/daraltma butonu
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.05),
                            Colors.blue.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.blue.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
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
                                  size: 20,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isExpanded ? 'Detayları Gizle' : 'Detayları Göster',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
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
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withOpacity(0.02),
                              Colors.blue.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.dava.davaKonusu.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.description, size: 16, color: Colors.blue[700]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Dava Konusu',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.dava.davaKonusu,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Alt bilgi kartları
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
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
                                        Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'ID: ${widget.dava.id}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontFamily: 'monospace',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Dava Açıldı',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
  }
}

/// Inaktif Dava Card - Red edilen davalar için (FiveCardCaseInformation benzeri)
class InactiveDavaCard extends StatelessWidget {
  final Dava dava;
  
  const InactiveDavaCard({super.key, required this.dava});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5, // Inaktif görünüm için opacity
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200, width: 2),
        ),
        color: Colors.red.shade50,
        child: Stack(
          children: [
            // Orijinal FiveCardCaseInformation içeriği
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol taraf - Profil ve butonlar
                  Container(
                    width: 80,
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              MdiIcons.homeFlood,
                              size: 19,
                              color: Colors.grey,
                            ),
                            const Text(
                              'Onayla',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Image.asset(
                          dava.profilResmi.isNotEmpty 
                            ? dava.profilResmi 
                            : 'lib/icons/07_profil_picture_davaci.png',
                          width: 60,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 50,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.person, color: Colors.grey.shade600),
                            );
                          },
                        ),
                        Row(
                          children: [
                            Icon(
                              MdiIcons.giftOpen,
                              size: 19,
                              color: Colors.grey,
                            ),
                            const Text(
                              'Onayla',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Sağ taraf - Dava bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Dava Adı    :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dava.adi,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Davalı         :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    dava.davali,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.thumb_down_alt_outlined, size: 25, color: Colors.grey),
                                  const Icon(Icons.thumb_up_alt_outlined, size: 25, color: Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Mevkii        :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dava.mevkii,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.grey),
                            const Text(
                              'Kalan Süre :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dava.kalanSure,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // "RED EDİLDİ" Etiketi
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'RED EDİLDİ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 