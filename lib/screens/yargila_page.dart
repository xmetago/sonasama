import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import '../models/sekiz_hukum_arguments.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import '../widgets/yargila_case_card.dart';
import '../widgets/modern_yargila_card.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import 'cezalar_page.dart';
import 'sekiz_hukum_page.dart';

export '../widgets/yargila_case_card.dart' show Dava, FiveCardCaseInformation;
export '../widgets/modern_yargila_card.dart' show ModernYargilaCard, DashedLinePainter;

// Yargıla Sayfası
class YargilaPage extends StatefulWidget {
  final String? userEmail;

  /// Test: kabul edilen davalar yüklenemesin.
  final bool forceLoadError;

  /// Test: yükleme göstergesinde kalsın.
  final bool forceLoading;

  const YargilaPage({
    super.key,
    this.userEmail,
    this.forceLoadError = false,
    this.forceLoading = false,
  });

  @override
  State<YargilaPage> createState() => _YargilaPageState();
}

class _YargilaPageState extends State<YargilaPage> {
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int dislikeCount = 0;
  List<Dava> _davaList = [];
  bool _isLoading = true;
  String? _loadError;
  final Map<String, TextEditingController> _hukumControllers = {}; // Her dava için ayrı controller
  final Map<String, bool> _isHukumExpanded = {}; // Her dava için ayrı expanded durumu
  final Map<String, int> _hukumCharacterCounts = {}; // Her dava için karakter sayısı
  final Map<String, DateTime?> _davaAcceptedAt = {}; // Her dava için açılış tarihi

  @override
  void initState() {
    super.initState();
    if (widget.forceLoading) return;
    _loadAcceptedDavalar();
  }

  Future<void> _loadAcceptedDavalar() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      if (widget.forceLoadError) {
        throw Exception('Yargılanacak davalar yüklenemedi');
      }
      final acceptedDavalar =
          await HiveDatabaseService.getAcceptedDavalar(widget.userEmail ?? '');
      if (!mounted) return;
      setState(() {
        _applyAcceptedDavalar(acceptedDavalar);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Yargılanacak davalar yüklenemedi';
        _davaList = [];
      });
    }
  }

  void _applyAcceptedDavalar(List<Map<String, dynamic>> acceptedDavalar) {
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
  }

  Dava? get _caseForCezalar {
    for (final Dava dava in _davaList) {
      if (_isHukumExpanded[dava.id] == true) return dava;
    }
    if (_davaList.isEmpty) return null;
    return _davaList.first;
  }

  void _openCezalar() {
    final Dava? dava = _caseForCezalar;
    final String id = dava?.id.trim() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CezalarPage(
          userEmail: widget.userEmail,
          davaId: id.isEmpty ? null : id,
          davaAdi: dava?.adi ?? '',
          davaDavali: dava?.davali ?? '',
          davaDavaci: dava?.davaci ?? '',
          davaGorev: dava?.mevkii ?? '',
          kalanSure: dava?.kalanSure ?? '',
          davaOpenedAt: dava == null ? null : _davaAcceptedAt[dava.id],
        ),
      ),
    );
  }

  void _openSekizHukum(Dava dava) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SekizHukumPage(
          userEmail: widget.userEmail,
          arguments: SekizHukumArguments(
            davaId: dava.id.isNotEmpty ? dava.id : null,
            davaAdi: dava.adi.isNotEmpty ? dava.adi : 'Dava adı belirtilmedi',
            davaDavali:
                dava.davali.isNotEmpty ? dava.davali : 'Davalı bilgisi yok',
            davaDavaci:
                dava.davaci.isNotEmpty ? dava.davaci : 'Davacı bilgisi yok',
            davaGorev: dava.mevkii.isNotEmpty ? dava.mevkii : 'Görev bilgisi yok',
            kalanSure:
                dava.kalanSure.isNotEmpty ? dava.kalanSure : 'Süre bilgisi yok',
            openedAt: _davaAcceptedAt[dava.id],
          ),
        ),
      ),
    );
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
    final SeyirPalette palette = SeyirPalette.of(context);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: AppExpandableIconMenu(
            bodyPadding: const EdgeInsets.all(8),
            items: _yargilaMenuItems(),
            headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
              return Column(
            mainAxisSize: MainAxisSize.min,
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
                      onPressed: toggle,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.10),
                        padding: const EdgeInsets.all(10),
                        minimumSize: const Size(
                          SeyirTokens.tapTarget,
                          SeyirTokens.tapTarget,
                        ),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),

                    // Fixed YARGILA Row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "YARGILA ||",
                            style: palette.display(weight: FontWeight.w600).copyWith(
                              letterSpacing: 0.8,
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


            ],
              );
            },
            body: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _loadError != null
                          ? Padding(
                              padding: const EdgeInsets.all(SeyirTokens.space4),
                              child: DelilLoadError(
                                message: _loadError!,
                                onRetry: _loadAcceptedDavalar,
                              ),
                            )
                          : _davaList.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(SeyirTokens.space4),
                              child: DelilSoftEmpty(
                                title: 'Henüz yargılanacak dava yok',
                                message: 'Kabul ettiğiniz davalar burada görünecek',
                                icon: MdiIcons.gavel,
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
          ),
        ),
    );
  }

  List<AppExpandableIconMenuItem> _yargilaMenuItems() {
    return [
      AppExpandableIconMenuItem(
        onTap: () {},
        customChild: IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
            child: Icon(
              Icons.save_outlined,
              size: 24,
              color: SeyirPalette.of(context).textMuted,
            ),
          ),
        ),
      ),
      AppExpandableIconMenuItem(
        onTap: () {},
        customChild: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
          child: IconButton(
            icon: Icon(
              MdiIcons.briefcaseEditOutline,
              size: 26,
              color: Colors.blue.shade700,
            ),
            onPressed: _openCezalar,
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.10),
              padding: const EdgeInsets.all(10),
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
      ),
      AppExpandableIconMenuItem(
        onTap: () {},
        customChild: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
          child: IconButton(
            icon: Icon(
              MdiIcons.handcuffs,
              size: 26,
              color: Colors.blueGrey.shade700,
            ),
            onPressed: _openCezalar,
            style: IconButton.styleFrom(
              backgroundColor: Colors.blueGrey.withValues(alpha: 0.10),
              padding: const EdgeInsets.all(10),
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildHukumComposer(Dava dava, TextEditingController controller) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final characterCount = _hukumCharacterCounts[dava.id] ?? controller.text.length;
    const maxChars = 1500;
    final remaining = maxChars - characterCount;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 1.3),
        boxShadow: palette.cardShadow,
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
                  color: palette.brandSoft,
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
                      style: palette.headline(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Davacı ${dava.davaci.isNotEmpty ? dava.davaci : ' '} ile davalı ${dava.davali.isNotEmpty ? dava.davali : ' '} arasındaki uyuşmazlık için son söz sizde.',
                      style: palette.body(weight: FontWeight.w400),
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
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: TextField(
              controller: controller,
              maxLength: maxChars,
              maxLines: null,
              minLines: 6,
              style: palette.title(weight: FontWeight.w500).copyWith(height: 1.6),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Hükmünüzü ayrıntılı olarak yazın. Deliller, tanık ifadeleri ve vicdani kanaatinizi not edin...',
                hintStyle: palette.title(
                  weight: FontWeight.w400,
                  color: palette.textMuted,
                ),
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
                  color: palette.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  remaining >= 0
                      ? 'Kalan karakter: $remaining'
                      : 'Karakter sınırı aşıldı',
                  style: palette.caption(
                    weight: FontWeight.w600,
                    color: remaining >= 0
                        ? Colors.green.shade800
                        : SeyirTokens.reject,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _openSekizHukum(dava),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  'Hükmümü Kayda Geçir',
                  style: palette.title(color: Colors.white),
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
