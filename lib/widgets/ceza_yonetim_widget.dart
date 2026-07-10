import 'package:flutter/material.dart';

import '../screens/cezalar_page.dart';
import '../screens/delilleri_incele_page.dart';
import 'cezalar_ceza_unified_panel.dart';
import 'cezalar_page_layout_rails.dart';
import 'common_header_widgets.dart';

// ═══════════════════════════════════════════════════════════════
// Ceza Yönetimi — tam ekran / sheet: kabuk + [CezalarCezaUnifiedPanel]
// ═══════════════════════════════════════════════════════════════

class CezaYonetimPage extends StatefulWidget {
  final String? davaId;
  final String davaAdi;
  final String davaDavali;
  final String davaDavaci;
  final String? userEmail;
  final String davaGorev;
  final String kalanSure;
  final DateTime? davaOpenedAt;

  const CezaYonetimPage({
    super.key,
    this.davaId,
    required this.davaAdi,
    required this.davaDavali,
    required this.davaDavaci,
    this.userEmail,
    this.davaGorev = '',
    this.kalanSure = '',
    this.davaOpenedAt,
  });

  @override
  State<CezaYonetimPage> createState() => _CezaYonetimPageState();
}

class _CezaYonetimPageState extends State<CezaYonetimPage> {
  bool _showLeftIcons = false;
  bool _isHeaderCollapsed = true;

  /// Hot reload / yanlış element eşleşmesinde `late` patlamasını önlemek için her build'da türetilir.
  CezalarUnifiedDava get _panelDava => CezalarUnifiedDava(
        adi: widget.davaAdi,
        davali: widget.davaDavali,
        davaci: widget.davaDavaci,
        mevkii: widget.davaGorev.isNotEmpty ? widget.davaGorev : '—',
        kalanSure: widget.kalanSure.isNotEmpty ? widget.kalanSure : '—',
        profilResmi: 'lib/icons/03_davala_ana_icon.png',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isHeaderCollapsed ? 40 : null,
              child: _isHeaderCollapsed
                  ? CollapsedWbHeaderRow(
                      title: 'CEZA YÖNETİMİ ',
                      onExpandHeader: () => setState(() => _isHeaderCollapsed = !_isHeaderCollapsed),
                      onToggleLeftNav: () => setState(() => _showLeftIcons = !_showLeftIcons),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
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
                            onShowSavedDavalar: () {},
                          ),
                        ),
                        CezalarMenuTitleRow(
                          onToggleLeftNav: () => setState(() => _showLeftIcons = !_showLeftIcons),
                          title: 'CEZA YÖNETİMİ ',
                          isHeaderCollapsed: _isHeaderCollapsed,
                          onToggleCollapse: () => setState(() => _isHeaderCollapsed = !_isHeaderCollapsed),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _showLeftIcons ? 60 : 0,
                      child: _showLeftIcons
                          ? SingleChildScrollView(
                              child: CezalarLeftIconScrollColumn(userEmail: widget.userEmail),
                            )
                          : const SizedBox.shrink(),
                    ),
                    CezalarMiddleVerticalIconRail(
                      onDelilleriIncele: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => const DelilleriIncelePage(),
                          ),
                        );
                      },
                      onCezalarBriefcase: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => CezalarPage(userEmail: widget.userEmail),
                          ),
                        );
                      },
                      onCezalarHandcuffs: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => CezalarPage(userEmail: widget.userEmail),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: CezalarCezaUnifiedPanel(
                          dava: _panelDava,
                          davaId: widget.davaId,
                          davaOpenedAt: widget.davaOpenedAt,
                          userEmail: widget.userEmail,
                          embeddedMiddlePane: true,
                          showSheetCloseHeader: false,
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
  }
}

/// Modal sheet veya gömülü kullanım: tek kaynak [CezalarCezaUnifiedPanel].
class CezaYonetimWidget extends StatelessWidget {
  final String? davaId;
  final String davaAdi;
  final String davaDavali;
  final String davaDavaci;
  final String? userEmail;
  final bool embeddedMiddlePane;
  final String davaGorev;
  final String kalanSure;
  final DateTime? davaOpenedAt;

  const CezaYonetimWidget({
    super.key,
    this.davaId,
    required this.davaAdi,
    required this.davaDavali,
    required this.davaDavaci,
    this.userEmail,
    this.embeddedMiddlePane = false,
    this.davaGorev = '',
    this.kalanSure = '',
    this.davaOpenedAt,
  });

  @override
  Widget build(BuildContext context) {
    final CezalarUnifiedDava dava = CezalarUnifiedDava(
      adi: davaAdi,
      davali: davaDavali,
      davaci: davaDavaci,
      mevkii: davaGorev.isNotEmpty ? davaGorev : '—',
      kalanSure: kalanSure.isNotEmpty ? kalanSure : '—',
      profilResmi: 'lib/icons/03_davala_ana_icon.png',
    );

    return CezalarCezaUnifiedPanel(
      dava: dava,
      davaId: davaId,
      davaOpenedAt: davaOpenedAt,
      userEmail: userEmail,
      embeddedMiddlePane: embeddedMiddlePane,
      showSheetCloseHeader: !embeddedMiddlePane,
      onPenaltyApplied: embeddedMiddlePane
          ? null
          : () {
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
    );
  }
}
