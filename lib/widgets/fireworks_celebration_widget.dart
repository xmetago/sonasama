import 'dart:math';
import 'package:flutter/material.dart';

/// Dava başarısı gibi kutlamalarda kısa süreli havai fişek patlaması efekti.
class FireworksCelebrationWidget extends StatefulWidget {
  const FireworksCelebrationWidget({
    super.key,
    this.duration = const Duration(milliseconds: 2800),
    this.onComplete,
  });

  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<FireworksCelebrationWidget> createState() =>
      _FireworksCelebrationWidgetState();
}

class _FireworksCelebrationWidgetState extends State<FireworksCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  late final List<_Burst> _bursts;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    _bursts = List.generate(5, (_) => _Burst.random(_random));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FireworksPainter(
            bursts: _bursts,
            progress: Curves.easeOutCubic.transform(_controller.value),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Burst {
  _Burst({
    required this.nx,
    required this.ny,
    required this.particles,
  });

  final double nx;
  final double ny;
  final List<_Spark> particles;

  factory _Burst.random(Random r) {
    final particles = <_Spark>[];
    const count = 42;
    const palette = [
      Color(0xFFFFD700),
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFF9B59B6),
      Color(0xFF3498DB),
      Color(0xFFFFEAA7),
      Color(0xFF00B894),
    ];
    for (var i = 0; i < count; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final speed = 0.35 + r.nextDouble() * 0.65;
      particles.add(
        _Spark(
          angle: angle,
          speed: speed,
          color: palette[r.nextInt(palette.length)],
          size: 2.0 + r.nextDouble() * 4.0,
        ),
      );
    }
    return _Burst(
      nx: 0.12 + r.nextDouble() * 0.76,
      ny: 0.08 + r.nextDouble() * 0.42,
      particles: particles,
    );
  }
}

class _Spark {
  _Spark({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter({
    required this.bursts,
    required this.progress,
  });

  final List<_Burst> bursts;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    for (final burst in bursts) {
      final cx = burst.nx * size.width;
      final cy = burst.ny * size.height;
      final fade = (1.0 - progress).clamp(0.0, 1.0);

      for (final spark in burst.particles) {
        final t = progress * spark.speed;
        final dist = t * min(size.width, size.height) * 0.38;
        final gx = cos(spark.angle) * dist;
        final gy = sin(spark.angle) * dist + progress * progress * size.height * 0.22;
        final x = cx + gx;
        final y = cy + gy;

        if (x < -20 || x > size.width + 20 || y < -20 || y > size.height + 20) {
          continue;
        }

        final alpha = (fade * (0.5 + 0.5 * (1 - t))).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = spark.color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

        canvas.drawCircle(Offset(x, y), spark.size * (0.7 + 0.3 * (1 - progress)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
