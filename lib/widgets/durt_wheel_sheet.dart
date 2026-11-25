import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/seyir_tokens.dart';

/// Dürtme çarkındaki bir kelime dilimi.
@immutable
class DurtWheelWord {
  const DurtWheelWord({
    required this.kelime,
    required this.icon,
    this.fontWeight = FontWeight.w600,
  });

  final String kelime;
  final IconData icon;
  final FontWeight fontWeight;
}

/// Profil dürtmesinde kullanılan kelimeler ve çizgi ikonlar.
const List<DurtWheelWord> durtmeWheelWords = <DurtWheelWord>[
  DurtWheelWord(
    kelime: 'İyi',
    icon: Icons.thumb_up_outlined,
    fontWeight: FontWeight.w600,
  ),
  DurtWheelWord(
    kelime: 'Kötü',
    icon: Icons.thumb_down_outlined,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Çirkin',
    icon: Icons.sentiment_very_dissatisfied_outlined,
    fontWeight: FontWeight.w500,
  ),
  DurtWheelWord(
    kelime: 'Özel',
    icon: Icons.star_outlined,
    fontWeight: FontWeight.w600,
  ),
  DurtWheelWord(
    kelime: 'Güzel',
    icon: Icons.favorite_outlined,
    fontWeight: FontWeight.w600,
  ),
  DurtWheelWord(
    kelime: 'Fena',
    icon: Icons.warning_outlined,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Hoş',
    icon: Icons.mood_outlined,
    fontWeight: FontWeight.w500,
  ),
  DurtWheelWord(
    kelime: 'Yakışıklı',
    icon: Icons.face_outlined,
    fontWeight: FontWeight.w600,
  ),
  DurtWheelWord(
    kelime: 'Boş ver',
    icon: Icons.block_outlined,
    fontWeight: FontWeight.w500,
  ),
  DurtWheelWord(
    kelime: 'İmkansız',
    icon: Icons.cancel_outlined,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Aptal',
    icon: Icons.sentiment_dissatisfied_outlined,
    fontWeight: FontWeight.w600,
  ),
  DurtWheelWord(
    kelime: 'Çılgın',
    icon: Icons.bolt_outlined,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Deli',
    icon: Icons.psychology_outlined,
    fontWeight: FontWeight.w600,
  ),
  DurtWheelWord(
    kelime: 'Olmaz',
    icon: Icons.close_outlined,
    fontWeight: FontWeight.w700,
  ),
  DurtWheelWord(
    kelime: 'Belki',
    icon: Icons.help_outlined,
    fontWeight: FontWeight.w500,
  ),
];

/// Dürtme kelimelerini stres çarkı olarak seçtiren alt sayfa.
class DurtWheelSheet extends StatefulWidget {
  const DurtWheelSheet({
    super.key,
    required this.onSend,
    this.words = durtmeWheelWords,
    this.subtitle,
    this.onClose,
  });

  final List<DurtWheelWord> words;
  final String? subtitle;
  final VoidCallback? onClose;
  final Future<void> Function(String kelime) onSend;

  @override
  State<DurtWheelSheet> createState() => _DurtWheelSheetState();
}

class _DurtWheelSheetState extends State<DurtWheelSheet>
    with SingleTickerProviderStateMixin {
  static const Key wheelKey = Key('durt-wheel');
  static const Key pointerKey = Key('durt-wheel-pointer');
  static const Key selectedWordKey = Key('durt-selected-word');

  late final AnimationController _spin;
  final math.Random _random = math.Random();

  int _selectedIndex = 0;
  bool _settled = true;
  bool _coasting = false;
  bool _dragging = false;
  bool _hapticsDuring = false;
  bool _impactOnStop = false;
  bool _sending = false;
  int _lastHapticIndex = 0;
  double _wheelSide = 240;
  double _lastPointerAngle = 0;
  Offset _lastLocal = Offset.zero;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _spin = AnimationController.unbounded(vsync: this, value: 0);
    _spin.addListener(_onTick);
    _spin.addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _spin.removeListener(_onTick);
    _spin.removeStatusListener(_onStatus);
    _spin.dispose();
    super.dispose();
  }

  double get _sweep => 2 * math.pi / widget.words.length;

  int _indexFor(double rotation) {
    final int count = widget.words.length;
    if (count == 0) return 0;
    final double raw = -rotation / _sweep;
    var index = raw.round() % count;
    if (index < 0) index += count;
    return index;
  }

  double _rotationForIndex(int index, {required double near}) {
    final double base = -index * _sweep;
    final int turns = ((near - base) / (2 * math.pi)).round();
    return base + turns * 2 * math.pi;
  }

  void _onTick() {
    final int index = _indexFor(_spin.value);
    if (_hapticsDuring && index != _lastHapticIndex) {
      _lastHapticIndex = index;
      HapticFeedback.selectionClick();
    }
    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  void _onStatus(AnimationStatus status) {
    if (!_coasting) return;
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    _coasting = false;
    _hapticsDuring = false;
    final int index = _indexFor(_spin.value);
    final double aligned = _rotationForIndex(index, near: _spin.value);
    if ((aligned - _spin.value).abs() > 0.01 && !_reduceMotion) {
      _animateTo(aligned);
      return;
    }
    if ((aligned - _spin.value).abs() > 0.0001) {
      _spin.value = aligned;
    }
    _markSettled();
  }

  void _markSettled() {
    if (!mounted) return;
    final bool impact = _impactOnStop;
    _impactOnStop = false;
    _hapticsDuring = false;
    _coasting = false;
    setState(() {
      _selectedIndex = _indexFor(_spin.value);
      _settled = true;
    });
    if (impact) {
      HapticFeedback.mediumImpact();
    }
  }

  void _animateTo(double target) {
    _coasting = false;
    _hapticsDuring = false;
    _spin.stop();
    if (_reduceMotion || (target - _spin.value).abs() < 0.001) {
      if ((target - _spin.value).abs() >= 0.001) {
        _spin.value = target;
      }
      _markSettled();
      return;
    }
    setState(() => _settled = false);
    _lastHapticIndex = _indexFor(_spin.value);
    _hapticsDuring = true;
    _coasting = true;
    final double delta = (target - _spin.value).abs();
    final int ms = (280 + delta * 110).clamp(280, 2400).round();
    _spin.animateTo(
      target,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
    );
  }

  void _animateToIndex(int index, {int extraTurns = 0}) {
    final int turns = _reduceMotion ? 0 : extraTurns;
    final double target =
        _rotationForIndex(index, near: _spin.value) + turns * 2 * math.pi;
    _impactOnStop = true;
    _animateTo(target);
  }

  void _fling(double omega) {
    _coasting = false;
    _hapticsDuring = false;
    _dragging = false;
    _spin.stop();
    _impactOnStop = true;
    if (_reduceMotion || omega.abs() < 1.1) {
      final double aligned = _rotationForIndex(
        _indexFor(_spin.value),
        near: _spin.value,
      );
      _animateTo(aligned);
      return;
    }
    final double capped = omega.clamp(-26.0, 26.0).toDouble();
    setState(() => _settled = false);
    _lastHapticIndex = _indexFor(_spin.value);
    _hapticsDuring = true;
    _coasting = true;
    _spin.animateWith(
      FrictionSimulation(
        0.4,
        _spin.value,
        capped,
        tolerance: const Tolerance(velocity: 0.35, distance: 0.01),
      ),
    );
  }

  void _onCevir() {
    if (widget.words.isEmpty || _sending) return;
    final int index = _random.nextInt(widget.words.length);
    final int extraTurns = 3 + _random.nextInt(2);
    _animateToIndex(index, extraTurns: extraTurns);
  }

  double _angleOf(Offset local) {
    final Offset center = Offset(_wheelSide / 2, _wheelSide / 2);
    final Offset delta = local - center;
    return math.atan2(delta.dy, delta.dx);
  }

  int? _indexAt(Offset local) {
    if (widget.words.isEmpty) return null;
    final Offset center = Offset(_wheelSide / 2, _wheelSide / 2);
    final Offset delta = local - center;
    final double dist = delta.distance;
    final double radius = _wheelSide / 2;
    if (dist < radius * 0.18 || dist > radius + 4) return null;
    final double localAngle = math.atan2(delta.dy, delta.dx) - _spin.value;
    var shifted = localAngle - (-math.pi / 2 - _sweep / 2);
    shifted %= 2 * math.pi;
    if (shifted < 0) shifted += 2 * math.pi;
    return (shifted / _sweep).floor() % widget.words.length;
  }

  void _onTapUp(TapUpDetails details) {
    if (_sending) return;
    final int? index = _indexAt(details.localPosition);
    if (index == null) return;
    _animateToIndex(index);
  }

  void _onPanStart(DragStartDetails details) {
    if (_sending) return;
    _coasting = false;
    _hapticsDuring = false;
    _spin.stop();
    _dragging = true;
    _impactOnStop = true;
    _lastHapticIndex = _indexFor(_spin.value);
    _hapticsDuring = true;
    _lastPointerAngle = _angleOf(details.localPosition);
    _lastLocal = details.localPosition;
    setState(() => _settled = false);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final double angle = _angleOf(details.localPosition);
    var delta = angle - _lastPointerAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    _lastPointerAngle = angle;
    _lastLocal = details.localPosition;
    _spin.value += delta;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_dragging) return;
    final Offset center = Offset(_wheelSide / 2, _wheelSide / 2);
    final Offset radius = _lastLocal - center;
    final double r2 = radius.dx * radius.dx + radius.dy * radius.dy;
    var omega = 0.0;
    if (r2 > 16) {
      final Offset velocity = details.velocity.pixelsPerSecond;
      omega = (radius.dx * velocity.dy - radius.dy * velocity.dx) / r2;
    }
    _hapticsDuring = false;
    _fling(omega);
  }

  void _onPanCancel() {
    if (!_dragging) return;
    _hapticsDuring = false;
    _fling(0);
  }

  Future<void> _onSendPressed() async {
    if (_sending || widget.words.isEmpty) return;
    if (!_settled || _coasting || _dragging) {
      _dragging = false;
      _hapticsDuring = false;
      _coasting = false;
      _spin.stop();
      final double aligned = _rotationForIndex(
        _indexFor(_spin.value),
        near: _spin.value,
      );
      if ((aligned - _spin.value).abs() > 0.0001) {
        _spin.value = aligned;
      }
      _impactOnStop = false;
      _markSettled();
    }
    final String kelime = widget.words[_selectedIndex].kelime;
    setState(() => _sending = true);
    try {
      await widget.onSend(kelime);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final double maxSheet = math.min(media.size.height * 0.88, 620);
    final int index = widget.words.isEmpty
        ? 0
        : math.min(_selectedIndex, widget.words.length - 1);
    final DurtWheelWord? word = widget.words.isEmpty
        ? null
        : widget.words[index];

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheet),
      child: Material(
        key: const Key('durt-wheel-sheet'),
        color: palette.card,
        borderRadius: SeyirTokens.sheetTop,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SeyirTokens.space4,
            SeyirTokens.space2,
            SeyirTokens.space4,
            SeyirTokens.space4 + media.padding.bottom,
          ),
          child: Column(
            children: [
              _DragHandle(color: palette.border),
              const SizedBox(height: SeyirTokens.space2),
              _SheetHeader(
                palette: palette,
                subtitle: widget.subtitle,
                onClose: widget.onClose,
              ),
              Divider(height: 1, color: palette.border),
              const SizedBox(height: SeyirTokens.space3),
              if (word != null)
                _SelectedWordBanner(
                  word: word,
                  settled: _settled,
                  palette: palette,
                ),
              const SizedBox(height: SeyirTokens.space2),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double available = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final double diameter = math
                        .min(300, math.max(0, available - 20))
                        .toDouble();
                    if (diameter < 96 || word == null) {
                      return const SizedBox.shrink();
                    }
                    _wheelSide = diameter;
                    return Center(
                      child: _Wheel(
                        diameter: diameter,
                        words: widget.words,
                        rotation: _spin.value,
                        selectedIndex: index,
                        settled: _settled,
                        palette: palette,
                        onTapUp: _onTapUp,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onPanCancel: _onPanCancel,
                        onSegmentTap: _sending
                            ? null
                            : (segment) => _animateToIndex(segment),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: SeyirTokens.space2),
              _ActionRow(
                palette: palette,
                sending: _sending,
                onSpin: _onCevir,
                onSend: _onSendPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.palette,
    required this.subtitle,
    required this.onClose,
  });

  final SeyirPalette palette;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.touch_app_outlined, color: palette.textPrimary, size: 22),
        const SizedBox(width: SeyirTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dürt', style: palette.headline()),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: palette.body(
                    weight: FontWeight.w400,
                    color: palette.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            tooltip: 'Kapat',
            style: IconButton.styleFrom(
              minimumSize: const Size(
                SeyirTokens.tapTarget,
                SeyirTokens.tapTarget,
              ),
              tapTargetSize: MaterialTapTargetSize.padded,
              foregroundColor: palette.textPrimary,
            ),
          ),
      ],
    );
  }
}

class _SelectedWordBanner extends StatelessWidget {
  const _SelectedWordBanner({
    required this.word,
    required this.settled,
    required this.palette,
  });

  final DurtWheelWord word;
  final bool settled;
  final SeyirPalette palette;

  @override
  Widget build(BuildContext context) {
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    final Color foreground = palette.textPrimary;
    return AnimatedContainer(
      duration: reduce ? Duration.zero : SeyirTokens.motion,
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space4,
        vertical: SeyirTokens.space2,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusLgAll,
        border: Border.all(
          color: settled ? SeyirTokens.brand : palette.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(word.icon, color: foreground, size: 20),
          const SizedBox(width: SeyirTokens.space2),
          Flexible(
            child: Text(
              word.kelime,
              key: _DurtWheelSheetState.selectedWordKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: palette.display(
                color: foreground,
                weight: word.fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.palette,
    required this.sending,
    required this.onSpin,
    required this.onSend,
  });

  final SeyirPalette palette;
  final bool sending;
  final VoidCallback onSpin;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: sending ? null : onSpin,
          icon: const Icon(Icons.rotate_right, size: 18),
          label: const Text('Çevir'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(
              SeyirTokens.tapTarget,
              SeyirTokens.tapTarget,
            ),
            tapTargetSize: MaterialTapTargetSize.padded,
            foregroundColor: palette.textPrimary,
            side: BorderSide(color: palette.border),
            shape: const RoundedRectangleBorder(
              borderRadius: SeyirTokens.radiusMdAll,
            ),
            padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space3),
            textStyle: const TextStyle(
              fontSize: SeyirTokens.typeTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: SeyirTokens.space3),
        Expanded(
          child: FilledButton(
            onPressed: sending ? null : onSend,
            style: FilledButton.styleFrom(
              backgroundColor: SeyirTokens.brand,
              foregroundColor: palette.onSolid(SeyirTokens.brand),
              disabledBackgroundColor: palette.surfaceMuted,
              disabledForegroundColor: palette.textMuted,
              minimumSize: const Size(
                SeyirTokens.tapTarget,
                SeyirTokens.tapTarget,
              ),
              tapTargetSize: MaterialTapTargetSize.padded,
              shape: const RoundedRectangleBorder(
                borderRadius: SeyirTokens.radiusMdAll,
              ),
              textStyle: const TextStyle(
                fontSize: SeyirTokens.typeTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Gönder'),
          ),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.diameter,
    required this.words,
    required this.rotation,
    required this.selectedIndex,
    required this.settled,
    required this.palette,
    required this.onTapUp,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    required this.onSegmentTap,
  });

  final double diameter;
  final List<DurtWheelWord> words;
  final double rotation;
  final int selectedIndex;
  final bool settled;
  final SeyirPalette palette;
  final GestureTapUpCallback onTapUp;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final GestureDragCancelCallback onPanCancel;
  final ValueChanged<int>? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final double hub = diameter * 0.2;
    return SizedBox(
      key: _DurtWheelSheetState.wheelKey,
      width: diameter,
      height: diameter + 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 16,
            left: 0,
            width: diameter,
            height: diameter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: onTapUp,
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              onPanCancel: onPanCancel,
              child: RepaintBoundary(
                child: Transform.rotate(
                  angle: rotation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(diameter),
                        painter: _DurtWheelPainter(
                          count: words.length,
                          even: palette.surface,
                          odd: palette.surfaceMuted,
                          selectedIndex: selectedIndex,
                          settled: settled,
                          rim: palette.border,
                          gap: palette.border,
                          accent: SeyirTokens.brand,
                          accentTint: palette.brandSoft,
                        ),
                      ),
                      for (var i = 0; i < words.length; i++)
                        _SegmentLabel(
                          index: i,
                          count: words.length,
                          word: words[i],
                          diameter: diameter,
                          selected: i == selectedIndex && settled,
                          onTap: onSegmentTap == null
                              ? null
                              : () => onSegmentTap!(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16 + (diameter - hub) / 2,
            left: (diameter - hub) / 2,
            width: hub,
            height: hub,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.card,
                  border: Border.all(color: palette.border, width: 1),
                ),
                child: Center(
                  child: Container(
                    width: SeyirTokens.space3,
                    height: SeyirTokens.space3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: diameter / 2 - 13,
            child: CustomPaint(
              key: _DurtWheelSheetState.pointerKey,
              size: const Size(26, 24),
              painter: _PointerPainter(
                fill: SeyirTokens.brand,
                border: palette.isDark
                    ? SeyirTokens.neutral0
                    : SeyirTokens.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.index,
    required this.count,
    required this.word,
    required this.diameter,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final int count;
  final DurtWheelWord word;
  final double diameter;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double sweep = 2 * math.pi / count;
    final double mid = -math.pi / 2 + index * sweep;
    final double radius = diameter / 2;
    final double orbit = radius * 0.56;
    final double boxW = math.min(radius * 0.62, 84);
    final double boxH = math.min(32, math.max(22, orbit * sweep * 0.85));
    final double dx = math.cos(mid) * orbit;
    final double dy = math.sin(mid) * orbit;
    var labelAngle = mid;
    if (math.cos(mid) < 0) labelAngle += math.pi;
    final Color foreground = SeyirPalette.of(context).textPrimary;

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: labelAngle,
          child: Semantics(
            button: true,
            selected: selected,
            label: word.kelime,
            child: GestureDetector(
              key: Key('durt-segment-${word.kelime}'),
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: SizedBox(
                width: boxW,
                height: boxH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(word.icon, size: 14, color: foreground),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        word.kelime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: SeyirTokens.typeCaption,
                          fontWeight: selected
                              ? FontWeight.w800
                              : word.fontWeight,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DurtWheelPainter extends CustomPainter {
  const _DurtWheelPainter({
    required this.count,
    required this.even,
    required this.odd,
    required this.selectedIndex,
    required this.settled,
    required this.rim,
    required this.gap,
    required this.accent,
    required this.accentTint,
  });

  final int count;
  final Color even;
  final Color odd;
  final int selectedIndex;
  final bool settled;
  final Color rim;
  final Color gap;
  final Color accent;
  final Color accentTint;

  Color _base(int index) => index.isEven ? even : odd;

  Color _fill(int index) {
    final Color base = _base(index);
    if (settled && index == selectedIndex) {
      return Color.alphaBlend(accentTint, base);
    }
    return base;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 3;
    if (count == 0 || radius <= 0) return;
    final double sweep = 2 * math.pi / count;
    final Rect base = Rect.fromCircle(center: center, radius: radius);
    final int selected = math.min(selectedIndex, count - 1);

    for (var i = 0; i < count; i++) {
      if (i == selected) continue;
      _drawSlice(
        canvas,
        rect: base,
        start: -math.pi / 2 - sweep / 2 + i * sweep,
        sweep: sweep,
        color: _fill(i),
      );
    }
    _drawSlice(
      canvas,
      rect: base,
      start: -math.pi / 2 - sweep / 2 + selected * sweep,
      sweep: sweep,
      color: _fill(selected),
    );

    final Paint gapPaint = Paint()
      ..color = gap
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < count; i++) {
      final double angle = -math.pi / 2 - sweep / 2 + i * sweep;
      final Offset edge = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, edge, gapPaint);
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rim,
    );

    if (settled) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 - sweep / 2 + selected * sweep,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
    }
  }

  void _drawSlice(
    Canvas canvas, {
    required Rect rect,
    required double start,
    required double sweep,
    required Color color,
  }) {
    canvas.drawArc(rect, start, sweep, true, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DurtWheelPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.even != even ||
        oldDelegate.odd != odd ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.settled != settled ||
        oldDelegate.rim != rim ||
        oldDelegate.gap != gap ||
        oldDelegate.accent != accent ||
        oldDelegate.accentTint != accentTint;
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width / 2, size.height - 1)
      ..lineTo(size.width * 0.12, 2)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.42,
        size.width * 0.88,
        2,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.border != border;
  }
}
