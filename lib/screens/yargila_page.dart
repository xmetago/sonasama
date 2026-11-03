import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/yargila_case_card.dart';
import '../widgets/modern_yargila_card.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import 'cezalar_page.dart';

export '../widgets/yargila_case_card.dart' show Dava, FiveCardCaseInformation;
export '../widgets/modern_yargila_card.dart' show ModernYargilaCard, DashedLinePainter;

// Yargıla Sayfası
class YargilaPage extends StatefulWidget {
  final String? userEmail;

  const YargilaPage({super.key, this.userEmail});

  @override
  State<YargilaPage> createState() => _YargilaPageState();
}

class _YargilaPageState extends State<YargilaPage> {
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int dislikeCount = 0;
  bool showLeftIcons = false;
  List<Dava> _davaList = [];
  final Map<String, TextEditingController> _hukumControllers = {}; // Her dava için ayrı controller
  final Map<String, bool> _isHukumExpanded = {}; // Her dava için ayrı expanded durumu
  final Map<String, int> _hukumCharacterCounts = {}; // Her dava için karakter sayısı
  final Map<String, DateTime?> _davaAcceptedAt = {}; // Her dava için açılış tarihi

  @override
  void initState() {
    super.initState();
    _loadAcceptedDavalar();
  }

  void _loadAcceptedDavalar() async {
    final acceptedDavalar = await HiveDatabaseService.getAcceptedDavalar(widget.userEmail ?? '');
    setState(() {
      _davaAcceptedAt.clear();
      final List<Dava> yeniDavaListesi = [];

      for (final Map<String, dynamic> davaMap in acceptedDavalar) {
        final String davaId = (davaMap['id'] ?? '').toString();
        final openedMeta = HiveDatabaseService.getOpenedDavaById(davaId);
        if (openedMeta != null && openedMeta['isArchived'] == true) {
          continue;
        }
        if (openedMeta != null &&
            openedMeta['davaOverallStatus']?.toString() ==
                'Reddedildi/Çekildi') {
          continue;
        }
        final DateTime? acceptedAt = _parseDateTimeOrNull(
              davaMap['acceptedAt'],
            ) ??
            _parseDateTimeOrNull(davaMap['statusUpdatedAt']) ??
            _parseDateTimeOrNull(davaMap['createdAt']);

        final Dava dava = Dava(
          id: davaId,
          adi: (davaMap['adi'] ?? '').toString(),
          davali: (davaMap['davali'] ?? '').toString(),
          mevkii: (davaMap['mevkii'] ?? '').toString(),
          kalanSure: (davaMap['kalanSure'] ?? '').toString(),
          profilResmi:
              (davaMap['profilResmi'] ?? 'lib/icons/03_davala_ana_icon.png')
                  .toString(),
          davaKonusu: (davaMap['davaKonusu'] ?? '').toString(),
          davaci: (davaMap['davaci'] ?? '').toString(),
          userRole: (davaMap['userRole'] ?? '').toString(),
        );

        yeniDavaListesi.add(dava);
        _davaAcceptedAt[davaId] = acceptedAt;

        _hukumControllers.putIfAbsent(dava.id, () => TextEditingController());
        _isHukumExpanded.putIfAbsent(dava.id, () => false);
        _hukumCharacterCounts[dava.id] = _hukumControllers[dava.id]!.text.length;
      }

      _davaList = yeniDavaListesi;
    });
  }

  DateTime? _parseDateTimeOrNull(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Widget _buildIconCounter(IconData icon, int count, VoidCallback onPressed) {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon, size: 24, color: Colors.green.shade700),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.10),
            padding: const EdgeInsets.all(10),
          ),
        ),
        Text('$count', style: const TextStyle(color: Colors.green)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Minimum alan kaplaması için
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
                    if (widget.userEmail != null) {
                      showSavedDavalarDialog(context, widget.userEmail!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı e-posta adresi bulunamadı!')),
                      );
                    }
                  },
                ),
              ),
              // ROW 4: Hamburger Iconu, Checkbox ve bilgi satırı
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        MdiIcons.menuOpen,
                        size: 19,
                        color: Colors.red.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          showLeftIcons = !showLeftIcons;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.10),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),

                    // Fixed YARGILA Row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "YARGILA ||",
                            style: TextStyle(
                              fontSize: 22,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Color(0xFF2F3E35),
                            ),
                          ),

                          Image.asset(
                            'lib/icons/06_yargila_left_row_icon.png',
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


              // ROW 5: 6 Icon Solda, Sağda Card ile Dava Bilgileri
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
                            const Padding(
                              padding: EdgeInsets.fromLTRB(8.0, 18.0, 8.0, 8.0),
                              child: Icon(Icons.save_outlined, size: 24, color: Colors.black54),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                              child: IconButton(
                                icon: Icon(
                                  MdiIcons.briefcaseEditOutline,
                                  size: 26,
                                  color: Colors.blue.shade700,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CezalarPage(userEmail: widget.userEmail)),
                                  );
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.10),
                                  padding: const EdgeInsets.all(10),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
                              child: IconButton(
                                icon: Icon(
                                  MdiIcons.handcuffs,
                                  size: 26,
                                  color: Colors.blueGrey.shade700,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CezalarPage(userEmail: widget.userEmail)),
                                  );
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blueGrey.withOpacity(0.10),
                                  padding: const EdgeInsets.all(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: _davaList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      MdiIcons.gavel,
                                      size: 80,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Henüz yargılanacak dava yok',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Kabul ettiğiniz davalar burada görünecek',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _davaList.length,
                              itemBuilder: (context, index) {
                                final dava = _davaList[index];
                                final controller = _hukumControllers[dava.id]!;
                                final isExpanded = _isHukumExpanded[dava.id] ?? false;
                                final DateTime? acceptedAt = _davaAcceptedAt[dava.id];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1.0),
                                      child: ModernYargilaCard(
                                        dava: dava,
                                        userEmail: widget.userEmail,
                                        acceptedAt: acceptedAt,
                                        onTap: () {
                                          setState(() {
                                            _isHukumExpanded[dava.id] = !( _isHukumExpanded[dava.id] ?? false);
                                          });
                                        },
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: isExpanded
                                          ? Padding(
                                              key: ValueKey('${dava.id}_expanded'),
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                              child: _buildHukumComposer(dava, controller),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                );
                              },
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
  }

  Widget _buildHukumComposer(Dava dava, TextEditingController controller) {
    final characterCount = _hukumCharacterCounts[dava.id] ?? controller.text.length;
    const maxChars = 1500;
    final remaining = maxChars - characterCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E6), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1A17).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.balance,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HÜKMÜNÜ BURAYA YAZ',
                      style: TextStyle(
                        color: const Color(0xFF1B2A23),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Davacı ${dava.davaci.isNotEmpty ? dava.davaci : ' '} ile davalı ${dava.davali.isNotEmpty ? dava.davali : ' '} arasındaki uyuşmazlık için son söz sizde.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDashedLine(Colors.green.shade300),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE8DF)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: TextField(
              controller: controller,
              maxLength: maxChars,
              maxLines: null,
              minLines: 6,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF111111)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Hükmünüzü ayrıntılı olarak yazın. Deliller, tanık ifadeleri ve vicdani kanaatinizi not edin...',
                hintStyle: TextStyle(color: Color(0xFF9AA5B1), fontSize: 15),
                counterText: '',
              ),
              onChanged: (value) {
                setState(() {
                  _hukumCharacterCounts[dava.id] = value.length;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  remaining >= 0
                      ? 'Kalan karakter: $remaining'
                      : 'Karakter sınırı aşıldı',
                  style: TextStyle(
                    color: remaining >= 0 ? Colors.green.shade800 : const Color(0xFFB42318),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  // TODO: Hüküm kaydetme iş akışı burada gerçekleştirilecek.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hüküm kaydetme işlemi yakında eklenecek.'),
                      backgroundColor: Color(0xFF2D6A4F),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Hükmümü Kayda Geçir',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine(Color color) {
    return SizedBox(
      height: 10,
      child: CustomPaint(
        size: const Size(double.infinity, 10),
        painter: DashedLinePainter(color: color, strokeWidth: 1.6),
      ),
    );
  }
}
