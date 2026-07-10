import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/evidence_viewer_widget.dart';
import '../services/dava_hukum_eligibility_service.dart';
import '../services/dava_timer_service.dart';
import '../services/hive_database_service.dart';

// Model class for Dava (delil için de kullanılabilir)
class Dava {
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;

  Dava({
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
  });
}

/// Delilleri İncele Sayfası
/// Yargıla sayfasından erişilen, dava delillerini görüntüleme sayfası
/// Modern EvidenceViewerWidget kullanır
class DelilleriIncelePage extends StatefulWidget {
  final String? userEmail;
  final String? davaId; // Opsiyonel dava ID - null ise kabul edilen davalar gösterilir

  const DelilleriIncelePage({
    super.key,
    this.userEmail,
    this.davaId,
  });

  @override
  State<DelilleriIncelePage> createState() => _DelilleriIncelePageState();
}

class _DelilleriIncelePageState extends State<DelilleriIncelePage> {
  List<Map<String, dynamic>> _acceptedDavalar = [];
  bool _isLoading = true;
  String? _selectedDavaId; // Deliller için kullanılan gerçek davaId
  String? _selectedDropdownValue; // Dropdown için benzersiz değer
  /// Yargıla — Dava Künyesi ile aynı daraltılabilir üst panel (sayfa açılışında kapalı)
  bool _delillerKunyeExpanded = false;
  /// Künye içinde Dava Konusu metni — varsayılan kapalı
  bool _davaKonusuExpanded = false;

  @override
  void initState() {
    super.initState();
    // Eğer widget'tan davaId gelmişse onu kullan
    // Ama önce accepted davaları yükleyip davaId alanını kontrol etmeliyiz
    _selectedDavaId = widget.davaId;
    _loadAcceptedDavalar();
  }

  /// Kabul edilen davaları yükle
  Future<void> _loadAcceptedDavalar() async {
    try {
      final acceptedDavalar = await HiveDatabaseService.getAcceptedDavalar(
        widget.userEmail ?? '',
      );
      
      setState(() {
        _acceptedDavalar = acceptedDavalar;
        _isLoading = false;
        
        // Eğer widget'tan davaId gelmişse, accepted davalar içinde eşleşeni bul
        if (widget.davaId != null && _acceptedDavalar.isNotEmpty) {
          // Önce davaId ile eşleşen dava ara
          final matchingIndex = _acceptedDavalar.indexWhere(
            (dava) {
              final davaId = (dava['davaId'] as String?) ?? (dava['id'] as String?);
              return davaId?.trim().toLowerCase() == widget.davaId!.trim().toLowerCase() ||
                     (dava['id'] as String?)?.trim().toLowerCase() == widget.davaId!.trim().toLowerCase();
            },
          );
          
          if (matchingIndex != -1) {
            final matchingDava = _acceptedDavalar[matchingIndex];
            _selectedDavaId = (matchingDava['davaId'] as String?) ?? 
                             (matchingDava['id'] as String?);
            // Dropdown için benzersiz değer oluştur
            _selectedDropdownValue = (matchingDava['id'] as String?) ?? 
                                    '${matchingDava['davaId'] as String? ?? 'dava'}_$matchingIndex';
            print('🔍 Widget davaId ile eşleşen dava bulundu: $_selectedDavaId');
          }
        }
        
        // Eğer dava ID belirtilmemişse ve listede dava varsa ilkini seç
        // Önce davaId alanını dene, yoksa id kullan
        if (_selectedDavaId == null && _acceptedDavalar.isNotEmpty) {
          final firstDava = _acceptedDavalar.first;
          const firstIndex = 0;
          _selectedDavaId = (firstDava['davaId'] as String?) ?? 
                           (firstDava['id'] as String?);
          // Dropdown için benzersiz değer oluştur
          _selectedDropdownValue = (firstDava['id'] as String?) ?? 
                                  '${firstDava['davaId'] as String? ?? 'dava'}_$firstIndex';
          print('🔍 İlk dava seçildi: $_selectedDavaId');
        }
      });
      
      print('✅ ${_acceptedDavalar.length} kabul edilmiş dava yüklendi');
      if (_selectedDavaId != null) {
        print('🔍 Seçili dava ID: $_selectedDavaId');
      }
    } catch (e) {
      print('❌ Davalar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

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
                    // Delilleri incele sayfasında kaydedilen davalar dialog'u açılamaz
                    // Bu sayfa sadece delil inceleme işlemleri için
                  },
                ),
              ),
              // Dava Künyesi (Yargıla) ile uyumlu üst panel + delil görüntüleyici
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_acceptedDavalar.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                        Icon(
                          MdiIcons.gavel,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz kabul edilmiş dava yok',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dava kabul ettiğinizde delillerini buradan inceleyebilirsiniz',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        ],
                      ),
                    ),
                )
              else
                _buildDelillerMainPanel(context),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _resolveSelectedDava() {
    if (_selectedDavaId == null) return null;
    final want = _selectedDavaId!.trim().toLowerCase();
    for (final d in _acceptedDavalar) {
      final id = ((d['davaId'] as String?) ?? (d['id'] as String?))?.trim().toLowerCase();
      if (id != null && id == want) return d;
    }
    return null;
  }

  /// Yargıla `ModernYargilaCard` / Dava Künyesi ile aynı görsel dil
  Widget _buildDelillerMainPanel(BuildContext context) {
    const borderColor = Color(0xFFDDE9E2);
    const innerBorder = Color(0xFFDCE7E1);
    const dashColor = Color(0xFFD8E5DE);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101815).withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: 26,
                    color: Colors.green.shade700,
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Geri',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: innerBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _delillerKunyeExpanded = !_delillerKunyeExpanded);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.content_paste_search,
                                color: Colors.blue.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    ' || Delilleri İncele ||',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                      color: Color(0xFF1B2A23),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _delillerKunyeExpanded ? 0.5 : 0,
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
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: _delillerKunyeExpanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: _buildKunyeExpandedBody(dashColor),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (_acceptedDavalar.length > 1) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FBF8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: innerBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDropdownValue,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.green.shade700,
                      ),
                      items: _acceptedDavalar.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dava = entry.value;
                        final uniqueValue = (dava['id'] as String?) ??
                            '${dava['davaId'] as String? ?? 'dava'}_$index';
                        return DropdownMenuItem<String>(
                          value: uniqueValue,
                          child: Text(
                            dava['adi'] as String? ?? 'İsimsiz Dava',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDropdownValue = newValue;
                          if (newValue != null) {
                            final selectedIndex = _acceptedDavalar.asMap().entries.firstWhere(
                              (entry) {
                                final index = entry.key;
                                final dava = entry.value;
                                final uniqueValue = (dava['id'] as String?) ??
                                    '${dava['davaId'] as String? ?? 'dava'}_$index';
                                return uniqueValue == newValue;
                              },
                              orElse: () => _acceptedDavalar.asMap().entries.first,
                            );

                            final selectedDava = selectedIndex.value;
                            _selectedDavaId = (selectedDava['davaId'] as String?) ??
                                (selectedDava['id'] as String?);
                            _davaKonusuExpanded = false;
                            print('🔍 Dava seçildi - Dropdown: $newValue, DavaId: $_selectedDavaId');
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (_selectedDavaId != null)
                EvidenceViewerWidget(
                  key: ValueKey(_selectedDavaId),
                  davaId: _selectedDavaId!.trim(),
                  userEmail: widget.userEmail,
                  userRole: (_acceptedDavalar.firstWhere(
                    (dava) =>
                        ((dava['davaId'] as String?) ?? (dava['id'] as String?))?.trim() ==
                        _selectedDavaId?.trim(),
                    orElse: () => <String, dynamic>{},
                  )['userRole'] as String?),
                  showCaseInfo: false,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKunyeExpandedBody(Color dashColor) {
    final d = _resolveSelectedDava();
    if (d == null) {
      return Text(
        'Dava bilgisi yüklenemedi veya henüz seçilmedi.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildKunyeInfoRow(
          'Göreviniz',
          d['userRole'] as String? ?? '-',
          Icons.gavel_outlined,
        ),
        const SizedBox(height: 3),
        _buildKunyeDashedLine(dashColor),
        const SizedBox(height: 3),
        _buildKunyeInfoRow('Dava Adı', d['adi'] as String? ?? '-', Icons.description),
        const SizedBox(height: 3),
        _buildKunyeDashedLine(dashColor),
        const SizedBox(height: 3),
        _buildKunyeInfoRow('Davacı', d['davaci'] as String? ?? '-', Icons.person),
        const SizedBox(height: 3),
        _buildKunyeDashedLine(dashColor),
        const SizedBox(height: 3),
        _buildKunyeInfoRow('Davalı', d['davali'] as String? ?? '-', Icons.person_outline),
        _buildKunyeDavaKonusuSection(d, dashColor),
        const SizedBox(height: 3),
        _buildKunyeDashedLine(dashColor),
        const SizedBox(height: 3),
        _buildKalanSureItem(d),
      ],
    );
  }

  /// Dava konusu: varsayılan kapalı, başlığa dokununca metin açılır
  Widget _buildKunyeDavaKonusuSection(Map<String, dynamic> d, Color dashColor) {
    final konusu = (d['davaKonusu'] as String?)?.trim() ?? '';
    if (konusu.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 3),
        _buildKunyeDashedLine(dashColor),
        const SizedBox(height: 3),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _davaKonusuExpanded = !_davaKonusuExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Icon(Icons.article_outlined, size: 20, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dava Konusu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _davaKonusuExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.expand_more, color: Colors.grey.shade600, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _davaKonusuExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 8, 4),
                  child: SelectableText(
                    konusu,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                      height: 1.45,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildKunyeDashedLine(Color color) {
    return SizedBox(
      height: 10,
      child: CustomPaint(
        size: const Size(double.infinity, 10),
        painter: KunyeDashedLinePainter(color: color, strokeWidth: 1.6),
      ),
    );
  }

  Widget _buildKunyeInfoRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlight ? Colors.red.shade600 : Colors.green.shade700,
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
                  color: isHighlight ? Colors.red.shade700 : Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bilgi item widget'ı
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue[700],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime? _extractOpenedAt(Map<String, dynamic> dava) {
    return _parseDate(dava['openedAt']) ??
        _parseDate(dava['acceptedAt']) ??
        _parseDate(dava['createdAt']);
  }

  Widget _buildKalanSureItem(Map<String, dynamic> selectedDava) {
    final davaId =
        ((selectedDava['davaId'] as String?) ?? (selectedDava['id'] as String?))
                ?.trim() ??
            '';
    final openedAt = _extractOpenedAt(selectedDava);
    final fallbackText = selectedDava['kalanSure'] as String? ?? '-';

    if (openedAt == null) {
      return _buildInfoItem('Kalan Süre', fallbackText, MdiIcons.timerSand);
    }

    final openedFromDb =
        davaId.isEmpty ? null : HiveDatabaseService.getOpenedDavaById(davaId);
    final isAppealActive =
        DavaHukumEligibilityService.isAppealJudgeWindowActive(openedFromDb);

    if (isAppealActive) {
      final appealRequestedAt = _parseDate(openedFromDb?['appealRequestedAt']);
      if (appealRequestedAt != null) {
        return _buildTimerInfoItem(
          label: 'Kalan Süre',
          subtitle: 'Temyiz',
          icon: MdiIcons.timerSand,
          startTime: appealRequestedAt,
          totalDuration: DavaTimerService.appealJudgeDecisionWindow,
          accentColor: Colors.deepPurple.shade700,
        );
      }
    }

    final segment = DavaTimerService.buildIncomingListCountdown(
      openedAt: openedAt,
    );
    if (segment != null) {
      return _buildTimerInfoItem(
        label: 'Kalan Süre',
        subtitle: segment.phaseLabel,
        icon: MdiIcons.timerSand,
        startTime: segment.segmentStart,
        totalDuration: segment.totalDuration,
        accentColor: segment.accentColor,
      );
    }

    return _buildInfoItem('Kalan Süre', 'Süre doldu', MdiIcons.timerSandComplete);
  }

  Widget _buildTimerInfoItem({
    required String label,
    required String subtitle,
    required IconData icon,
    required DateTime startTime,
    required Duration totalDuration,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue[700],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              CountdownTimerWidget(
                startTime: startTime,
                totalDuration: totalDuration,
                accentColor: accentColor,
                showHourglass: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Yargıla sayfasındaki `DashedLinePainter` ile aynı çizgi stili
class KunyeDashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  KunyeDashedLinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 6.0;
    final y = size.height / 2;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Reused Widgets from GelenDavalarPage

class FiveCardCaseInformation extends StatelessWidget {
  final Dava dava;
  final VoidCallback? onTap;

  const FiveCardCaseInformation({super.key, required this.dava, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 19,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Haklı... ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Image.asset(dava.profilResmi, width: 60, height: 50),
                      ),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_down_off_alt_outlined,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Haksız ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Dava Adı    :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(dava.adi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Davalı :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(child: Text(dava.davali, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                const Spacer(),
                                const Icon(Icons.thumb_up_alt_outlined, size: 25, color: Colors.green),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Görev        :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(dava.mevkii, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text('Kalan Süre :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              dava.kalanSure,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                            child:Icon(MdiIcons.gavel, size: 19, color: Colors.black54),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
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
