import 'package:flutter/material.dart';
import 'dart:async';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/countdown_timer_widget.dart';
import 'yargila_page.dart';
import 'actigim_davalar_page.dart';
import 'davaci_unlulur_page.dart';
import 'trend_insights_page.dart';
import 'haykir_page.dart';
import '../services/hive_database_service.dart';
import '../services/dava_timer_service.dart';
import '../services/dava_appeal_judge_assign_service.dart';
import '../services/dava_auto_assign_service.dart';
import 'gelen_davalar_kactane.dart';
import 'friendship_management_page.dart';
import '../providers/dava_provider.dart';
import 'katildigim_davalar_page.dart';

// Model class for Dava
class Dava {
  final String id;
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String davaKonusu;
  final String davaci; // Davacı bilgisi eklendi
  final DateTime? createdAt; // Dava açılış tarihi
  final DateTime? acceptedAt; // Dava kabul edilme tarihi
  /// AwaitingRole | RoleAssigned | FinalJudgement | …
  final String lifecycleStatus;
  /// Davalı e-posta (üyelik / misafir rozeti için)
  final String? davaliEmail;
  /// Temyiz hakimi görevi mi (tarafın takipçisine atanan)
  final bool isAppealJudgeAssignment;

  Dava({
    required this.id,
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    required this.davaKonusu,
    this.davaci = '', // Varsayılan boş değer
    this.createdAt,
    this.acceptedAt,
    this.lifecycleStatus = DavaLifecycleStatuses.awaitingRole,
    this.davaliEmail,
    this.isAppealJudgeAssignment = false,
  });
}

class GelenDavalarPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const GelenDavalarPage({super.key, this.userEmail});

  @override
  State<GelenDavalarPage> createState() => _GelenDavalarPageState();
}

class _GelenDavalarPageState extends State<GelenDavalarPage> {
  bool showLeftIcons = false; // Sol ikonların gösterilip gösterilmeyeceğini kontrol eder
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
    return Consumer<DavaProvider>(
      builder: (context, davaProvider, child) {
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
                  // Gelen davalar sayfasında kaydedilen davalar dialog'u açılamaz
                  // Bu sayfa sadece gelen davaları gösterir
                },
              ),
            ),
            // ROW 4: Menü + başlık + gelen dava sayısı rozeti
            GelenDavalarHeadlineRow(
              onMenuPressed: () {
                setState(() {
                  showLeftIcons = !showLeftIcons;
                });
              },
            ),
            // ROW 5: Sol navigasyon + dava listesi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: showLeftIcons ? 56 : 0,
                      child: showLeftIcons
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE0E4EA)),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: GelenDavalarLeftNavColumn(userEmail: widget.userEmail),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (showLeftIcons) const SizedBox(width: 10),
                    Expanded(
                      child: ListView.builder(
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

class FiveCardCaseInformation extends StatefulWidget {
  final Dava dava;
  final VoidCallback? onTap;
  final bool isExpanded;
  final String? userEmail;
  final VoidCallback? onDavaRejected; // Red edilince çağrılacak callback

  const FiveCardCaseInformation({
    super.key, 
    required this.dava, 
    this.onTap,
    this.isExpanded = false,
    this.userEmail,
    this.onDavaRejected,
  });

  @override
  State<FiveCardCaseInformation> createState() => _FiveCardCaseInformationState();
}

class _FiveCardCaseInformationState extends State<FiveCardCaseInformation> {
  String? selectedRole;
  bool isAccepted = false;
  bool isRejected = false;
  bool showRoleSelection = false;
  bool isRoleConfirmed = false;
  DateTime? _acceptedAt; // Kabul edilme zamanı
  bool _hasExistingRole = false; // Kullanıcının bu davada zaten bir görevi var mı?
  String? _existingRole; // Mevcut görev adı

  Color _cardPhaseColor() {
    final opened = widget.dava.createdAt ?? DateTime.now();
    final seg = DavaTimerService.buildIncomingListCountdown(openedAt: opened);
    return seg?.accentColor ?? Colors.green.shade300;
  }

  bool _isAppealJudgeAssignmentCard() =>
      widget.dava.isAppealJudgeAssignment ||
      DavaAppealJudgeAssignService.isAppealJudgeRole(widget.dava.mevkii);

  @override
  Widget build(BuildContext context) {
    final phaseColor = _cardPhaseColor();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: phaseColor,
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
        child: Padding(
            padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Dava Bilgileri
                _buildCaseInfo(),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(),
                
                const SizedBox(height: 24),
                
                // Mevki Seçimi - Sadece Kabul Et'e basıldığında göster
                if (showRoleSelection && isAccepted) ...[
                  _buildDashedLine(),
                  Center(
                    child: Text(
                      _isAppealJudgeAssignmentCard()
                          ? 'TEMYİZ HAKİMLİĞİ GÖREVİ'
                          : 'MEVKİNİZİ SEÇİNİZ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_isAppealJudgeAssignmentCard()) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Görevi çift tıklayarak kabul edin; ardından 8-Hüküm sayfasında karar verin. '
                        'Kabul etmezseniz görev başkasına verilmez, dava mevcut haliyle sonuçlanır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  _buildCaseInfoSeparator(),
                  const SizedBox(height: 8),
                  _buildRoleSelection(),
                ],
                
                // Seçilen Mevki Gösterimi
                if (isRoleConfirmed && selectedRole != null) ...[
                  _buildDashedLine(),
                  Center(
                    child: Text(
                      'SEÇİLEN MEVKİ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _buildCaseInfoSeparator(),
                  const SizedBox(height: 16),
                  _buildSelectedRoleDisplay(),
                  _buildCaseInfoSeparator(),
                  const SizedBox(height: 16),
                  // Zamanlayıcı Widget'ı
                  if (_acceptedAt != null)
                    CountdownTimerWidget(
                      startTime: _acceptedAt!,
                      totalDuration: _isAppealJudgeAssignmentCard()
                          ? DavaTimerService.appealJudgeDecisionWindow
                          : DavaTimerService.acceptedHukumWindow,
                      showHourglass: true,
                      onTimeUp: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⏰ Dava süresi doldu!'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Üst/alt bölüm sınırı (daha belirgin kesik çizgi)
  Widget _buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(
        painter: DashedLinePainter(color: Colors.green.shade300),
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }

  /// Satırlar / alt başlıklar arası (daha açık kesik çizgi)
  Widget _buildCaseInfoSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(
        painter: DashedLinePainter(color: Colors.green.shade100),
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }

  bool _davaliIsGuest() {
    final key = (widget.dava.davaliEmail ?? widget.dava.davali).trim();
    if (key.isEmpty) return false;
    if (!key.contains('@')) {
      return HiveDatabaseService.getRegistrationByEmail(key) == null &&
          HiveDatabaseService.getRegistrationByJudgeName(key) == null;
    }
    return HiveDatabaseService.getRegistrationByEmail(key) == null;
  }

  Widget _buildCaseInfo() {
    final guest = _davaliIsGuest();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCaseInfoRow(
            'Dava Adı',
            widget.dava.adi.isNotEmpty ? widget.dava.adi : 'Belirtilmedi',
            Icons.description,
          ),
          const SizedBox(height: 10),
          _buildYargilaStyleSeparator(),
          const SizedBox(height: 10),
          _buildCaseInfoRow(
            'Davacı',
            widget.dava.davaci.isNotEmpty ? widget.dava.davaci : 'Davacı Adı',
            Icons.person,
          ),
          const SizedBox(height: 10),
          _buildYargilaStyleSeparator(),
          const SizedBox(height: 10),
          _buildModernDavaliRow(guest),
          const SizedBox(height: 10),
          _buildYargilaStyleSeparator(),
          const SizedBox(height: 10),
          _buildStyledCountdownRow(),
        ],
      ),
    );
  }

  Widget _buildYargilaStyleSeparator() {
    return SizedBox(
      height: 10,
      child: CustomPaint(
        size: const Size(double.infinity, 10),
        painter: DashedLinePainter(
          color: const Color(0xFFD8E5DE),
          strokeWidth: 1.6,
        ),
      ),
    );
  }

  Widget _buildCaseInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDavaliRow(bool guest) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.person_outline,
          size: 20,
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Davalı',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.dava.davali.isNotEmpty ? widget.dava.davali : 'Davalı Adı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  if (guest) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Bu davalı WhoBoom üyesi değil (misafir)',
                      child: Icon(
                        Icons.person_off_outlined,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyledCountdownRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.hourglass_bottom,
          size: 20,
          color: Colors.green.shade700,
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
              _buildCountdownRow(),
            ],
          ),
        ),
      ],
    );
  }

  /// Geriye doğru sayan sayaç satırı (168 saatlik 3 aşamalı döngü segmenti)
  Widget _buildCountdownRow() {
    final openedAt = widget.dava.createdAt ?? DateTime.now();
    final segment = DavaTimerService.buildIncomingListCountdown(openedAt: openedAt);

    if (segment == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Süre :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Ana süreç ve temyiz penceresi tamamlandı.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            segment.phaseLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                'Süre :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: CountdownTimerWidget(
                startTime: segment.segmentStart,
                totalDuration: segment.totalDuration,
                accentColor: segment.accentColor,
                showHourglass: true,
                onTimeUp: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⏰ Bu fazın süresi doldu!'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'RED ET',
            isReject: true,
            onPressed: () {
              print('🔴 RED ET butonuna basıldı - Dava ID: ${widget.dava.id}');
              
              setState(() {
                isRejected = true;
                isAccepted = false;
                showRoleSelection = false;
                isRoleConfirmed = false;
                selectedRole = null;
              });
              
              if (_isAppealJudgeAssignmentCard()) {
                _handleAppealJudgeDeclined();
              } else {
                print('🔴 State güncellendi, dava taşıma işlemi başlatılıyor...');
                _moveDavaToKatildigim();
              }
              
              widget.onDavaRejected?.call();
              
              print('🔴 UI callback çağrıldı');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'KABUL ET',
            isReject: false,
            onPressed: () {
              setState(() {
                isAccepted = !isAccepted;
                if (isAccepted) {
                  isRejected = false;
                  // ADIM 1: Kullanıcının bu davada zaten bir görevi olup olmadığını kontrol et
                  _checkExistingRole().then((hasRole) {
                    if (hasRole && _hasExistingRole) {
                      // Kullanıcının zaten bir görevi varsa, görev seçimini engelle
                      setState(() {
                        isAccepted = false;
                        showRoleSelection = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bu davada zaten "$_existingRole" görevini seçtiniz. Aynı davada farklı bir görev seçemezsiniz.',
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    } else {
                      // Görev seçimine izin ver
                      setState(() {
                        showRoleSelection = true;
                        if (_isAppealJudgeAssignmentCard()) {
                          selectedRole = DavaAppealJudgeAssignService.appealJudgeRole;
                        }
                      });
                    }
                  });
                } else {
                  showRoleSelection = false;
                  isRoleConfirmed = false;
                  selectedRole = null;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isReject,
    required VoidCallback onPressed,
  }) {
    final isSelected = isReject ? isRejected : isAccepted;
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isSelected 
          ? (isReject ? Colors.red.shade50 : Colors.green.shade50)
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? (isReject ? Colors.red : Colors.green)
            : Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected 
                  ? (isReject ? Colors.red.shade700 : Colors.green.shade700)
                  : Colors.blue.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kullanıcının bu davada zaten bir görevi olup olmadığını kontrol et
  Future<bool> _checkExistingRole() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      return false;
    }
    
    try {
      final participants = await HiveDatabaseService.getDavaParticipants(widget.dava.id);
      final existingParticipant = participants.firstWhere(
        (p) => (p['userEmail']?.toString() ?? '').toLowerCase() == widget.userEmail!.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );
      
      if (existingParticipant.isNotEmpty) {
        final status = existingParticipant['status']?.toString() ?? '';
        final existingRole = existingParticipant['mevkii']?.toString() ?? '';
        
        if (status == 'accepted' && existingRole.isNotEmpty) {
          setState(() {
            _hasExistingRole = true;
            _existingRole = existingRole;
          });
          return true;
        }
      }
      
      setState(() {
        _hasExistingRole = false;
        _existingRole = null;
      });
      return false;
    } catch (e) {
      print('❌ [FiveCardCaseInformation] Katılımcı kontrolü sırasında hata: $e');
      return false;
    }
  }

  Widget _buildRoleSelection() {
    final List<Map<String, String>> roles;
    if (_isAppealJudgeAssignmentCard()) {
      roles = [
        {
          'label': DavaAppealJudgeAssignService.appealJudgeRole,
          'value': DavaAppealJudgeAssignService.appealJudgeRole,
        },
      ];
    } else {
      roles = DavaAutoAssignService.standardCaseRoles
          .map((r) => {'label': r, 'value': r})
          .toList();
    }

    return Column(
      children: roles.map((role) {
        final isSelected = selectedRole == role['label'];
        // Eğer kullanıcının zaten bir görevi varsa, butonları devre dışı bırak
        final isDisabled = _hasExistingRole;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isDisabled ? null : () {
                setState(() {
                  selectedRole = role['label'];
                });
              },
              onDoubleTap: () async {
                // Çift tıklama - mevkiyi onayla
                // ADIM 1: Kullanıcının bu davada zaten bir görevi olup olmadığını kontrol et
                if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
                  try {
                    final participants = await HiveDatabaseService.getDavaParticipants(widget.dava.id);
                    final existingParticipant = participants.firstWhere(
                      (p) => (p['userEmail']?.toString() ?? '').toLowerCase() == widget.userEmail!.toLowerCase(),
                      orElse: () => <String, dynamic>{},
                    );
                    
                    // Eğer kullanıcının bu davada zaten bir görevi varsa ve kabul edilmişse
                    if (existingParticipant.isNotEmpty) {
                      final status = existingParticipant['status']?.toString() ?? '';
                      final existingRole = existingParticipant['mevkii']?.toString() ?? '';
                      
                      if (status == 'accepted' && existingRole.isNotEmpty) {
                        // Kullanıcıya bilgi ver ve görev seçimini engelle
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Bu davada zaten "$existingRole" görevini seçtiniz. Aynı davada farklı bir görev seçemezsiniz.',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }
                    }
                  } catch (e) {
                    print('❌ [GelenDavalarPage] Katılımcı kontrolü sırasında hata: $e');
                    // Hata durumunda devam et (kullanıcı deneyimini bozmamak için)
                  }
                }

                final acceptedTime = DateTime.now();
                setState(() {
                  selectedRole = role['label'];
                  isRoleConfirmed = true;
                  showRoleSelection = false;
                  _acceptedAt = acceptedTime;
                });
                
                // Davayı kabul edilmiş olarak kaydet
                // ÖNEMLİ: 'id' alanı orijinal dava ID'si olmalı, yoksa gelen davalardan kaldırılamaz
                final davaData = {
                  'id': widget.dava.id, // Orijinal dava ID'si (yeni ID oluşturma!)
                  'davaId': widget.dava.id,
                  'adi': widget.dava.adi,
                  'davali': widget.dava.davali,
                  'mevkii': selectedRole,
                  'kalanSure': widget.dava.kalanSure,
                  'profilResmi': widget.dava.profilResmi,
                  'davaKonusu': widget.dava.davaKonusu,
                  'davaci': widget.dava.davaci,
                  'userEmail': widget.userEmail,
                  'userRole': selectedRole,
                  'status': 'accepted',
                  'acceptedAt': acceptedTime.toIso8601String(),
                  'createdAt': widget.dava.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                  'remainingHours': 76,
                  if (_isAppealJudgeAssignmentCard())
                    'isAppealJudgeAssignment': true,
                };
                
                print('✅ [GelenDavalarPage] Dava kabul ediliyor:');
                print('   - Dava ID: ${widget.dava.id}');
                print('   - Dava Adı: ${widget.dava.adi}');
                print('   - Seçilen Görev: $selectedRole');
                print('   - User Email: ${widget.userEmail}');
                
                // Provider üzerinden davayı kabul edilenlere ekle
                // Bu metod otomatik olarak gelen davalardan kaldırır
                final davaProvider = Provider.of<DavaProvider>(context, listen: false);
                final success = await davaProvider.acceptDava(davaData);
                
                if (success) {
                  print('✅ [GelenDavalarPage] Dava başarıyla kabul edildi ve gelen davalardan kaldırıldı');

                  if (_isAppealJudgeAssignmentCard()) {
                    await HiveDatabaseService.updateOpenedDava(widget.dava.id, {
                      'appealJudgeAssignmentPending': false,
                      'appealJudgeAcceptedAt': acceptedTime.toIso8601String(),
                    });
                    if (widget.userEmail != null &&
                        widget.userEmail!.isNotEmpty) {
                      await HiveDatabaseService.markDavaParticipantStatus(
                        davaId: widget.dava.id,
                        userEmail: widget.userEmail!,
                        status: 'accepted',
                        reason: 'appeal_judge_accepted',
                        extra: {
                          'mevkii': selectedRole,
                          'userRole': selectedRole,
                          'acceptedAt': acceptedTime.toIso8601String(),
                          'isAppealJudgeAssignment': true,
                        },
                      );
                    }
                  }

                  // Katıldığım Davalar: açılmış orijinal dava + seçilen görev (ör. 1.Jüri)
                  if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
                    final opened = HiveDatabaseService.getOpenedDavaById(widget.dava.id);
                    final katildigimKayit = Map<String, dynamic>.from(davaData);
                    katildigimKayit['davaAdi'] = widget.dava.adi;
                    katildigimKayit['isAccepted'] = true;
                    katildigimKayit['isRejected'] = false;
                    katildigimKayit['source'] = 'gelen_davalar_accept';
                    if (opened != null) {
                      final kat = opened['kategori'] ?? opened['davaKategorisi'];
                      if (kat != null && kat.toString().trim().isNotEmpty) {
                        katildigimKayit['kategori'] = kat;
                        katildigimKayit['davaKategori'] = kat;
                      }
                      final oa = opened['openedAt']?.toString();
                      if (oa != null && oa.isNotEmpty) {
                        katildigimKayit['openedAt'] = oa;
                      }
                      if (opened['isOpened'] != null) {
                        katildigimKayit['isOpened'] = opened['isOpened'];
                      }
                    } else {
                      katildigimKayit['openedAt'] =
                          katildigimKayit['acceptedAt']?.toString();
                      katildigimKayit['isOpened'] = true;
                    }
                    await HiveDatabaseService.removeKatildigimDava(
                      widget.userEmail!,
                      widget.dava.id,
                    );
                    await HiveDatabaseService.addKatildigimDava(
                      widget.userEmail!,
                      katildigimKayit,
                    );
                    await davaProvider.reloadKatildigimDavalar(widget.userEmail!);
                  }
                  
                  // UI'dan dava kartını kaldır (callback ile)
                  widget.onDavaRejected?.call();
                  
                  // Gelen davalar listesini yeniden yükle (Provider'dan)
                  if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
                    await davaProvider.loadUserData(widget.userEmail!);
                  }
                } else {
                  print('❌ [GelenDavalarPage] Dava kabul edilirken hata oluştu');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Dava kabul edilirken hata oluştu. Lütfen tekrar deneyin.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }
                
                // Yargıla sayfasına yönlendir
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YargilaPage(userEmail: widget.userEmail),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: isDisabled 
                    ? Colors.grey.shade200 
                    : (isSelected ? Colors.green.shade50 : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDisabled 
                      ? Colors.grey.shade400 
                      : (isSelected ? Colors.green : Colors.grey.shade300),
                    width: 1,
                  ),
                ),
                child: Row(
                    children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDisabled 
                            ? Colors.grey.shade400 
                            : (isSelected ? Colors.green : Colors.grey.shade400),
                          width: 2,
                        ),
                        color: isDisabled 
                          ? Colors.grey.shade300 
                          : (isSelected ? Colors.green : Colors.transparent),
                      ),
                      child: isDisabled
                        ? const Icon(Icons.block, size: 12, color: Colors.grey)
                        : (isSelected
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${role['label']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDisabled 
                            ? Colors.grey.shade500 
                            : (isSelected ? Colors.green.shade700 : Colors.grey.shade800),
                        ),
                      ),
                    ),
                    // Çift tıklama ipucu
                    if (!isRoleConfirmed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Çift tıkla',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedRoleDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 12),
          Text(
            'Seçilen Mevki:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedRole ?? '',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Mevki Onaylandı ✓',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
                ),
        ),
      ],
      ),
    );
  }


  /// Temyiz hakimi görevi reddedildi: yeniden atama yok, dava mevcut haliyle kalır.
  Future<void> _handleAppealJudgeDeclined() async {
    try {
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        await HiveDatabaseService.markDavaParticipantStatus(
          davaId: widget.dava.id,
          userEmail: widget.userEmail!,
          status: 'manual_rejected',
          reason: 'appeal_judge_declined',
          extra: {
            'mevkii': widget.dava.mevkii.isNotEmpty
                ? widget.dava.mevkii
                : DavaAppealJudgeAssignService.appealJudgeRole,
            'isAppealJudgeAssignment': true,
          },
        );
      }

      await HiveDatabaseService.updateOpenedDava(widget.dava.id, {
        'appealJudgeAssignmentPending': false,
        'appealJudgeDeclined': true,
        'appealJudgeDeclinedAt': DateTime.now().toIso8601String(),
      });

      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        await HiveDatabaseService.removeIncomingDavaForUser(
          widget.userEmail!,
          widget.dava.id,
        );
      }
    } catch (e) {
      print('❌ Temyiz hakimi görevi reddi kaydedilemedi: $e');
    }
  }

  /// Dava reddedildiğinde katıldığım davalar sayfasına ekle
  void _moveDavaToKatildigim() async {
    print('🔄 _moveDavaToKatildigim başlatıldı - Dava: ${widget.dava.adi}');
    
    try {
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        await HiveDatabaseService.markDavaParticipantStatus(
          davaId: widget.dava.id,
          userEmail: widget.userEmail!,
          status: 'manual_rejected',
          reason: 'user_rejected',
          extra: {
            if (widget.dava.mevkii.isNotEmpty) 'mevkii': widget.dava.mevkii,
          },
        );
      }

      final reg = widget.userEmail != null
          ? HiveDatabaseService.getRegistrationByEmail(widget.userEmail!)
          : null;
      final mevkiiLabel =
          widget.dava.mevkii.isNotEmpty ? widget.dava.mevkii : 'Katılımcı';
      final kisiAdi = reg?.judgeName ??
          (widget.userEmail?.split('@').first ?? 'Kullanıcı');
      final davaciAd =
          widget.dava.davaci.isNotEmpty ? widget.dava.davaci : 'Davacı';
      final davaliAd =
          widget.dava.davali.isNotEmpty ? widget.dava.davali : 'Davalı';
      final davaAdi = widget.dava.adi.isNotEmpty ? widget.dava.adi : 'Dava';
      final narrative =
          '"$mevkiiLabel" "$kisiAdi", vicdanıyla girdiği düelloyu kaybettiği için '
          '"$davaciAd"\'in "$davaliAd"\'ya açtığı "$davaAdi" davasından çekilmek zorunda kalmıştır.';

      await HiveDatabaseService.appendWithdrawalNarrative(widget.dava.id, narrative);
      await HiveDatabaseService.appendDavaHistoryEvent(widget.dava.id, {
        'type': 'withdraw_reject',
        'userEmail': widget.userEmail,
        'mevkii': mevkiiLabel,
        'narrative': narrative,
      });
      await HiveDatabaseService.updateOpenedDava(widget.dava.id, {
        'davaOverallStatus': 'Reddedildi/Çekildi',
      });
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        await HiveDatabaseService.saveHukum(
          davaId: widget.dava.id,
          userRole: mevkiiLabel,
          hukumText: narrative,
          userEmail: widget.userEmail!,
          hukumSentiment: 'positive',
          isFinalized: true,
        );
      }

      // Dava verilerini hazırla
      final davaData = {
        'id': widget.dava.id,
        'adi': widget.dava.adi,
        'davaAdi': widget.dava.adi,
        'davaKonusu': widget.dava.davaKonusu,
        'davaci': widget.dava.davaci,
        'davali': widget.dava.davali,
        'displayName': widget.dava.davaci,
        'userEmail': widget.userEmail ?? '',
        'mevkii': 'Katılımcı', // Red edilen dava katıldığım davalar sayfasında
        'kalanSure': DateTime.now().add(const Duration(days: 3)).toIso8601String(), // 3 gün sonra
        'profilResmi': widget.dava.profilResmi,
        'openedAt': DateTime.now().toIso8601String(),
        'acceptedAt': DateTime.now().toIso8601String(), // Kabul edildi olarak işaretle
        'kategori': 'Genel',
        'davaKategori': 'Genel',
        'source': 'gelen_davalar_page', // Kaynak bilgisi
        'isAccepted': true, // Kabul edilmiş olarak işaretle
        'isRejected': false, // Red edilmiş ama katıldığım davalar sayfasında
        'status': 'Reddedildi/Çekildi',
      };

      print('💾 Dava verileri hazırlandı, veritabanına kaydediliyor...');
      
      // Katıldığım davalar sayfasına ekle
      await HiveDatabaseService.addKatildigimDava(widget.userEmail!, davaData);
      print('✅ Dava katıldığım davalar sayfasına eklendi');
      
      // Provider'ı güncelle
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      await davaProvider.reloadKatildigimDavalar(widget.userEmail!);
      print('✅ Katıldığım davalar provider güncellendi');
      
      // Gelen davalar sayfasından kaldır
      await _removeFromGelenDavalar();
      print('✅ Dava gelen davalar sayfasından kaldırıldı');
      
      // Gelen davalar provider'ını da güncelle
      final gelenDavaProvider = Provider.of<DavaProvider>(context, listen: false);
      await gelenDavaProvider.reloadIncomingDavalar(widget.userEmail!);
      print('✅ Gelen davalar provider güncellendi');
      
      print('✅ Dava katıldığım davalar sayfasına taşındı: ${widget.dava.adi}');
      
      // Kullanıcıya bildirim göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Dava reddedildi - Katıldığım Davalar sayfasına taşındı'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Katıldığım Davalar',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KatildigimDavalarPage(userEmail: widget.userEmail),
                ),
              );
            },
          ),
        ),
      );
      
    } catch (e) {
      print('❌ Dava taşınırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Dava taşınırken hata oluştu: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Gelen davalar sayfasından dava kaldır
  Future<void> _removeFromGelenDavalar() async {
    try {
      // Gelen davalar listesinden kaldır
      await HiveDatabaseService.removeIncomingDava(widget.dava.id);
      
      // Provider güncelleme - sayfa yeniden yüklenecek
      
      print('✅ Dava gelen davalar sayfasından kaldırıldı: ${widget.dava.id}');
      
    } catch (e) {
      print('❌ Gelen davalar sayfasından kaldırılırken hata: $e');
    }
  }

}

/// Dashed Line Painter for creating dashed borders
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Menü, sayfa başlığı ve gelen dava sayısı rozetini tek satırda hizalar.
class GelenDavalarHeadlineRow extends StatelessWidget {
  final VoidCallback onMenuPressed;

  const GelenDavalarHeadlineRow({
    super.key,
    required this.onMenuPressed,
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
