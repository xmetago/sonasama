import 'package:flutter/material.dart';

import '../widgets/common_header_widgets.dart';
import '../widgets/cezalar_ceza_unified_panel.dart';
import '../widgets/cezalar_page_layout_rails.dart';
import 'delilleri_incele_page.dart';

// ═══════════════════════════════════════════════════════════════
// 🏛️  CEZALAR — Birleşik sayfa (dava kartı + ceza yönetimi tek panel)
// ═══════════════════════════════════════════════════════════════

class CezalarPage extends StatefulWidget {
  final String? userEmail;
  final String? davaId;
  final String davaAdi;
  final String davaDavali;
  final String davaDavaci;
  /// Yargıla / hüküm kartındaki görev metni (Hive hüküm anahtarı ile uyumlu).
  final String davaGorev;
  final String kalanSure;
  final DateTime? davaOpenedAt;

  const CezalarPage({
    super.key,
    this.userEmail,
    this.davaId,
    this.davaAdi = '',
    this.davaDavali = '',
    this.davaDavaci = '',
    this.davaGorev = '',
    this.kalanSure = '',
    this.davaOpenedAt,
  });

  @override
  State<CezalarPage> createState() => _CezalarPageState();
}

class _CezalarPageState extends State<CezalarPage> {
  bool _showLeftIcons = false;
  bool _isHeaderCollapsed = true;

  CezalarUnifiedDava get _panelDava => CezalarUnifiedDava(
        adi: widget.davaAdi.isNotEmpty ? widget.davaAdi : 'Şeytanın Hileleri',
        davali: widget.davaDavali.isNotEmpty ? widget.davaDavali : 'Edip Yüksel',
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
                      title: 'CEZALAR ',
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
                          title: 'CEZALAR ',
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
