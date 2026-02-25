import 'dart:math';
import 'package:flutter/material.dart';

/// 109 adet konfeti parçası ile görsel şölen sunan animasyon widget'ı
class ConfettiAnimationWidget extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const ConfettiAnimationWidget({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<ConfettiAnimationWidget> createState() => _ConfettiAnimationWidgetState();
}

class _ConfettiAnimationWidgetState extends State<ConfettiAnimationWidget>
    with TickerProviderStateMixin {
  final List<ConfettiParticle> _particles = [];
  late AnimationController _controller;
  final Random _random = Random();
  ColorScheme? _colorScheme;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete?.call();
        }
      });
  }

  void _initializeParticles(ColorScheme colorScheme) {
    if (_particles.isEmpty) {
      // 109 adet konfeti parçası oluştur
      for (int i = 0; i < 109; i++) {
        _particles.add(_createParticle(colorScheme));
      }
      _controller.forward();
    }
  }

  ConfettiParticle _createParticle(ColorScheme colorScheme) {
    // ColorScheme'den parlak renkler oluştur
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.errorContainer,
      // Daha parlak tonlar için
      Color.lerp(colorScheme.primary, Colors.white, 0.3) ?? colorScheme.primary,
      Color.lerp(colorScheme.secondary, Colors.white, 0.3) ?? colorScheme.secondary,
    ];

    return ConfettiParticle(
      color: colors[_random.nextInt(colors.length)],
      startX: _random.nextDouble(),
      startY: -0.1,
      velocityX: (_random.nextDouble() - 0.5) * 0.02,
      velocityY: 0.01 + _random.nextDouble() * 0.02,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      size: 8.0 + _random.nextDouble() * 12.0,
      shape: _random.nextBool() ? ConfettiShape.circle : ConfettiShape.rectangle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_colorScheme != theme.colorScheme) {
      _colorScheme = theme.colorScheme;
      _particles.clear();
      _initializeParticles(theme.colorScheme);
    } else if (_particles.isEmpty) {
      _initializeParticles(theme.colorScheme);
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
            colorScheme: theme.colorScheme,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Konfeti parçacığı modeli
class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double rotationSpeed;
  final double size;
  final ConfettiShape shape;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.rotationSpeed,
    required this.size,
    required this.shape,
  });
}

enum ConfettiShape { circle, rectangle }

/// Konfeti parçacıklarını çizen custom painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;
  final ColorScheme colorScheme;

  ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.startX * size.width + particle.velocityX * size.width * progress * 50;
      final y = particle.startY * size.height + particle.velocityY * size.height * progress * 30;
      final rotation = particle.rotationSpeed * progress * 10;

      // Ekran dışına çıkan parçacıkları çizme
      if (y < 0 || y > size.height || x < 0 || x > size.width) {
        continue;
      }

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (particle.shape == ConfettiShape.circle) {
        canvas.drawCircle(
          Offset.zero,
          particle.size / 2,
          paint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

