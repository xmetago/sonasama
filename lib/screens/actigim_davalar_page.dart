import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/common_header_widgets.dart';
import '../widgets/actigim_case_card.dart';
export '../widgets/actigim_dava_card.dart' show ActigimDavaCard;
export '../widgets/actigim_case_card.dart' show Dava, FiveCardCaseInformation;
import 'gelen_davalar_page.dart' hide Dava, FiveCardCaseInformation;
import 'yargila_page.dart' hide Dava, FiveCardCaseInformation;
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import '../services/hive_database_service.dart';
import '../services/dava_seed_service.dart';
import '../utils/dialog_utils.dart';
import '../models/dava.dart' as dava_model;
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';

import 'dava_ac_page.dart' hide Dava, FiveCardCaseInformation;
import 'katildigim_davalar_page.dart' hide Dava, FiveCardCaseInformation;
import 'haykirislarim_page.dart';
import '../widgets/ilgililerin_seyir_defteri_widgeti.dart';
import '../widgets/actigim_dava_sayilari_section.dart';
import '../services/actigim_dava_istatistik_service.dart';
import '../utils/dava_map_utils.dart';

class ActigimDavalarPage extends StatefulWidget {
  final String? userEmail;
  final bool initiallyCollapsed;

  const ActigimDavalarPage({
    super.key,
    this.userEmail,
    this.initiallyCollapsed = false,
  });

  @override
  State<ActigimDavalarPage> createState() => _ActigimDavalarPageState();
}

class _ActigimDavalarPageState extends State<ActigimDavalarPage> {
  bool showLeftIcons = false;
  late bool isHeaderCollapsed;
  List<Map<String, dynamic>> _actigimDavalar = [];
  List<Dava> rejectedDavaList = []; // Red edilen davalar
  final Map<String, bool> _seyirDefteriCollapsedByDavaId = <String, bool>{};
  bool _highlightSaveIcon = false;
  bool _hasPendingSavedDava = false;
  Timer? _saveIconBlinkTimer;

  int _actigimSayisi = 0;
  int _hakliOldugumSayisi = 0;
  int _haksizOldugumSayisi = 0;
  int _banaAcilanSayisi = 0;

  // Provider senkronizasyonu için: Son yüklenen hüküm versiyonu
  int _lastHukumUpdateVersion = -1;
  // Performans optimizasyonu: Son refresh zamanı
  DateTime? _lastListRefreshTime;
  static const Duration _listRefreshCooldown = Duration(seconds: 2); // 2 saniye cooldown

  static const ActigimDavaIstatistikService _istatistikService =
      ActigimDavaIstatistikService();

  @override
  void initState() {
    super.initState();
    isHeaderCollapsed = widget.initiallyCollapsed;
    _loadOpenedDavalar();
    _loadRejectedDavalar();
    _calculateStatistics();
    _refreshSavedDavaIndicator();
    
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

  @override
  void dispose() {
    _saveIconBlinkTimer?.cancel();
    super.dispose();
  }

  void _refreshSavedDavaIndicator() {
    final savedDavalar = HiveDatabaseService.getSavedDavalar();
    if (!mounted) return;
    setState(() {
      _hasPendingSavedDava = savedDavalar.isNotEmpty;
      if (!_hasPendingSavedDava) {
        _highlightSaveIcon = false;
      }
    });
    _startSaveIconBlinkTimerIfNeeded();
  }

  void _startSaveIconBlinkTimerIfNeeded() {
    _saveIconBlinkTimer?.cancel();
    if (!_hasPendingSavedDava) return;

    _highlightSaveIcon = true;
    _saveIconBlinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_hasPendingSavedDava) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _highlightSaveIcon = false;
          });
        }
        return;
      }
      setState(() {
        _highlightSaveIcon = !_highlightSaveIcon;
      });
    });
  }

  Future<void> _showSavedDavalarAndRefresh() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return;
    await showSavedDavalarDialog(context, widget.userEmail!);
    if (!mounted) return;
    _refreshSavedDavaIndicator();
    _loadOpenedDavalar();
  }

  /// Test: HAKLI + HAKSIZ davacı onay senaryolarını veritabanına yazar.
  Future<void> _seedOnayTestDavalar() async {
    final String? email = widget.userEmail;
    if (email == null || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş yapın — test davaları için kullanıcı e-postası gerekli.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = HiveDatabaseService.getRegistrationByEmail(email);
    final String davaciName =
        user?.judgeName.trim().isNotEmpty == true ? user!.judgeName : 'Test Davacı';

    try {
      final result = await DavaSeedService.seedDavaciOnayTestDavalar(
        davaciName: davaciName,
      );
      if (!mounted) return;
      try {
        Provider.of<DavaProvider>(context, listen: false).notifyMasrafDataChanged();
      } catch (_) {}
      _loadOpenedDavalar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'KURAL SETİ — 4 onay senaryosu yüklendi:\n'
            '1) ${result['durum1Adi']}  →  ${result['durum1Buton']}\n'
            '2) ${result['durum2Adi']}  →  ${result['durum2Buton']}\n'
            '3) ${result['durum3Adi']}  →  ${result['durum3Buton']}\n'
            '4) ${result['durum4Adi']}  →  ${result['durum4Buton']}',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test davalar yüklenemedi: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildOnayTestSeedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Material(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _seedOnayTestDavalar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(Icons.science_outlined, color: Colors.amber.shade900, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Onay butonları testi (KURAL SETİ — 4 durum)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        'D1 HAKLI+ÜYE · D2 HAKLI+ÜYESİZ · D3 HAKSIZ+ÜYE · D4 HAKSIZ+ÜYESİZ',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.download_rounded, color: Colors.amber.shade900),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Açılan davaları ve beklemede davaları yükle (davacı olarak)
  void _loadOpenedDavalar() {
    final email = widget.userEmail ?? '';
    final davalar = ActigimDavaIstatistikService.listActigimDavalarForUser(email);

    setState(() {
      _actigimDavalar = davalar;
    });
    unawaited(_calculateStatistics());
  }

  Future<void> _calculateStatistics() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return;
    }

    try {
      final stats = await _istatistikService.compute(widget.userEmail!);
      if (!mounted) return;
      setState(() {
        _actigimSayisi = stats.actigim;
        _hakliOldugumSayisi = stats.hakliOldugum;
        _haksizOldugumSayisi = stats.haksizOldugum;
        _banaAcilanSayisi = stats.banaAcilan;
      });
    } catch (e) {
      print('❌ [ActigimDavalarPage] İstatistik hesaplama hatası: $e');
    }
  }

  Widget _buildActigimSeyirDefteriCard(Map<String, dynamic> davaData) {
    final String davaId =
        (davaData['id'] ?? davaData['davaId'] ?? '').toString().trim();
    final String? openedAtRaw =
        (davaData['openedAt'] ?? davaData['createdAt'])?.toString();
    DateTime? openedAt;
    if (openedAtRaw != null && openedAtRaw.isNotEmpty) {
      openedAt = DateTime.tryParse(openedAtRaw);
    }
    final bool collapsed = _seyirDefteriCollapsedByDavaId[davaId] ?? true;

    final String adi =
        (davaData['davaAdi'] ?? davaData['adi'] ?? '').toString();
    final bool isOpened = davaData['isOpened'] == true;
    final bool isBeklemede = adi == 'Beklemede' && !isOpened;

    Widget card = Container(
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
          davaAdi: adi.isEmpty ? null : adi,
          davaci: davaData['davaci']?.toString(),
          davali: davaData['davali']?.toString(),
          kategori: (davaData['kategori'] ??
                  resolveDavaKategoriFromMap(davaData))
              .toString(),
          davaKonusu: davaData['davaKonusu']?.toString(),
          openedAt: openedAt,
          kullaniciGorev: 'Davacı',
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

    if (isBeklemede) {
      card = GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DavaAcPage(
                userEmail: widget.userEmail,
                editDava: dava_model.Dava(
                  id: davaId,
                  davaAdi: adi,
                  davaci: davaData['davaci']?.toString() ?? '',
                  davali: davaData['davali']?.toString() ?? '',
                  mevkii: davaData['mevkii']?.toString() ?? '',
                  kalanSure: davaData['kalanSure']?.toString() ?? '',
                  profilResmi: davaData['profilResmi']?.toString() ?? '',
                  davaKonusu: davaData['davaKonusu']?.toString() ?? '',
                  kategori: resolveDavaKategoriFromMap(davaData),
                  isOpened: isOpened,
                ),
              ),
            ),
          );
          if (mounted) {
            _loadOpenedDavalar();
          }
        },
        child: card,
      );
    }

    return card;
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
          kategori: resolveDavaKategoriFromMap(davaMap),
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
                _calculateStatistics();
              }
            });
          }
        }
        
        return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Üst Arayüz Bölümü - diğer sayfalar gibi aç/kapa (collapse)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isHeaderCollapsed ? 40 : null,
                child: isHeaderCollapsed
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        child: Row(
                          children: [
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
                                '|| AÇTIĞIM DAVALAR ||',
                                style: TextStyle(
                                  fontSize: 11,
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
                                  unawaited(_showSavedDavalarAndRefresh());
                                }
                              },
                            ),
                          ),
                          // ROW 4: Hamburger Iconu, Başlık ve collapse oku
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
                              onShowSavedDavalar: () {
                                if (widget.userEmail != null) {
                                  unawaited(_showSavedDavalarAndRefresh());
                                }
                              },
                              highlightSaveIcon: _highlightSaveIcon,
                              hasPendingSavedDava: _hasPendingSavedDava,
                              headlineDavaCount: _actigimDavalar.length,
                            ),
                        ],
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOnayTestSeedBanner(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ActigimDavaSayilariSection(
                              actigim: _actigimSayisi,
                              hakli: _hakliOldugumSayisi,
                              haksiz: _haksizOldugumSayisi,
                              banaAcilan: _banaAcilanSayisi,
                            ),
                          ),
                          if (_actigimDavalar.isEmpty)
                            Padding(
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
                                  const SizedBox(height: 8),
                                  Text(
                                    'Davacı olarak açtığınız davalar burada, ilgililerin seyir defteri ile görünür',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  OutlinedButton.icon(
                                    onPressed: _seedOnayTestDavalar,
                                    icon: const Icon(Icons.science_outlined),
                                    label: const Text('Test: HAKLI + HAKSIZ dava yükle'),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _actigimDavalar.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Map<String, dynamic> davaData =
                                    _actigimDavalar[index];
                                return _buildActigimSeyirDefteriCard(davaData);
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
  final VoidCallback? onShowSavedDavalar;
  final bool highlightSaveIcon;
  final bool hasPendingSavedDava;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  /// Sayfa başlığı (varsayılan: Açtığım Davalar).
  final String headlineText;
  /// Başlık solundaki satır ikonunun asset yolu.
  final String headlineAssetPath;
  /// Varsa başlıktan sonra rozet olarak gösterilir.
  final int? headlineDavaCount;
  /// Kaydedilen dava düzenleme ikonu (Katıldığım Davalar gibi sayfalarda false).
  final bool showSavedDavalarIcon;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Color(0xFF2F3E35),
  );

  const TreeMenuPageheadlines({
    super.key,
    this.onMenuPressed,
    this.onShowSavedDavalar,
    this.highlightSaveIcon = false,
    this.hasPendingSavedDava = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.headlineText = 'AÇTIĞIM DAVALAR',
    this.headlineAssetPath = 'lib/icons/06_left_row_actigim_davalar_icon.png',
    this.headlineDavaCount,
    this.showSavedDavalarIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
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
            tooltip: 'Sol menü',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('|| $headlineText ||', style: _titleStyle),
                if (headlineDavaCount != null && headlineDavaCount! > 0) ...[
                  const SizedBox(width: 7),
                  _HeadlineDavaCountBadge(count: headlineDavaCount!),
                ],
                if (showSavedDavalarIcon) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Kaydedilen Davalar - Düzenlemek için tıklayın',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onShowSavedDavalar,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: highlightSaveIcon || hasPendingSavedDava
                                ? const Color(0xFF4CAF50).withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: highlightSaveIcon || hasPendingSavedDava
                                  ? const Color(0xFF4CAF50)
                                  : Colors.transparent,
                              width: highlightSaveIcon ? 3 : (hasPendingSavedDava ? 1.5 : 0),
                            ),
                            boxShadow: highlightSaveIcon
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withOpacity(0.35),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            MdiIcons.contentSaveOutline,
                            size: 24,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onToggleCollapse != null)
            IconButton(
              icon: Icon(
                isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 24,
                color: Colors.black,
              ),
              onPressed: onToggleCollapse,
              tooltip: isCollapsed ? 'Arayüzü Aç' : 'Arayüzü Kapat',
            )
          else
            const SizedBox(width: 38),
        ],
      ),
    );
  }
}

/// Gelen davalar sayfasındaki rozet stiliyle uyumlu dava sayısı göstergesi.
class _HeadlineDavaCountBadge extends StatelessWidget {
  final int count;

  const _HeadlineDavaCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
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
  }
}

/// Modern Dava Kartı Widget'ı - Açtığım Davalar için
/// 168 saatlik geri sayım, hüküm durumu ve modern UI ile
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