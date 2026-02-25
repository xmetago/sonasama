import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/common_header_widgets.dart';
import 'gelen_davalar_page.dart';
import 'yargila_page.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import 'haykir_page.dart';
import 'sekiz_hukum_page.dart';
import '../models/sekiz_hukum_arguments.dart';
import '../services/hive_database_service.dart';
import '../services/verified_users_service.dart';
import '../services/dava_consensus_service.dart';
import '../services/dava_hukum_service.dart';
import '../models/hukum_sentiment.dart';
import '../utils/dialog_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';

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

  const KatildigimDavalarPage({super.key, this.userEmail});

  @override
  State<KatildigimDavalarPage> createState() => _KatildigimDavalarPageState();
}

class _KatildigimDavalarPageState extends State<KatildigimDavalarPage> {
  bool showLeftIcons = false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
  List<Map<String, dynamic>> _katildigimDavalar = []; // Gerçek veriler için
  
  // İstatistikler
  int _katildigimSayisi = 0;
  int _hakliOldugumSayisi = 0;
  int _haksizOldugumSayisi = 0;
  int _banaAcilanSayisi = 0;

  @override
  void initState() {
    super.initState();
    _loadKatildigimDavalar();
    _calculateStatistics();
  }

  /// Katıldığım davaları yükle
  void _loadKatildigimDavalar() {
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      final davalar = HiveDatabaseService.getKatildigimDavalar(widget.userEmail!);
      
      // Test verisi ekle (eğer hiç dava yoksa)
      if (davalar.isEmpty) {
        _addTestData();
        return;
      }
      
      setState(() {
        _katildigimDavalar = davalar;
      });
      print('✅ Katıldığım davalar yüklendi: ${davalar.length} dava');
      _calculateStatistics();
    }
  }

  /// İstatistikleri hesapla
  Future<void> _calculateStatistics() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return;
    }

    // Katıldığım sayısı
    final katildigimSayisi = _katildigimDavalar.length;

    // Bana açılan sayısı
    final banaAcilanSayisi = HiveDatabaseService.getIncomingDavalar(widget.userEmail!).length;

    // Haklı/Haksız sayılarını hesapla
    int hakliSayisi = 0;
    int haksizSayisi = 0;

    for (final dava in _katildigimDavalar) {
      final davaId = dava['id'] as String? ?? dava['davaId'] as String? ?? '';
      final davaAdi = dava['adi'] ?? dava['davaAdi'] ?? '';
      final userRole = dava['mevkii'] as String? ?? '';
      
      if (davaId.isEmpty || userRole.isEmpty) continue;

      try {
        // Yargıç kararını kontrol et
        final yargicKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
          davaId,
          'Yargıç Kararı',
          davaAdi: davaAdi,
        );

        if (yargicKarari != null) {
          final sentiment = yargicKarari['hukumSentiment'] as String?;
          final isPositive = sentiment == 'positive';
          final isNegative = sentiment == 'negative';

          // Kullanıcının görevine göre haklı/haksız kontrolü
          if (userRole.toLowerCase().contains('davacı') || userRole.toLowerCase().contains('davaci')) {
            // Kullanıcı davacı ise
            if (isPositive) {
              hakliSayisi++;
            } else if (isNegative) {
              haksizSayisi++;
            }
          } else if (userRole.toLowerCase().contains('davalı') || userRole.toLowerCase().contains('davali')) {
            // Kullanıcı davalı ise (ters mantık)
            if (isPositive) {
              haksizSayisi++; // Davacı haklı ise davalı haksız
            } else if (isNegative) {
              hakliSayisi++; // Davacı haksız ise davalı haklı
            }
          }
        } else {
          // Yargıç kararı yoksa, consensus'e bak
          final openedAtStr = dava['openedAt'] as String? ?? 
                              dava['acceptedAt'] as String? ??
                              dava['createdAt'] as String?;
          DateTime? openedAt;
          if (openedAtStr != null && openedAtStr.isNotEmpty) {
            openedAt = DateTime.tryParse(openedAtStr);
          }

          if (openedAt != null) {
            final evaluation = await DavaConsensusService.evaluateConsensus(
              davaId: davaId,
              openedAt: openedAt,
            );

            if (evaluation.totalVotes > 0) {
              final isDavaciHakli = evaluation.positiveCount > evaluation.negativeCount;
              
              if (userRole.toLowerCase().contains('davacı') || userRole.toLowerCase().contains('davaci')) {
                if (isDavaciHakli) {
                  hakliSayisi++;
                } else {
                  haksizSayisi++;
                }
              } else if (userRole.toLowerCase().contains('davalı') || userRole.toLowerCase().contains('davali')) {
                if (isDavaciHakli) {
                  haksizSayisi++;
                } else {
                  hakliSayisi++;
                }
              }
            }
          }
        }
      } catch (e) {
        print('❌ İstatistik hesaplama hatası: $e');
      }
    }

    setState(() {
      _katildigimSayisi = katildigimSayisi;
      _hakliOldugumSayisi = hakliSayisi;
      _haksizOldugumSayisi = haksizSayisi;
      _banaAcilanSayisi = banaAcilanSayisi;
    });
  }

  /// Test verisi ekle
  void _addTestData() {
    final testDavalar = [
      {
        'id': 'test_dava_1',
        'adi': 'Şeytanın Hileleri',
        'davaAdi': 'Şeytanın Hileleri',
        'davaci': 'Edip Yüksel',
        'davali': 'Edip Yüksel',
        'mevkii': 'Davalı Avukatı',
        'kalanSure': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'profilResmi': 'lib/icons/07_profil_picture_davaci.png',
        'davaKonusu': 'Dini tartışma davası',
        'userEmail': widget.userEmail,
        'source': 'test_data',
        'isAccepted': true,
        'isRejected': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'acceptedAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'id': 'test_dava_2',
        'adi': 'Adaletin Sesi',
        'davaAdi': 'Adaletin Sesi',
        'davaci': 'Ali Veli',
        'davali': 'Ali Veli',
        'mevkii': 'Davacı',
        'kalanSure': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'profilResmi': 'lib/icons/07_profil_picture_davaci.png',
        'davaKonusu': 'Hukuki anlaşmazlık',
        'userEmail': widget.userEmail,
        'source': 'test_data',
        'isAccepted': true,
        'isRejected': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'acceptedAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
    ];

    // Test verilerini veritabanına ekle
    for (final dava in testDavalar) {
      HiveDatabaseService.addKatildigimDava(widget.userEmail!, dava);
    }

    setState(() {
      _katildigimDavalar = testDavalar;
    });
    
    print('✅ Test verileri eklendi: ${testDavalar.length} dava');
  }

  /// DAVA SAYILARI tablosunu oluşturur (geliştirilmiş ve kullanıcı dostu)
  Widget _buildDavaSayilariTable() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.lightGreen.shade100,
            Colors.green.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık - Daha vurgulu
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  MdiIcons.chartBar,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'DAVA SAYILARI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Veri satırları - Daha güzel ve okunabilir
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                _buildStatRow(
                  'Katıldığım',
                  _katildigimSayisi,
                  MdiIcons.accountGroup,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Haklı Olduğum',
                  _hakliOldugumSayisi,
                  MdiIcons.checkCircle,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Haksız Olduğum',
                  _haksizOldugumSayisi,
                  MdiIcons.closeCircle,
                  Colors.red,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Bana Açılan',
                  _banaAcilanSayisi,
                  MdiIcons.emailAlert,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// İstatistik satırını oluşturur (geliştirilmiş)
  Widget _buildStatRow(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol taraf - İkon ve label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color is MaterialColor ? color.shade700 : color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          // Sağ taraf - Değer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: color is MaterialColor
                    ? [color.shade400, color.shade600]
                    : [color, color],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DavaProvider>(
      builder: (context, authProvider, davaProvider, child) {
        // Provider'dan gelen verileri güncelle
        if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
          final providerDavalar = davaProvider.katildigimDavalar;
          if (providerDavalar.isNotEmpty && providerDavalar != _katildigimDavalar) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _katildigimDavalar = providerDavalar;
              });
              // Veriler güncellendiğinde istatistikleri yeniden hesapla
              _calculateStatistics();
            });
          }
        }
        return Scaffold(
      body: SafeArea(
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
            // ROW 4: Hamburger Iconu, Checkbox ve bilgi satırı
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      MdiIcons.menuOpen,
                      size: 34,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        showLeftIcons = !showLeftIcons;
                      });
                    },
                  ),
                  const SizedBox(width: 48),
                  MyCheckboxWidget(davaCount: _katildigimDavalar.length),
                ],
              ),
            ),
            // ROW 5: 6 Icon Solda, Sağda Text Yazma Alanı ve detaylar
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
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

                                ),
                                GestureDetector(
                                  onTap: () {
                                                                      Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => YargilaPage(userEmail: widget.userEmail)),
                                  );
                                  },

                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const KatildigimDavalarPage()),
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
                                    MaterialPageRoute(builder: (context) => ActigimDavalarPage(userEmail: widget.userEmail)),
                                  );
                                  },

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

                                ),
                                GestureDetector(
                                  onTap: () {
                                                                      Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HaykirPage(userEmail: widget.userEmail),
                                    ),
                                  );
                                  },

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
                      child: Container(
                        color: Colors.white30,
                        child: Column(
                          children: [
                            // DAVA SAYILARI Tablosu (sol menü açıldığında sağa kayar)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.only(
                                left: showLeftIcons ? 0 : 0,
                                right: showLeftIcons ? 0 : 0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildDavaSayilariTable(),
                              ),
                            ),
                            // Dava listesi
                            Expanded(
                              child: _katildigimDavalar.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      MdiIcons.briefcaseOutline,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Henüz katıldığınız dava yok',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gelen davalar sayfasından bir dava red edin',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _katildigimDavalar.length,
                                itemBuilder: (context, index) {
                                  final davaData = _katildigimDavalar[index];
                                  return FiveCardCaseInformation(
                                    davaData: davaData,
                                    userEmail: widget.userEmail,
                                    onRefresh: _loadKatildigimDavalar,
                                  );
                                },
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
          ],
        ),
      ),
    );
      },
    );
  }
}

// Stateful checkbox widget (dava_ac_page.dart ile aynı)
class MyCheckboxWidget extends StatefulWidget {
  final int davaCount;
  
  const MyCheckboxWidget({
    super.key,
    required this.davaCount,
  });

  @override
  State<MyCheckboxWidget> createState() => _MyCheckboxWidgetState();
}

class _MyCheckboxWidgetState extends State<MyCheckboxWidget> {
  bool isChecked = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 38),
        const Text(
          'KATILDIGIM   DAVALAR ',
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
        ),
        const SizedBox(width: 4),
        Text(
          ' [ ${widget.davaCount} ]  ', // kaç taneye katıldı isem burda o sayı yazar
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
        ),
      ],
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
  List<String>? _yargicMasraflar;
  bool _cezaOnaylandi = false;
  bool _masrafOnaylandi = false;
  
  // Performans optimizasyonu
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 2);
  
  // Provider senkronizasyonu
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
    
    // 76 gün dolduysa hüküm hesapla ve yükle
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

  /// Konsensus değerlendirmesini yükle
  Future<void> _loadConsensusEvaluation() async {
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    if (davaId.isEmpty) return;

    setState(() {
      _isLoadingConsensus = true;
    });

    try {
      final acceptedAtStr = widget.davaData['acceptedAt'] as String? ?? 
                          widget.davaData['createdAt'] as String?;
      DateTime? acceptedAt;
      if (acceptedAtStr != null && acceptedAtStr.isNotEmpty) {
        acceptedAt = DateTime.tryParse(acceptedAtStr);
      }

      final evaluation = await DavaConsensusService.evaluateConsensus(
        davaId: davaId,
        openedAt: acceptedAt,
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
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Colors.green.withOpacity(0.2),
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
                          Colors.green.withOpacity(0.02),
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
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık satırı - Dava Adı ve Durum (Tıklanabilir)
                                InkWell(
                                  onTap: () async {
                                    final wasExpanded = isExpanded;
                                    setState(() {
                                      isExpanded = !isExpanded;
                                    });
                                    if (!wasExpanded && isExpanded) {
                                      await _refreshAllDataIfNeeded();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.gavel,
                                          size: 20,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.davaData['adi'] ?? widget.davaData['davaAdi'] ?? 'Dava Adı',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Açılır/Kapanır İkon
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0,
                                          duration: const Duration(milliseconds: 300),
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 24,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Kapalı durumda davacı sonucunu ikon ve hızlı aksiyonlarla özetle
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
                                // İçerik - Sadece açık olduğunda göster
                                if (isExpanded) ...[
                                  const SizedBox(height: 16),

                                  // Bilgi kartları - Grid yapısı
                                  Row(
                                    children: [
                                      // Davacı
                                      Expanded(
                                        child: _buildInfoCard(
                                          icon: Icons.person,
                                          label: 'Davacı',
                                          value: widget.davaData['davaci'] ?? 'Bilinmeyen',
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Davalı
                                      Expanded(
                                        child: _buildInfoCard(
                                          icon: Icons.person_outline,
                                          label: 'Davalı',
                                          value: widget.davaData['davali'] ?? 'Bilinmeyen',
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Ceza ve Masraf butonları (sadece yargıç kararı varsa)
                                  if (_shouldShowCezaMasrafButtons())
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCezaOnaylaButton(),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildMasrafOnaylaButton(),
                                      ),
                                    ],
                                  ),
                                  if (_shouldShowCezaMasrafButtons())
                                  const SizedBox(height: 8),
                                  
                                  // Hüküm verisi gösterimi (76 gün dolduysa)
                                  if (_isHukumSuresiDoldu()) ...[
                                    _buildHukumVerisiCard(),
                                    const SizedBox(height: 8),
                                  ],
                                  
                                  Row(
                                    children: [
                                      // Görev - Kullanıcının görevi (seyir defterinde gösterilmez)
                                      if (!widget.isSeyirDefteri) ...[
                                        Expanded(
                                          child: _buildUserRoleCard(),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      // Hükmüm Durumu
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
                                  const SizedBox(height: 8),
                                  // Kullanıcının Kararı veya Yorumu
                                  if (widget.isSeyirDefteri)
                                    // Seyir defterinde: Kullanıcının ilk yorumunu göster
                                    _buildUserYorumSection()
                                  else if (_hasUserHukum())
                                    // Katıldığım davalar sayfasında: Kullanıcının kararını göster
                                    _buildUserKararSection(),
                                  if ((widget.isSeyirDefteri && _hasUserYorum()) || (!widget.isSeyirDefteri && _hasUserHukum()))
                                    const SizedBox(height: 16),

                                  // Kalan Süre - Büyük ve vurgulu
                                  Container(
                                    padding: const EdgeInsets.all(3),
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
                                                'Dava Açılış Tarihi',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              Text(
                                                _getDavaAcilisTarihi(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Genişletme/daraltma butonu (sadece açık olduğunda görünür)
                        if (isExpanded)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.withOpacity(0.05),
                                Colors.green.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: Colors.green.withOpacity(0.1),
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
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isExpanded ? 'Detayları Gizle' : 'Detayları Göster',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
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
                                  Colors.green.withOpacity(0.02),
                                  Colors.green.withOpacity(0.05),
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

                                // Rol Kartları Bölümü
                                _buildRoleCardsSection(),
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

  /// Kapalı görünümde davacı sonucunu ikonla temsil eder
  Widget _buildVerdictEmojiIcon() {
    final bool? verdict = _getFinalDavaciVerdict();
    late final IconData iconData;
    late final Color iconColor;

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

  /// 76 gün doldu mu kontrol et
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
      padding: const EdgeInsets.only(right: 52.0),
      child: InkResponse(
        radius: 20,
        onTap: isDisabled ? null : onTap,
        child: Tooltip(
          message: isDisabled ? '76 gün doldu, bu işlem artık yapılamaz' : tooltip,
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
    
    // 76 gün kontrolü - destek, kına, yorum için
    if (type == 'like' || type == 'dislike' || type == 'comment') {
      if (_isHukumSuresiDoldu()) {
        _showActionSnack('⚠️ 76 gün doldu, bu işlem artık yapılamaz');
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
      
      // 76 gün dolduysa hüküm hesapla
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
                        'Yorumunuz "GizliTanık-X" adıyla görünecektir.',
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

  /// Mevcut hükümleri yükle
  Future<void> _loadExistingHukumler() async {
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    final davaAdi = widget.davaData['adi'] ?? widget.davaData['davaAdi'] ?? '';
    
    if (davaId.isEmpty) {
      return;
    }

    try {
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      Map<String, Map<String, dynamic>> existing = await davaProvider.getHukumlerByDavaId(davaId, davaAdi: davaAdi);
      
      if (existing.isEmpty) {
        existing = await HiveDatabaseService.getHukumlerByDavaIdGrouped(davaId, davaAdi: davaAdi);
      }
      
      if (existing.isEmpty && davaAdi.isNotEmpty) {
        final alternativeId = 'dava_${davaAdi.hashCode}';
        existing = await HiveDatabaseService.getHukumlerByDavaIdGrouped(alternativeId);
      }

      if (!mounted) return;

      setState(() {
        _rolHukumleri.clear();
        _rolHukumleri.addEntries(existing.entries.where((entry) {
          final dynamic text = entry.value['hukumText'];
          return (text is String) && text.trim().isNotEmpty;
        }).map((entry) {
          final String normalizedKey = _normalizeRole(entry.key);
          return MapEntry(
            normalizedKey,
            entry.value['hukumText'].toString(),
          );
        }));

        _rolSentimentleri.clear();
        for (final entry in existing.entries) {
          final String? sentimentValue = entry.value['hukumSentiment'] as String?;
          final HukumSentiment? sentiment = hukumSentimentFromStorage(sentimentValue);
          final String normalizedKey = _normalizeRole(entry.key);
          if (sentiment != null) {
            _rolSentimentleri[normalizedKey] = sentiment;
          }
        }

        _rolFinalizasyonlari.clear();
        _rolFinalizasyonlari.addEntries(existing.entries.map((entry) {
          final String normalizedKey = _normalizeRole(entry.key);
          return MapEntry(
            normalizedKey,
            (entry.value['isFinalized'] as bool?) ?? false,
          );
        }));

        _rolUserEmails.clear();
        _rolUserEmails.addEntries(existing.entries.map((entry) {
          final String normalizedKey = _normalizeRole(entry.key);
          return MapEntry(
            normalizedKey,
            entry.value['userEmail']?.toString() ?? '',
          );
        }));

        _rolCreatedAts.clear();
        _rolCreatedAts.addEntries(existing.entries.map((entry) {
          final String normalizedKey = _normalizeRole(entry.key);
          return MapEntry(
            normalizedKey,
            entry.value['createdAt']?.toString() ?? '',
          );
        }));
      });
    } catch (e) {
      print('❌ [FiveCardCaseInformation] Hükümler yüklenirken hata: $e');
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
    final davaId = widget.davaData['id'] as String? ?? widget.davaData['davaId'] as String? ?? '';
    final davaAdi = widget.davaData['adi'] ?? widget.davaData['davaAdi'] ?? '';
    
    if (davaId.isEmpty) {
      return;
    }

    try {
      String davaIdToUse = davaId;
      
      Map<String, dynamic>? yargicKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
        davaIdToUse,
        'Yargıç Kararı',
        davaAdi: davaAdi,
      );
      
      if (yargicKarari == null && davaAdi.isNotEmpty) {
        final alternativeId = 'dava_${davaAdi.hashCode}';
        yargicKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
          alternativeId,
          'Yargıç Kararı',
          davaAdi: davaAdi,
        );
        if (yargicKarari != null) {
          davaIdToUse = alternativeId;
        }
      }
      
      Map<String, dynamic>? temyizKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
        davaIdToUse,
        'Temyiz Hakimi Kararı',
        davaAdi: davaAdi,
      );
      
      if (temyizKarari == null && davaAdi.isNotEmpty && davaIdToUse == davaId) {
        final alternativeId = 'dava_${davaAdi.hashCode}';
        temyizKarari = await HiveDatabaseService.getHukumByDavaIdAndRole(
          alternativeId,
          'Temyiz Hakimi Kararı',
          davaAdi: davaAdi,
        );
        if (temyizKarari != null) {
          davaIdToUse = alternativeId;
        }
      }

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
        
        if (mounted) {
          String? cezaText = await HiveDatabaseService.getCeza(
            davaId: davaIdToUse,
            userEmail: userEmail,
          );
          
          if (cezaText == null && davaIdToUse == davaId && davaAdi.isNotEmpty) {
            final alternativeId = 'dava_${davaAdi.hashCode}';
            cezaText = await HiveDatabaseService.getCeza(
              davaId: alternativeId,
              userEmail: userEmail,
            );
          }
          
          List<String>? masraflar = await HiveDatabaseService.getMasrafExpenses(
            davaId: davaIdToUse,
            userEmail: userEmail,
          );
          
          if (masraflar == null && davaIdToUse == davaId && davaAdi.isNotEmpty) {
            final alternativeId = 'dava_${davaAdi.hashCode}';
            masraflar = await HiveDatabaseService.getMasrafExpenses(
              davaId: alternativeId,
              userEmail: userEmail,
            );
          }
          
          if (mounted) {
            setState(() {
              _yargicCezaText = cezaText;
              _yargicMasraflar = masraflar;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _yargicCezaText = null;
            _yargicMasraflar = null;
          });
        }
      }
    } catch (e) {
      print('❌ [FiveCardCaseInformation] Yargıç ceza/masraf yüklenirken hata: $e');
    }
  }

  /// Davacının haklı olup olmadığını kontrol eder
  bool _isDavaciHakli() {
    return _getFinalDavaciVerdict() ?? false;
  }

  /// Ceza ve Masraf butonlarının gösterilip gösterilmeyeceğini belirler
  bool _shouldShowCezaMasrafButtons() {
    final bool hasYargicKarari = _rolHukumleri.containsKey('Yargıç Kararı') || 
                                  _rolHukumleri.containsKey('yargıç kararı');
    final bool hasCezaOrMasraf = (_yargicCezaText != null && _yargicCezaText!.isNotEmpty) ||
                                  (_yargicMasraflar != null && _yargicMasraflar!.isNotEmpty);
    return hasYargicKarari && hasCezaOrMasraf;
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isEnabled ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Masrafları Onayla/Kabul Et butonunu oluşturur
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
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
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Rol Kararları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
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

  /// Tekil rol kartını oluşturur
  Widget _buildRoleCard(String title, IconData icon) {
    final String normalizedTitle = _normalizeRole(title);
    final String? hukumText = _rolHukumleri[normalizedTitle];
    final bool hasHukum = (hukumText?.trim().isNotEmpty ?? false);
    final HukumSentiment? sentiment = _rolSentimentleri[normalizedTitle];

    final List<Widget> trailingWidgets = _buildRoleTrailingWidgets(title, hasHukum, normalizedTitle, sentiment);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasHukum ? Colors.green.shade400 : Colors.green.shade200,
          width: hasHukum ? 2 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasHukum ? Colors.green.shade700 : Colors.green.shade700,
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

  /// Rol satırının sağ tarafındaki ikon alanını oluşturur
  List<Widget> _buildRoleTrailingWidgets(
    String title,
    bool hasHukum,
    String normalizedTitle,
    HukumSentiment? sentiment,
  ) {
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

  /// Rol kartında hükmü görüntüleyen aksiyon ikonunu üretir
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

  /// Kullanıcının görevini al
  String _getUserRole() {
    return widget.davaData['mevkii'] as String? ?? 'Katılımcı';
  }

  /// Kullanıcının görevine göre normalize edilmiş rol adını al
  String _getUserNormalizedRole() {
    final userRole = _getUserRole();
    // Eğer görev "Davacı" veya "Davalı" ise, direkt döndür
    if (userRole == 'Davacı' || userRole == 'Davalı') {
      return userRole;
    }
    // Diğer görevler için normalize et
    return _normalizeRole(userRole);
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
    final roleIcon = _getRoleIcon(userRole);
    
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
                  color: Colors.white,
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
            child: Text(
              yorumMetni.length > 150 
                  ? '${yorumMetni.substring(0, 150)}...' 
                  : yorumMetni,
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

  /// Hüküm dialog'unu göster
  void _showHukumDialog(String normalizedRole) {
    String? hukumText = _rolHukumleri[normalizedRole];
    
    if (hukumText == null || hukumText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hüküm bulunamadı: $normalizedRole'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final String userEmail = _rolUserEmails[normalizedRole] ?? '';
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
              ],
            ),
          ),
        );
      },
    );
  }
}