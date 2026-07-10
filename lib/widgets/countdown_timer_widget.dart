import 'package:flutter/material.dart';

/// Geriye doğru sayan sayaç widget'ı
class CountdownTimerWidget extends StatefulWidget {
  final DateTime startTime;
  final Duration totalDuration;
  final VoidCallback? onTimeUp;
  final bool showHourglass;
  /// Faz rengi (yeşil/turuncu/kırmızı) — verilmezse süreye göre varsayılan renk kullanılır.
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
    if (widget.accentColor != null) {
      if (_isTimeUp) return Colors.red;
      return widget.accentColor!;
    }
    final hoursLeft = _remainingTime.inHours;
    if (_isTimeUp) return Colors.red;
    if (hoursLeft <= 2) return Colors.red.shade600;
    if (hoursLeft <= 10) return Colors.orange;
    if (hoursLeft <= 24) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hourglassAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  const SizedBox(width: 8),
                ],
                
                // Süre metni
                Text(
                  _isTimeUp ? 'SÜRE DOLDU!' : _formatDuration(_remainingTime),
                  style: TextStyle(
                    color: _getTimerColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                
                // Durum ikonu
                const SizedBox(width: 6),


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
    final hoursLeft = _remainingTime.inHours;
    if (_isTimeUp) return Colors.red;
    if (hoursLeft <= 2) return Colors.red.shade600;
    if (hoursLeft <= 10) return Colors.orange;
    if (hoursLeft <= 24) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTimerColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getTimerColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isTimeUp ? Icons.warning : Icons.timer,
            color: _getTimerColor(),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _isTimeUp ? 'SÜRE DOLDU!' : _formatDuration(_remainingTime),
            style: TextStyle(
              color: _getTimerColor(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}