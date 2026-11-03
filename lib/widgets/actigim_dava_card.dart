import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/evidence_model.dart';
import '../models/hukum_sentiment.dart';
import '../providers/dava_provider.dart';
import '../screens/delil_listesi_ekrani.dart';
import '../services/ceza_consensus_service.dart';
import '../services/dava_consensus_service.dart';
import '../services/evidence_service.dart';
import '../services/hediye_consensus_service.dart';
import '../services/hive_database_service.dart';
import '../services/masraf_onay_service.dart';
import 'actigim_case_card.dart';
import 'countdown_timer_widget.dart';
import 'masraf_onay_panel.dart';
import 'rol_hukum_kartlari_section.dart';

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
  /// [ModernHukumCard] dava künyesi ile uyumlu: üst özet satırları aç/kapa.
  bool _kunyeExpanded = true;
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
  /// Rol → ceza metni (Hive `getCezaMapForDavaId`, email eşlemesi — ModernHukumCard ile aynı)
  final Map<String, String> _rolCezalari = <String, String>{};
  /// Rol → masraf/hediye satırı
  final Map<String, String> _rolMasraflari = <String, String>{};
  /// [ModernHukumCard] aktif görev satırında taslak duygu; salt okunurda yüklemede kayıttan doldurulur.
  HukumSentiment? _selectedSentiment;
  List<EvidenceModel> _deliller = [];
  final EvidenceService _evidenceService = EvidenceService();
  
  // Ceza ve masraf bilgileri (Yargıç veya Temyiz Hakimi için)
  String? _yargicCezaText; // Geçerli/nihai ceza (halk oyu → temyiz → yargıç)
  String? _effectiveCezaKaynak;
  List<String>? _hediyeOnayList;
  String? _effectiveHediyeKaynak;
  List<String>? _yargicMasraflar; // Yargıç veya Temyiz Hakimi'nin belirlediği masraflar
  bool _cezaOnaylandi = false; // Ceza onaylandı mı?
  bool _masrafOnaylandi = false; // Masraf onaylandı mı?
  bool _hediyeOnaylandi = false; // Hediye onaylandı mı? (davacı haklı)
  bool _cezaIconPressed = false; // Ceza ikonu basılı animasyon durumu
  
  // Performans optimizasyonu: Son refresh zamanı
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 2); // 2 saniye cooldown
  
  // Provider senkronizasyonu için: Son yüklenen hüküm versiyonu (Provider değişikliklerini takip etmek için)
  int _lastHukumUpdateVersion = -1;

  /// Açılış tarihi önbelleği. `build` Hive kutusunun tamamını taramaz.
  DateTime? _kunyeOpenedAt;
  String? _kunyeOpenedAtDavaId;

  void _refreshKunyeOpenedAt() {
    final String id = widget.dava.id;
    _kunyeOpenedAtDavaId = id;
    if (id.isEmpty) {
      _kunyeOpenedAt = null;
      return;
    }
    try {
      final List<Map<String, dynamic>> openedDavalar =
          HiveDatabaseService.getOpenedDavalar();
      final Map<String, dynamic> davaData = openedDavalar.firstWhere(
        (Map<String, dynamic> d) => d['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final String? openedAtStr = davaData['openedAt'] as String?;
      if (openedAtStr == null || openedAtStr.isEmpty) {
        _kunyeOpenedAt = null;
        return;
      }
      _kunyeOpenedAt = DateTime.tryParse(openedAtStr);
    } catch (e) {
      print('⚠️ [ActigimDavaCard] Açılış tarihi okunamadı: $e');
      _kunyeOpenedAt = null;
    }
  }

  @override
  void setState(VoidCallback fn) {
    _refreshKunyeOpenedAt();
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _refreshKunyeOpenedAt();
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
    
    _loadConsensusEvaluation();
    _loadExistingHukumler();
    _loadYargicCezaVeMasraf(); // Yargıç veya Temyiz Hakimi'nin ceza ve masraf bilgilerini yükle
    // _loadEvidences(); // Kaldırıldı - sadece okunabilir mod
  }

  @override
  void didUpdateWidget(covariant ActigimDavaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshKunyeOpenedAt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  /// Konsensus değerlendirmesini yükle
  Future<void> _loadConsensusEvaluation() async {
    if (widget.dava.id.isEmpty) return;

    setState(() {
      _isLoadingConsensus = true;
    });

    try {
      // openedAt, setState başında önbelleğe alındı. Kutu burada yeniden taranmaz.
      _refreshKunyeOpenedAt();
      final DateTime? openedAt = _kunyeOpenedAt;

      // Debug: Konsensus yükleme bilgilerini yazdır
      print('🔍 [ActigimDavaCard] Konsensus yükleniyor...');
      print('   - Dava ID: ${widget.dava.id}');
      print('   - OpenedAt: $openedAt');
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

  /// Hüküm durumunu al
  String _getHukumStatus() {
    if (_isLoadingConsensus) return 'Yükleniyor...';
    
    // Öncelik sırası: 1) Yargıç Kararı, 2) Temyiz Hakimi Kararı, 3) Consensus (Çoğunluk)
    // Rol adlarını normalize ederek kontrol et
    final normalizedYargic = normalizeRolKarari('Yargıç Kararı');
    final normalizedTemyiz = normalizeRolKarari('Temyiz Hakimi Kararı');
    
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
    final normalizedYargic = normalizeRolKarari('Yargıç Kararı');
    if (_rolHukumleri.containsKey(normalizedYargic)) {
      final sentiment = _rolSentimentleri[normalizedYargic];
      if (sentiment == HukumSentiment.positive) {
        davaciHakli = true;
      }
    } else {
      // Temyiz Hakimi kararını kontrol et
      final normalizedTemyiz = normalizeRolKarari('Temyiz Hakimi Kararı');
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
    
    // Ceza veya masraf/hediye onaylanmışsa UZLAŞMA değil
    if (_cezaOnaylandi || _masrafOnaylandi || _hediyeOnaylandi) return false;
    
    // 72 saat geçmiş mi kontrol et. Tarih önbellekten okunur.
    try {
      final DateTime? openedAt = _getOpenedAtForKunye();
      if (openedAt == null) {
        return false;
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
                          ],
                        ),
                      ),
                    ),

                    // Davacı onay butonları — Dava Künyesi ile Detayları Göster arası
                    if (_shouldShowCezaMasrafButtons())
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _buildDavaciOnayButonlariRow(),
                      ),

                    // Genişletme/daraltma butonu
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
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFCFB),
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
                                    color: const Color(0xFFDCE7E1),
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
                                            color: const Color(0xFF1B2A23),
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

                            // Yargıç oyları — Olumlu / Olumsuz (ModernHukumCard ile birlikte korunur)
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
                              davaId: widget.dava.id.isNotEmpty
                                  ? widget.dava.id
                                  : null,
                              openedAt: _getOpenedAtForKunye(),
                              userEmail: widget.userEmail,
                              kullaniciGorev: widget.dava.mevkii,
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

                            // Deliller Bölümü (Kaldırıldı - sadece okunabilir mod)
                            // if (_deliller.isNotEmpty) ...[
                            //   _buildEvidencesSection(),
                            //   const SizedBox(height: 16),
                            // ],

                            // Dava ID
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAF9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFDCE7E1),
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

  /// [ModernHukumCard._buildDavaInfo] ile aynı çizgi: dava künyesi kutusu.
  Widget _buildDavaKunyeSection() {
    const Color kunyeBorder = Color(0xFFDCE7E1);
    final String kategoriRaw = widget.dava.kategori.trim();
    final String kategoriDisplay =
        kategoriRaw.isNotEmpty ? kategoriRaw : 'Belirtilmedi';

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
                        color: widget.dava.isOpened
                            ? Colors.green.withOpacity(0.08)
                            : Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.dava.isOpened ? Colors.green : Colors.orange,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            widget.dava.isOpened ? Icons.check_circle : Icons.pending_outlined,
                            size: 14,
                            color: widget.dava.isOpened
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.dava.isOpened ? 'Aktif' : 'Beklemede',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: widget.dava.isOpened
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
                    widget.dava.adi,
                    MdiIcons.gavel,
                    iconColor: Colors.green.shade700,
                  ),
                  const Divider(height: 20),
                  GestureDetector(
                    onTap: () => _showHediyeDialog('davaci'),
                    behavior: HitTestBehavior.opaque,
                    child: _buildKunyeInfoRow(
                      'Davacı',
                      widget.dava.davaci.isNotEmpty
                          ? widget.dava.davaci
                          : 'Bilinmeyen Yargıç',
                      MdiIcons.account,
                      iconColor: Colors.green.shade700,
                    ),
                  ),
                  const Divider(height: 20),
                  GestureDetector(
                    onTap: () => _showHediyeDialog('davali'),
                    behavior: HitTestBehavior.opaque,
                    child: _buildKunyeInfoRow(
                      'Davalı',
                      widget.dava.davali,
                      MdiIcons.accountOutline,
                      iconColor: Colors.green.shade700,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildKunyeInfoRow(
                    'Hüküm',
                    _getHukumStatus(),
                    MdiIcons.scaleBalance,
                    iconColor: _getHukumStatusColor(),
                  ),
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

  DateTime? _getOpenedAtForKunye() {
    if (_kunyeOpenedAtDavaId != widget.dava.id) {
      _refreshKunyeOpenedAt();
    }
    return _kunyeOpenedAt;
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
    final DateTime? openedAt = _getOpenedAtForKunye();
    final String openedAtText = openedAt != null
        ? _formatKunyeDateTime(openedAt)
        : (widget.dava.kalanSure.isNotEmpty
            ? widget.dava.kalanSure
            : 'Açılış tarihi bulunamadı');

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
                  if (openedAt == null && widget.dava.kalanSure.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      widget.dava.kalanSure,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
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

  /// [ModernHukumCard._canEvaluateConsensus]
  bool get _canEvaluateConsensus => widget.dava.id.isNotEmpty;

  /// [ModernHukumCard._refreshConsensus] — rozet yenile.
  Future<void> _refreshConsensus() async {
    if (!_canEvaluateConsensus) {
      if (!mounted) return;
      setState(() {
        _consensusEvaluation = null;
        _isLoadingConsensus = false;
      });
      return;
    }
    await _loadConsensusEvaluation();
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

  /// [ModernHukumCard._loadExistingHukumler] ile aynı mantık: kayıtlı hükümler hem gerçek
  /// `davaId` hem de `dava_${davaAdi.hashCode}` altında tutulabiliyor; ikisini birleştirir.
  Map<String, Map<String, dynamic>> _mergeHukumlerGroupedMaps(
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

  /// Mevcut hükümleri yükle (Provider üzerinden - senkronizasyon için)
  Future<void> _loadExistingHukumler() async {
    final String pid = widget.dava.id.trim();
    final String? hid =
        widget.dava.adi.isNotEmpty ? 'dava_${widget.dava.adi.hashCode}' : null;
    if (pid.isEmpty && (hid == null || hid.isEmpty)) {
      print('❌ [ActigimDavaCard] Dava ID ve dava adı yok, hüküm yüklenemiyor!');
      return;
    }

    print('🔍 [ActigimDavaCard] ========== HÜKÜMLER YÜKLENİYOR ==========');
    print('   - Dava ID: "${widget.dava.id}"');
    print('   - Dava Adı: "${widget.dava.adi}"');
    print('   - Mevcut versiyon: $_lastHukumUpdateVersion');
    print('   - Alternatif ID (hash): "dava_${widget.dava.adi.hashCode}"');

    try {
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      final List<Map<String, Map<String, dynamic>>> idChunks =
          <Map<String, Map<String, dynamic>>>[];

      if (pid.isNotEmpty) {
        Map<String, Map<String, dynamic>> byPid =
            await davaProvider.getHukumlerByDavaId(pid, davaAdi: widget.dava.adi);
        if (byPid.isEmpty) {
          byPid = await HiveDatabaseService.getHukumlerByDavaIdGrouped(
            pid,
            davaAdi: widget.dava.adi,
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
          davaAdi: widget.dava.adi,
        );
        if (byHid.isNotEmpty) {
          idChunks.add(byHid);
        }
      }

      Map<String, Map<String, dynamic>> existing =
          _mergeHukumlerGroupedMaps(idChunks);

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
                pid,
                if (hid != null) hid,
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

      existing = _mergeHukumlerGroupedMaps(
        <Map<String, Map<String, dynamic>>>[existing],
      );

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

      final String cezaPrimaryId = pid.isNotEmpty ? pid : (hid ?? '');
      final Map<String, String> cezalarByEmail = cezaPrimaryId.isNotEmpty
          ? Map<String, String>.from(
              await HiveDatabaseService.getCezaMapForDavaId(cezaPrimaryId),
            )
          : <String, String>{};
      final Map<String, String> masraflarByEmail = cezaPrimaryId.isNotEmpty
          ? Map<String, String>.from(
              await HiveDatabaseService.getMasrafGiftLineMapForDavaId(cezaPrimaryId),
            )
          : <String, String>{};
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
        // Hüküm metinlerini yükle (key'ler zaten normalize edilmiş - getHukumlerByDavaIdGrouped'den geliyor)
        _rolHukumleri.clear();
        _rolHukumleri.addEntries(existing.entries.where((entry) {
          final dynamic text = entry.value['hukumText'];
          return (text is String) && text.trim().isNotEmpty;
        }).map((entry) {
          // Key zaten normalize edilmiş (modern_hukum_card.dart'ta normalize edilmiş olarak kaydediliyor)
          // Ama yine de normalize edelim ki tutarlı olsun (eğer eski veriler varsa)
          final String normalizedKey = normalizeRolKarari(entry.key);
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
          final String normalizedKey = normalizeRolKarari(entry.key);
          
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
          final String normalizedKey = normalizeRolKarari(entry.key);
          return MapEntry(
            normalizedKey,
            (entry.value['isFinalized'] as bool?) ?? false,
          );
        }));

        // Kullanıcı email'lerini yükle (normalize edilmiş key'ler ile)
        _rolUserEmails.clear();
        _rolUserEmails.addEntries(existing.entries.map((entry) {
          // Veritabanından gelen rol adını normalize et (modern_hukum_card.dart ile senkronize)
          final String normalizedKey = normalizeRolKarari(entry.key);
          return MapEntry(
            normalizedKey,
            entry.value['userEmail']?.toString() ?? '',
          );
        }));

        // Oluşturulma tarihlerini yükle (normalize edilmiş key'ler ile)
        _rolCreatedAts.clear();
        _rolCreatedAts.addEntries(existing.entries.map((entry) {
          // Veritabanından gelen rol adını normalize et (modern_hukum_card.dart ile senkronize)
          final String normalizedKey = normalizeRolKarari(entry.key);
          return MapEntry(
            normalizedKey,
            entry.value['createdAt']?.toString() ?? '',
          );
        }));

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

        final String normalizedUserRole = normalizeRolKarari(widget.dava.mevkii);
        _selectedSentiment = _rolSentimentleri[normalizedUserRole];
        
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

  /// Geçerli ceza, masraf (davalı) ve hediye (davacı) — konsensus ile senkron.
  Future<void> _loadYargicCezaVeMasraf() async {
    if (widget.dava.id.isEmpty) {
      return;
    }

    try {
      final CezaDavaLoadResult cezaLoad =
          await CezaConsensusService.loadEffectiveCezaForDava(
        davaId: widget.dava.id,
        davaAdi: widget.dava.adi,
      );
      final List<String>? masraflar =
          await CezaConsensusService.loadMasraflarForDava(
        loadResult: cezaLoad,
        davaId: widget.dava.id,
        davaAdi: widget.dava.adi,
      );

      final HediyeDavaLoadResult hediyeLoad =
          await HediyeConsensusService.loadEffectiveHediyeForDava(
        davaId: widget.dava.id,
        davaAdi: widget.dava.adi,
      );
      final List<String>? hediyeler =
          await HediyeConsensusService.loadHediyeListForDava(
        loadResult: hediyeLoad,
        davaId: widget.dava.id,
        davaAdi: widget.dava.adi,
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
      print('❌ [ActigimDavaCard] Ceza/masraf/hediye yüklenirken hata: $e');
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
    if (_consensusEvaluation == null) return false;
    // positiveCount = davalı haksız (Haklı Davacı)
    // negativeCount = davacı haksız (Haklı Davalı)
    return _consensusEvaluation!.positiveCount > _consensusEvaluation!.negativeCount;
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

  String _hediyeOnayGosterimMetni(bool hasHediye) {
    if (!hasHediye) {
      return _hediyeOnaylandi ? 'Onaylandı' : 'Hediye bekleniyor';
    }
    final int n = _hediyeOnayList!.length;
    final String metin = '$n hediye seçildi';
    final String? kaynak = _effectiveHediyeKaynak;
    if (kaynak != null && kaynak.isNotEmpty) {
      return '$metin · $kaynak';
    }
    return metin;
  }

  /// Ceza ve Masraf/Hediye butonlarının gösterilip gösterilmeyeceğini belirler
  bool _shouldShowCezaMasrafButtons() {
    final bool hasCezaOrMasraf = (_yargicCezaText != null && _yargicCezaText!.isNotEmpty) ||
        (_yargicMasraflar != null && _yargicMasraflar!.isNotEmpty) ||
        (_hediyeOnayList != null && _hediyeOnayList!.isNotEmpty);
    return hasCezaOrMasraf;
  }

  /// Davacı onay satırı — davacı her durumda onay merciidir.
  ///
  /// KURAL SETİ (Nihai) — Davacı'nın açtığım sayfasında 4 durumun her biri için
  /// `MasrafOnayPanel` tek başına doğru butonu seçer:
  ///
  /// - Durum 1 (Davacı haklı + Davalı ÜYE) → **MASRAF/UYAR** (Davalı basacak,
  ///   Davacı 19 günde bir uyarır). Ana onay butonu burada görünmez —
  ///   `katıldığım davalar` sayfasında Davalı'ya çıkar.
  /// - Durum 2 (Davacı haklı + Davalı ÜYE DEĞİL) → **WHOBOOM'A ÖDENSİN**
  ///   (Davacı basar, +Yeşil kazanır).
  /// - Durum 3 (Davacı haksız + Davalı ÜYE) → **MASRAFLARI ONAYLA** (Davacı
  ///   basar). MASRAF/UYAR butonu Davalı'nın katıldığım sayfasına düşer.
  /// - Durum 4 (Davacı haksız + Davalı ÜYE DEĞİL) → **MASRAFLARI ONAYLA**
  ///   (Davacı basar). Uyarılacak Davalı olmadığı için UYAR butonu hiç
  ///   görünmez.
  Widget _buildDavaciOnayButonlariRow() {
    final bool davaciHakli = _isDavaciHakli();
    final decision = MasrafOnayService.decide(
      davaciHakli: davaciHakli,
      davaciJudgeName: widget.dava.davaci,
      davaliJudgeName: widget.dava.davali,
    );

    final Widget sagButon = MasrafOnayPanel(
      davaId: widget.dava.id,
      davaAdi: widget.dava.adi,
      decision: decision,
      currentUserEmail: widget.userEmail,
      currentUserJudgeName: HiveDatabaseService.getRegistrationByEmail(
        widget.userEmail ?? '',
      )?.judgeName,
      onStateChanged: () {
        if (mounted) {
          setState(() {
            _masrafOnaylandi = true;
          });
        }
      },
    );

    return Row(
      children: <Widget>[
        Expanded(child: _buildCezaOnaylaButton()),
        const SizedBox(width: 8),
        Expanded(child: sagButon),
      ],
    );
  }

  /// Cezayı Onayla butonunu oluşturur (Oyunsal ve Animasyonlu)
  Widget _buildCezaOnaylaButton() {
    final bool hasCeza = _yargicCezaText != null && _yargicCezaText!.isNotEmpty;
    final bool isEnabled = hasCeza && !_cezaOnaylandi;
    final bool davaciHakli = _isDavaciHakli();
    final String buttonText = davaciHakli
        ? (_cezaOnaylandi ? 'Ceza Onaylandı ✅' : 'Cezasını  Onayla')
        : (_cezaOnaylandi ? 'Ceza Onaylandı ✅' : 'Cezanı    Onayla');

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
                      fontSize: 12,
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

                ],
              ),
        ),
      ),
        );
      },
    );
  }

  /// Masrafları Onayla butonunu oluşturur (davacı haksız — Oyunsal ve Animasyonlu)
  Widget _buildMasrafOnaylaButton() {
    final bool hasMasraf = _yargicMasraflar != null && _yargicMasraflar!.isNotEmpty;
    final bool isEnabled = hasMasraf && !_masrafOnaylandi;
    final String buttonText =
        _masrafOnaylandi ? 'Masraflar Onaylandı ✅' : 'Masrafları Onayla';

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

  /// Hediyeleri Onayla butonunu oluşturur (davacı haklı — Oyunsal ve Animasyonlu)
  Widget _buildHediyeOnaylaButton() {
    final bool hasHediye = _hediyeOnayList != null && _hediyeOnayList!.isNotEmpty;
    final bool isEnabled = hasHediye && !_hediyeOnaylandi;
    final String buttonText =
        _hediyeOnaylandi ? 'Hediyeler Onaylandı ✅' : 'HEDİYELERİ ONAYLA';

    if (_masrafPulseController == null || _masrafGlowController == null ||
        _masrafPulseAnimation == null || _masrafGlowAnimation == null) {
      return _buildSimpleHediyeButton(hasHediye, isEnabled, buttonText);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_masrafPulseController!, _masrafGlowController!]),
      builder: (context, child) {
        return Transform.scale(
          scale: isEnabled ? _masrafPulseAnimation!.value : 1.0,
          child: GestureDetector(
            onTap: isEnabled ? () => _onHediyeOnayla() : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.amber.shade400,
                          Colors.orange.shade600,
                          Colors.deepOrange.shade800,
                        ],
                      )
                    : null,
                color: isEnabled ? null : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled
                      ? Colors.orange.shade300
                      : Colors.grey.withOpacity(0.3),
                  width: isEnabled ? 2.5 : 1,
                ),
                boxShadow: isEnabled && _masrafGlowAnimation != null
                    ? [
                        BoxShadow(
                          color: Colors.orange.withOpacity(_masrafGlowAnimation!.value),
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
                          color: isEnabled
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          MdiIcons.giftOutline,
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
                              ? (hasHediye ? Icons.check_circle : Icons.access_time)
                              : Icons.block,
                          size: 16,
                          color: isEnabled
                              ? (hasHediye ? Colors.white : Colors.white70)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _hediyeOnayGosterimMetni(hasHediye),
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
          ),
        );
      },
    );
  }

  /// Basit hediye butonu (animasyon controller'ları yoksa)
  Widget _buildSimpleHediyeButton(bool hasHediye, bool isEnabled, String buttonText) {
    return GestureDetector(
      onTap: isEnabled ? () => _onHediyeOnayla() : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade600,
                    Colors.deepOrange.shade800,
                  ],
                )
              : null,
          color: isEnabled ? null : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? Colors.orange.shade300 : Colors.grey.withOpacity(0.3),
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
                    MdiIcons.giftOutline,
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
                        ? (hasHediye ? Icons.check_circle : Icons.access_time)
                        : Icons.block,
                    size: 16,
                    color: isEnabled
                        ? (hasHediye ? Colors.white : Colors.white70)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _hediyeOnayGosterimMetni(hasHediye),
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
                      _cezaOnayGosterimMetni(hasCeza),
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
                  size: 24,
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

  /// Hediye onaylama işlemi (davacı haklı)
  void _onHediyeOnayla() {
    if (_hediyeOnayList == null || _hediyeOnayList!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onaylanacak hediye bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hediyeleri Onayla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_hediyeOnayList!.length} hediye onaylanacak:'),
              if (_effectiveHediyeKaynak != null &&
                  _effectiveHediyeKaynak!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Kaynak: $_effectiveHediyeKaynak',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 8),
              ..._hediyeOnayList!.map((hediye) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $hediye'),
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
                  _hediyeOnaylandi = true;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Hediyeler onaylandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Onayla'),
            ),
          ],
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
    
    // Dava tarihini al. Dokunma anında bir kez okunur, build sırasında değil.
    _refreshKunyeOpenedAt();
    final DateTime? openedAt = _kunyeOpenedAt;
    String davaTarihi = 'Bilinmeyen Tarih';
    if (openedAt != null) {
      davaTarihi = '${openedAt.day.toString().padLeft(2, '0')}.${openedAt.month.toString().padLeft(2, '0')}.${openedAt.year}';
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

