import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Izgara hücreleri için giriş: hafif gecikme + fade ve yukarı kayma.
class HukumGiftTileEntrance extends StatelessWidget {
  const HukumGiftTileEntrance({
    super.key,
    required this.gridIndex,
    required this.child,
  });

  final int gridIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    return _HukumGiftTileEntranceStateful(gridIndex: gridIndex, child: child);
  }
}

class _HukumGiftTileEntranceStateful extends StatefulWidget {
  const _HukumGiftTileEntranceStateful({
    required this.gridIndex,
    required this.child,
  });

  final int gridIndex;
  final Widget child;

  @override
  State<_HukumGiftTileEntranceStateful> createState() =>
      _HukumGiftTileEntranceStatefulState();
}

class _HukumGiftTileEntranceStatefulState
    extends State<_HukumGiftTileEntranceStateful>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.09),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    final int delayMs = math.min(widget.gridIndex * 44, 520);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Emoji üzerinde hafif dikey “nefes” hareketi.
class HukumGiftEmojiMotion extends StatelessWidget {
  const HukumGiftEmojiMotion({
    super.key,
    required this.emoji,
    this.fontSize = 42,
  });

  final String emoji;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(emoji, style: TextStyle(fontSize: fontSize));
    }

    return _HukumGiftEmojiMotionStateful(emoji: emoji, fontSize: fontSize);
  }
}

class _HukumGiftEmojiMotionStateful extends StatefulWidget {
  const _HukumGiftEmojiMotionStateful({
    required this.emoji,
    required this.fontSize,
  });

  final String emoji;
  final double fontSize;

  @override
  State<_HukumGiftEmojiMotionStateful> createState() =>
      _HukumGiftEmojiMotionStatefulState();
}

class _HukumGiftEmojiMotionStatefulState extends State<_HukumGiftEmojiMotionStateful>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double get _phaseOffset => (widget.emoji.hashCode % 997) / 997 * 2 * math.pi;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double t = _c.value * 2 * math.pi + _phaseOffset;
        final double dy = math.sin(t) * 2.2;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Text(widget.emoji, style: TextStyle(fontSize: widget.fontSize)),
    );
  }
}
