import 'dart:math' as math;

import 'package:flutter/material.dart';

class DavaGonderilecekGrupDialog extends StatefulWidget {
  const DavaGonderilecekGrupDialog({
    super.key,
    required this.onConfirm,
  });

  final ValueChanged<String> onConfirm;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // artık dışarı tıklayınca kapanabilir
      builder: (context) => DavaGonderilecekGrupDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<DavaGonderilecekGrupDialog> createState() => _DavaGonderilecekGrupDialogState();
}

class _DavaGonderilecekGrupDialogState extends State<DavaGonderilecekGrupDialog> with SingleTickerProviderStateMixin {
  String? _selectedGroup;
  AnimationController? _animController;
  Animation<double>? _scaleAnimation;

  /// Hot reload `initState` çalıştırmadığı için `late` yerine ilk kullanımda oluşturulur.
  void _ensureAnimController() {
    if (_animController != null) return;
    final c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _animController = c;
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
    );
  }

  AnimationController get _ac {
    _ensureAnimController();
    return _animController!;
  }

  Animation<double> get _scaleAnim {
    _ensureAnimController();
    return _scaleAnimation!;
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  void _playAnimation() {
    final c = _ac;
    c.forward().then((_) {
      if (mounted) c.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureAnimController();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DavaHukmeJaggedHeader(
              title: 'Davayı Hükme Gönder',
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.blue.shade800,
                  ),
            ),
            const SizedBox(height: 28),

            // Seçenekler
            _buildOptionCard(
              value: 'Grup19',
              title: 'Grup19',
              subtitle: '7 Bilgeden Seç',
              color: Colors.deepPurple,
              icon: Icons.group_rounded,
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              value: 'Arkadaşlar',
              title: 'Arkadaşlar',
              subtitle: 'Arkadaşlardan 7  üye seç',
              color: Colors.green.shade700,
              icon: Icons.people_alt_rounded,
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              value: 'Takipçiler',
              title: 'Takipçiler',
              subtitle: 'Takipçilerden  7  üye seç',
              color: Colors.orange.shade700,
              icon: Icons.notifications_active_rounded,
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              value: 'Tanımadıklarım',
              title: 'Tanınmayan',
              subtitle: 'Tanımadığım 7  üye seç',
              color: Colors.red.shade700,
              icon: Icons.public_rounded,
            ),

            const SizedBox(height: 32),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      'İPTAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedGroup != null
                        ? () {
                            Navigator.pop(context);
                            widget.onConfirm(_selectedGroup!);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedGroup != null ? Colors.blue.shade700 : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: _selectedGroup != null ? 2 : 0,
                    ),
                    child: const Text(
                      'DAVA ATA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String value,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedGroup == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGroup = value);
        _playAnimation();
      },
      child: AnimatedBuilder(
        animation: _ac,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnim.value : 1.0,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2.2 : 1.4,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bilet / makbuz tarzı tırtıklı üst–alt kenar; dolgu ve çerçeve tek path ile çizilir.
class DavaHukmeJaggedHeader extends StatelessWidget {
  const DavaHukmeJaggedHeader({
    super.key,
    required this.title,
    this.textStyle,
  });

  final String title;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade800,
            );

    return CustomPaint(
      painter: _JaggedTicketHeaderPainter(
        fillColor: Colors.blue.shade50,
        borderColor: Colors.blue.shade300,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dar alanlarda fontu kontrollü küçültüp tek satırı korur.
                  final resolvedStyle = style ?? const TextStyle();
                  final baseFontSize = resolvedStyle.fontSize ?? 22;
                  const minScale = 0.84;

                  final textPainter = TextPainter(
                    text: TextSpan(text: title, style: resolvedStyle),
                    maxLines: 1,
                    textDirection: Directionality.of(context),
                  )..layout(maxWidth: double.infinity);

                  final intrinsicWidth = textPainter.width;
                  final availableWidth = constraints.maxWidth;
                  final widthScale = intrinsicWidth > 0
                      ? (availableWidth / intrinsicWidth).clamp(minScale, 1.0)
                      : 1.0;

                  return Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: resolvedStyle.copyWith(fontSize: baseFontSize * widthScale),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JaggedTicketHeaderPainter extends CustomPainter {
  _JaggedTicketHeaderPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  static const double _r = 12;
  static const double _toothW = 9;
  static const double _toothD = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true,
    );
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(0, h - _r);
    path.arcToPoint(
      Offset(_r, h),
      radius: const Radius.circular(_r),
      clockwise: false,
    );

    var x = _r;
    while (x < w - _r - 0.5) {
      final next = math.min(x + _toothW, w - _r);
      final mid = (x + next) / 2;
      path.lineTo(mid, h - _toothD);
      path.lineTo(next, h);
      x = next;
    }

    path.arcToPoint(
      Offset(w, h - _r),
      radius: const Radius.circular(_r),
      clockwise: false,
    );
    path.lineTo(w, _r);
    path.arcToPoint(
      Offset(w - _r, 0),
      radius: const Radius.circular(_r),
      clockwise: false,
    );

    x = w - _r;
    while (x > _r + 0.5) {
      final next = math.max(x - _toothW, _r);
      final mid = (x + next) / 2;
      path.lineTo(mid, _toothD);
      path.lineTo(next, 0);
      x = next;
    }

    path.arcToPoint(
      Offset(0, _r),
      radius: const Radius.circular(_r),
      clockwise: false,
    );
    path.lineTo(0, h - _r);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _JaggedTicketHeaderPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
