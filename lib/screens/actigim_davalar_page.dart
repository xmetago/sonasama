import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/actigim_case_card.dart';
import '../widgets/inactive_dava_card.dart';
import '../widgets/actigim_page_chrome.dart';
export '../widgets/tree_menu_page_headlines.dart' show TreeMenuPageheadlines;
export '../widgets/actigim_dava_card.dart' show ActigimDavaCard;
export '../widgets/actigim_case_card.dart' show Dava, FiveCardCaseInformation;
import '../services/hive_database_service.dart';
import '../services/dava_seed_service.dart';
import '../utils/dialog_utils.dart';
import '../models/dava.dart' as dava_model;
import '../providers/dava_provider.dart';

import 'dava_ac_page.dart' hide Dava, FiveCardCaseInformation, TreeMenuPageheadlines;
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
  DavaProvider? _hukumProvider;
  // Performans optimizasyonu: Son refresh zamanı
  DateTime? _lastListRefreshTime;
  static const Duration _listRefreshCooldown = Duration(seconds: 2); // 2 saniye cooldown

  static const ActigimDavaIstatistikService _istatistikService =
      ActigimDavaIstatistikService();

  @override
  void initState() {
    super.initState();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final DavaProvider next = Provider.of<DavaProvider>(context, listen: false);
    if (identical(_hukumProvider, next)) return;
    _hukumProvider?.removeListener(_onHukumProviderSignal);
    _hukumProvider = next;
    next.addListener(_onHukumProviderSignal);
    _onHukumProviderSignal();
  }

  void _onHukumProviderSignal() {
    if (!mounted || _hukumProvider == null) return;
    final int currentVersion = _hukumProvider!.hukumUpdateVersion;
    if (_lastHukumUpdateVersion != currentVersion) {
      final DateTime now = DateTime.now();
      if (_lastListRefreshTime == null ||
          now.difference(_lastListRefreshTime!) >= _listRefreshCooldown) {
        print('🔄 [ActigimDavalarPage] Provider versiyonu değişti: $_lastHukumUpdateVersion -> $currentVersion');
        _lastHukumUpdateVersion = currentVersion;
        _lastListRefreshTime = now;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            print('✅ [ActigimDavalarPage] Liste yeniden yüklenecek (versiyon: $currentVersion)');
            _loadOpenedDavalar();
            _calculateStatistics();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _hukumProvider?.removeListener(_onHukumProviderSignal);
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
        return Scaffold(
      backgroundColor: Colors.white,
      body: ActigimPageChrome(
        userEmail: widget.userEmail,
        initiallyCollapsed: widget.initiallyCollapsed,
        highlightSaveIcon: _highlightSaveIcon,
        hasPendingSavedDava: _hasPendingSavedDava,
        headlineDavaCount: _actigimDavalar.length,
        onShowSavedDavalar: () {
          if (widget.userEmail != null) {
            unawaited(_showSavedDavalarAndRefresh());
          }
        },
        rejectedSection: rejectedDavaList.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
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
                    ...rejectedDavaList.map((dava) => InactiveDavaCard(dava: dava)),
                  ],
                ),
              ),
        listPane: Column(
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
                  final Map<String, dynamic> davaData = _actigimDavalar[index];
                  return _buildActigimSeyirDefteriCard(davaData);
                },
              ),
          ],
        ),
      ),
    );
  }
}
