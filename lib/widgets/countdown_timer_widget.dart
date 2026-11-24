import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';

/// Süre doldu, kısa süre ve varsayılan sayaç renkleri Seyir paletinden gelir.
Color _countdownColor(
  BuildContext context, {
  required bool timeUp,
  required Duration remaining,
  Color? accent,
}) {
  final palette = SeyirPalette.of(context);
  if (timeUp) return palette.foreground(SeyirTokens.reject);
  if (accent != null) return accent;
  final hoursLeft = remaining.inHours;
  if (hoursLeft <= 2) return palette.foreground(SeyirTokens.reject);
  if (hoursLeft <= 24) return palette.foreground(SeyirTokens.warning);
  return palette.foreground(SeyirTokens.brand);
}

/// Geriye doğru sayan sayaç widget'ı
class CountdownTimerWidget extends StatefulWidget {
  final DateTime startTime;
  final Duration totalDuration;
  final VoidCallback? onTimeUp;
  final bool showHourglass;

  /// Faz rengi. Verilmezse süreye göre Seyir paleti kullanılır.
  final Color? accentColor;

  const CountdownTimerWidget({
    super.key,
    required this.startTime,
    required this.totalDuration,
    this.onTimeUp,
    this.showHourglass = true,
    this.accentColor,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _hourglassController;
  late Animation<double> _hourglassAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Duration _remainingTime = Duration.zero;
  bool _isTimeUp = false;

  @override
  void initState() {
    super.initState();

    // Kum saati animasyonu
    _hourglassController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _hourglassAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hourglassController,
      curve: Curves.easeInOut,
    ));

    // Nabız animasyonu (süre azaldığında)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _calculateRemainingTime();
    _startTimer();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final elapsed = now.difference(widget.startTime);
    final remaining = widget.totalDuration - elapsed;

    if (remaining.isNegative) {
      _remainingTime = Duration.zero;
      _isTimeUp = true;
      widget.onTimeUp?.call();
    } else {
      _remainingTime = remaining;
      _isTimeUp = false;
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
        _startTimer();

        // Animasyon kontrolü
        _updateAnimations();
      }
    });
  }

  void _updateAnimations() {
    // Kum saati animasyonu - sürekli döner
    if (!_hourglassController.isAnimating) {
      _hourglassController.repeat();
    }

    // Nabız animasyonu - son 10 saatte başlar
    final hoursLeft = _remainingTime.inHours;
    if (hoursLeft <= 10 && hoursLeft > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _hourglassController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color _getTimerColor() {
    return _countdownColor(
      context,
      timeUp: _isTimeUp,
      remaining: _remainingTime,
      accent: widget.accentColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hourglassAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SeyirTokens.space3,
              vertical: SeyirTokens.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showHourglass) ...[
                  // Kum saati animasyonu
                  SizedBox(
                    width: 19,
                    height: 19,
                    child: Transform.rotate(
                      angle: _hourglassAnimation.value * 2 * 3.14159,
                      child: Icon(
                        Icons.hourglass_empty,
                        color: _getTimerColor(),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: SeyirTokens.space2),
                ],
                Text(
                  _isTimeUp ? 'SÜRE DOLDU!' : _formatDuration(_remainingTime),
                  style: TextStyle(
                    color: _getTimerColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: SeyirTokens.typeTitle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Basit sayaç widget'ı (animasyon olmadan)
class SimpleCountdownWidget extends StatefulWidget {
  final DateTime startTime;
  final Duration totalDuration;
  final VoidCallback? onTimeUp;

  const SimpleCountdownWidget({
    super.key,
    required this.startTime,
    required this.totalDuration,
    this.onTimeUp,
  });

  @override
  State<SimpleCountdownWidget> createState() => _SimpleCountdownWidgetState();
}

class _SimpleCountdownWidgetState extends State<SimpleCountdownWidget> {
  Duration _remainingTime = Duration.zero;
  bool _isTimeUp = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final elapsed = now.difference(widget.startTime);
    final remaining = widget.totalDuration - elapsed;

    if (remaining.isNegative) {
      _remainingTime = Duration.zero;
      _isTimeUp = true;
      widget.onTimeUp?.call();
    } else {
      _remainingTime = remaining;
      _isTimeUp = false;
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
        _startTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color _getTimerColor() {
    return _countdownColor(
      context,
      timeUp: _isTimeUp,
      remaining: _remainingTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTimerColor();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space2,
        vertical: SeyirTokens.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: SeyirTokens.radiusSmAll,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isTimeUp ? Icons.warning : Icons.timer,
            color: color,
            size: 14,
          ),
          const SizedBox(width: SeyirTokens.space1),
          Text(
            _isTimeUp ? 'SÜRE DOLDU!' : _formatDuration(_remainingTime),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: SeyirTokens.typeCaption,
            ),
          ),
        ],
      ),
    );
  }
}
