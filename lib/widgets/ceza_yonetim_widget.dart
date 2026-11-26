import 'package:flutter/material.dart';

import '../screens/cezalar_page.dart';
import '../screens/delilleri_incele_page.dart';
import '../theme/seyir_tokens.dart';
import '../utils/dialog_utils.dart';
import 'cezalar_ceza_unified_panel.dart';
import 'cezalar_page_layout_rails.dart';
import 'common_header_widgets.dart';
import 'shared/app_expandable_icon_menu.dart';

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
  bool _isHeaderCollapsed = true;
  bool _muhurledi = false;
  bool _allowPop = false;

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
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || _allowPop) {
          return;
        }
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop(_muhurledi);
        });
      },
      child: Scaffold(
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
                      title: 'CEZA YÖNETİMİ',
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
                            onShowSavedDavalar: () {
                              final String? email = widget.userEmail;
                              if (email == null || email.isEmpty) return;
                              showSavedDavalarDialog(context, email);
                            },
                          ),
                        ),
                        CezalarMenuTitleRow(
                          onToggleLeftNav: toggle,
                          title: 'CEZA YÖNETİMİ',
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
                            builder: (BuildContext context) => CezalarPage(
                              userEmail: widget.userEmail,
                              davaId: widget.davaId,
                              davaAdi: widget.davaAdi,
                              davaDavali: widget.davaDavali,
                              davaDavaci: widget.davaDavaci,
                              davaGorev: widget.davaGorev,
                              kalanSure: widget.kalanSure,
                              davaOpenedAt: widget.davaOpenedAt,
                            ),
                          ),
                        );
                      },
                      onCezalarHandcuffs: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => CezalarPage(
                              userEmail: widget.userEmail,
                              davaId: widget.davaId,
                              davaAdi: widget.davaAdi,
                              davaDavali: widget.davaDavali,
                              davaDavaci: widget.davaDavaci,
                              davaGorev: widget.davaGorev,
                              kalanSure: widget.kalanSure,
                              davaOpenedAt: widget.davaOpenedAt,
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Card(
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
                          onPenaltyApplied: () {
                            if (mounted && !_muhurledi) {
                              setState(() => _muhurledi = true);
                            }
                          },
                        ),
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
    );
  }
}
