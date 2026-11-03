import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TreeMenuPageheadlines extends StatelessWidget {
  final VoidCallback? onMenuPressed;
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

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: Color(0xFF2F3E35),
  );

  const TreeMenuPageheadlines({
    super.key,
    this.onMenuPressed,
    this.onShowSavedDavalar,
    this.highlightSaveIcon = false,
    this.hasPendingSavedDava = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.headlineText = 'AÇTIĞIM DAVALAR',
    this.headlineAssetPath = 'lib/icons/06_left_row_actigim_davalar_icon.png',
    this.headlineDavaCount,
    this.showSavedDavalarIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              MdiIcons.menuOpen,
              size: 34,
              color: Colors.red,
            ),
            onPressed: onMenuPressed ?? () {
              print("Menu button pressed");
            },
            tooltip: 'Sol menü',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('|| $headlineText ||', style: _titleStyle),
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
                        padding: EdgeInsets.all(4.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: highlightSaveIcon || hasPendingSavedDava
                                ? const Color(0xFF4CAF50).withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: highlightSaveIcon || hasPendingSavedDava
                                  ? const Color(0xFF4CAF50)
                                  : Colors.transparent,
                              width: highlightSaveIcon ? 3 : (hasPendingSavedDava ? 1.5 : 0),
                            ),
                            boxShadow: highlightSaveIcon
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withOpacity(0.35),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            MdiIcons.contentSaveOutline,
                            size: 24,
                            color: Colors.green,
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
                color: Colors.black,
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
  }
}

