import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Lottie animasyon overlay widget'ı - "Hemen Haykır" butonuna basılınca gösterilir
class LottieAnimationOverlay extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final String? lottieAssetPath;

  const LottieAnimationOverlay({
    super.key,
    this.onAnimationComplete,
    this.lottieAssetPath,
  });

  @override
  State<LottieAnimationOverlay> createState() => _LottieAnimationOverlayState();
}

class _LottieAnimationOverlayState extends State<LottieAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleAnimationComplete() {
    _fadeController.reverse().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: theme.colorScheme.scrim.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: widget.lottieAssetPath != null
                ? Lottie.asset(
                    widget.lottieAssetPath!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    repeat: false,
                    onLoaded: (composition) {
                      // Animasyon yüklendiğinde
                    },
                  )
                : _buildFallbackAnimation(theme),
          ),
        ),
      ),
    );
  }

  /// Lottie dosyası yoksa fallback animasyon göster
  Widget _buildFallbackAnimation(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      onEnd: _handleAnimationComplete,
      builder: (context, value, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Icon(
                Icons.campaign,
                size: 100,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Haykırış Yayında!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}

