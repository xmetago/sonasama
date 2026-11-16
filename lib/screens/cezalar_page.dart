import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../theme/seyir_tokens.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
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
  bool _isHeaderCollapsed = true;

  static String _shown(String value) => value.trim().isEmpty ? '—' : value;

  bool get _hasCase {
    bool filled(String? value) => value != null && value.trim().isNotEmpty;
    return filled(widget.davaId) ||
        filled(widget.davaAdi) ||
        filled(widget.davaDavali) ||
        filled(widget.davaDavaci);
  }

  CezalarUnifiedDava get _panelDava => CezalarUnifiedDava(
        adi: _shown(widget.davaAdi),
        davali: _shown(widget.davaDavali),
        davaci: widget.davaDavaci,
        mevkii: widget.davaGorev.isNotEmpty ? widget.davaGorev : '—',
        kalanSure: widget.kalanSure.isNotEmpty ? widget.kalanSure : '—',
        profilResmi: 'lib/icons/03_davala_ana_icon.png',
      );

  void _openSavedDavalar() {
    final String? email = widget.userEmail;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı e-posta adresi bulunamadı!')),
      );
      return;
    }
    showSavedDavalarDialog(context, email);
  }

  CezalarPage _sameCasePage() {
    return CezalarPage(
      userEmail: widget.userEmail,
      davaId: widget.davaId,
      davaAdi: widget.davaAdi,
      davaDavali: widget.davaDavali,
      davaDavaci: widget.davaDavaci,
      davaGorev: widget.davaGorev,
      kalanSure: widget.kalanSure,
      davaOpenedAt: widget.davaOpenedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppExpandableIconMenu(
          expandBody: true,
          inset: const EdgeInsets.all(8),
          rowCrossAxisAlignment: CrossAxisAlignment.stretch,
          items: [
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: CezalarLeftIconScrollColumn(userEmail: widget.userEmail),
            ),
          ],
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isHeaderCollapsed ? 48 : null,
              child: _isHeaderCollapsed
                  ? CollapsedWbHeaderRow(
                      title: 'CEZALAR',
                      titleStyle: SeyirPalette.of(context).headline(weight: FontWeight.w600),
                      onExpandHeader: () => setState(() => _isHeaderCollapsed = !_isHeaderCollapsed),
                      onToggleLeftNav: toggle,
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
                            onShowSavedDavalar: _openSavedDavalar,
                          ),
                        ),
                        CezalarMenuTitleRow(
                          onToggleLeftNav: toggle,
                          title: 'CEZALAR',
                          isHeaderCollapsed: _isHeaderCollapsed,
                          onToggleCollapse: () => setState(() => _isHeaderCollapsed = !_isHeaderCollapsed),
                        ),
                      ],
                    ),
            );
          },
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
                    CezalarMiddleVerticalIconRail(
                      onDelilleriIncele: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => DelilleriIncelePage(
                              userEmail: widget.userEmail,
                              davaId: widget.davaId,
                            ),
                          ),
                        );
                      },
                      onCezalarBriefcase: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => _sameCasePage(),
                          ),
                        );
                      },
                      onCezalarHandcuffs: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => _sameCasePage(),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: !_hasCase
                          ? const Padding(
                              padding: EdgeInsets.all(SeyirTokens.space4),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: DelilSoftEmpty(
                                  title: 'Seçili dava yok',
                                  message: 'Ceza vermek için önce bir dava seçin.',
                                  icon: MdiIcons.gavel,
                                ),
                              ),
                            )
                          : Card(
                        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                        color: SeyirPalette.of(context).card,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: SeyirPalette.of(context).border),
                        ),
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
    );
  }
}
