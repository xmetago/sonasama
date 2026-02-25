import 'package:flutter/material.dart';

/// Kategori arama çubuğu widget'ı - Yeniden kullanılabilir
class CategorySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  // Site genelindeki ana renk teması
  static const Color primaryColor = Color(0xFF059669); // Koyu yeşil
  static const Color primaryLightColor = Color(0xFF10B981); // Açık yeşil

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
      duration: const Duration(milliseconds: 300),
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                if (_isFocused)
                  BoxShadow(
                    color: CategorySearchBar.primaryColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
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
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CategorySearchBar.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: CategorySearchBar.primaryColor,
                            size: 20,
                            semanticLabel: 'Aramayı temizle',
                          ),
                          onPressed: () {
                            widget.onClear?.call();
                            setState(() => _isFocused = false);
                            _animationController.reverse();
                          },
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: CategorySearchBar.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
} 