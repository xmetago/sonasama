import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';

/// Kategori arama çubuğu widget'ı - Yeniden kullanılabilir
class CategorySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const CategorySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: SeyirTokens.motion,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    const Color brand = SeyirTokens.brandDeep;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(SeyirTokens.space3),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: SeyirTokens.radiusLgAll,
              border: Border.all(
                color: _isFocused
                    ? palette.foreground(SeyirTokens.brand)
                    : palette.border,
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                if (_isFocused)
                  BoxShadow(
                    color: brand.withValues(alpha: 0.3 * _glowAnimation.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              style: palette.body(weight: FontWeight.w500),
              onTap: () {
                setState(() => _isFocused = true);
                _animationController.forward();
              },
              onSubmitted: (_) {
                setState(() => _isFocused = false);
                _animationController.reverse();
              },
              decoration: InputDecoration(
                hintText: 'Kategori ara...',
                hintStyle: palette.body(
                  weight: FontWeight.w400,
                  color: palette.textMuted,
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Aramayı temizle',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(
                            SeyirTokens.tapTarget,
                            SeyirTokens.tapTarget,
                          ),
                          tapTargetSize: MaterialTapTargetSize.padded,
                          foregroundColor: brand,
                        ),
                        icon: const Icon(
                          Icons.clear,
                          size: 20,
                          semanticLabel: 'Aramayı temizle',
                        ),
                        onPressed: () {
                          widget.onClear?.call();
                          setState(() => _isFocused = false);
                          _animationController.reverse();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: SeyirTokens.radiusLgAll,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: SeyirTokens.radiusLgAll,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: SeyirTokens.radiusLgAll,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: palette.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: SeyirTokens.space4,
                  vertical: SeyirTokens.space3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
