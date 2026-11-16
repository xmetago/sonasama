import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../theme/seyir_tokens.dart';

class TreeMenuPageheadlines extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final Widget? menuButton;
  final VoidCallback? onShowSavedDavalar;
  final bool highlightSaveIcon;
  final bool hasPendingSavedDava;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  /// Sayfa başlığı (varsayılan: Açtığım Davalar).
  final String headlineText;
  /// Başlık solundaki satır ikonunun asset yolu.
  final String headlineAssetPath;
  /// Varsa başlıktan sonra rozet olarak gösterilir.
  final int? headlineDavaCount;
  /// Kaydedilen dava düzenleme ikonu (Katıldığım Davalar gibi sayfalarda false).
  final bool showSavedDavalarIcon;

  const TreeMenuPageheadlines({
    super.key,
    this.onMenuPressed,
    this.menuButton,
    this.onShowSavedDavalar,
    this.highlightSaveIcon = false,
    this.hasPendingSavedDava = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.headlineText = 'Açtığım Davalar',
    this.headlineAssetPath = 'lib/icons/06_left_row_actigim_davalar_icon.png',
    this.headlineDavaCount,
    this.showSavedDavalarIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final bool saveActive = highlightSaveIcon || hasPendingSavedDava;
    final TextStyle titleStyle = palette.headline(
      weight: FontWeight.w600,
    ).copyWith(letterSpacing: 0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          menuButton ??
              IconButton(
                icon: const Icon(
                  MdiIcons.menuOpen,
                  size: 34,
                  color: Colors.red,
                ),
                onPressed: onMenuPressed ?? () {
                  debugPrint('Menu button pressed');
                },
                tooltip: 'Sol menü',
              ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(headlineText, style: titleStyle),
                if (headlineDavaCount != null && headlineDavaCount! > 0) ...[
                  const SizedBox(width: 7),
                  _HeadlineDavaCountBadge(count: headlineDavaCount!),
                ],
                if (showSavedDavalarIcon) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Kaydedilen Davalar - Düzenlemek için tıklayın',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onShowSavedDavalar,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: saveActive
                                ? palette.brandSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: saveActive
                                  ? SeyirTokens.brand
                                  : Colors.transparent,
                              width: highlightSaveIcon ? 3 : (hasPendingSavedDava ? 1.5 : 0),
                            ),
                            boxShadow: highlightSaveIcon
                                ? [
                                    BoxShadow(
                                      color: SeyirTokens.brand.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: const Icon(
                            MdiIcons.contentSaveOutline,
                            size: 24,
                            color: SeyirTokens.brand,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onToggleCollapse != null)
            IconButton(
              icon: Icon(
                isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 24,
                color: palette.textPrimary,
              ),
              onPressed: onToggleCollapse,
              tooltip: isCollapsed ? 'Arayüzü Aç' : 'Arayüzü Kapat',
            )
          else
            const SizedBox(width: 38),
        ],
      ),
    );
  }
}

/// Gelen davalar sayfasındaki rozet stiliyle uyumlu dava sayısı göstergesi.
class _HeadlineDavaCountBadge extends StatelessWidget {
  final int count;

  const _HeadlineDavaCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: SeyirTokens.brand,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: palette.onSolid(SeyirTokens.brand),
          fontSize: SeyirTokens.typeCaption,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

