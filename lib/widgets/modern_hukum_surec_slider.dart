part of 'modern_hukum_card.dart';

/// 0–114 hukuki süreç slider'ı: 19 artan çubuk, 19'un katları, Kaydet / Düzenle / Hüküm.
class _HukukiSurecSlider extends StatefulWidget {
  const _HukukiSurecSlider({
    super.key,
    required this.dragEnabled,
    required this.finalized,
    required this.inactiveSegment,
    required this.canSave,
    required this.canHukum,
    required this.focusNode,
    required this.onSave,
    required this.onHukum,
    this.disabledHint,
  });

  final bool dragEnabled;
  final bool finalized;
  /// Kilitliyken: 1 → orta (~57), 2 → sağ (~95).
  final int inactiveSegment;
  final bool canSave;
  final bool canHukum;
  final FocusNode focusNode;
  final Future<void> Function() onSave;
  final VoidCallback onHukum;
  final String? disabledHint;

  static const double maxValue = 114;
  static const List<int> milestones = <int>[0, 19, 38, 57, 76, 95, 114];
  static const int barCount = 19;

  static const Color finalizedGrey = Color(0xFF90A4AE);
  static const Color trackMuted = Color(0xFFE8ECEF);

  /// 0→114 sürekli geçiş: düşük uyarılma (mavi) → dikkat (sarı) → risk (turuncu) → nihai (koyu).
  static Color accentForProgress(double v) {
    final double t = (v / maxValue).clamp(0.0, 1.0);
    if (t < 0.38) {
      return Color.lerp(
        const Color(0xFF2196F3),
        const Color(0xFFFFD600),
        Curves.easeIn.transform(t / 0.38),
      )!;
    }
    if (t < 0.833) {
      return Color.lerp(
        const Color(0xFFFFD600),
        const Color(0xFFE65100),
        Curves.easeInOut.transform((t - 0.38) / (0.833 - 0.38)),
      )!;
    }
    return Color.lerp(
      const Color(0xFFE65100),
      const Color(0xFF2C3E50),
      Curves.easeIn.transform((t - 0.833) / (1.0 - 0.833)),
    )!;
  }

  @override
  State<_HukukiSurecSlider> createState() => _HukukiSurecSliderState();
}

class _HukukiSurecSliderState extends State<_HukukiSurecSlider> {
  /// Sürekli konum 0…114; bırakınca en yakın milestone'a yuvarlanır.
  double _value = 0;
  double? _dragValue;

  static int _nearestMilestone(double v) {
    int best = _HukukiSurecSlider.milestones.first;
    double bestD = (v - best).abs();
    for (final int m in _HukukiSurecSlider.milestones) {
      final double d = (v - m).abs();
      if (d < bestD) {
        bestD = d;
        best = m;
      }
    }
    return best;
  }

  static int _zoneForValue(double v) {
    if (v <= 38) {
      return 0;
    }
    if (v < 114) {
      return 1;
    }
    return 2;
  }

  double _lockedValue() {
    if (widget.finalized) {
      return _HukukiSurecSlider.maxValue;
    }
    if (!widget.dragEnabled) {
      return widget.inactiveSegment >= 2 ? 95.0 : 57.0;
    }
    return _value;
  }

  Color _progressColor(double v, {required bool lockedGrey}) {
    if (lockedGrey || widget.finalized) {
      return _HukukiSurecSlider.finalizedGrey;
    }
    return _HukukiSurecSlider.accentForProgress(v);
  }

  @override
  void initState() {
    super.initState();
    if (widget.finalized) {
      _value = _HukukiSurecSlider.maxValue;
    }
  }

  @override
  void didUpdateWidget(covariant _HukukiSurecSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.finalized && !oldWidget.finalized) {
      _value = _HukukiSurecSlider.maxValue;
      _dragValue = null;
    }
    if (!widget.dragEnabled &&
        oldWidget.dragEnabled &&
        !widget.finalized) {
      _value = widget.inactiveSegment >= 2 ? 95.0 : 0.0;
      _dragValue = null;
    }
    if (widget.dragEnabled && !oldWidget.dragEnabled) {
      _value = 0;
    }
  }

  Future<void> _onDragEnd() async {
    if (_dragValue == null) {
      return;
    }
    final int snapped = _nearestMilestone(_dragValue!);
    final int zone = _zoneForValue(snapped.toDouble());

    int resolvedMilestone = snapped;

    if (zone == 0) {
      if (!widget.canSave) {
        resolvedMilestone = 0;
      } else {
        await widget.onSave();
        if (!mounted) {
          return;
        }
        resolvedMilestone = 0;
      }
    } else if (zone == 1) {
      widget.focusNode.requestFocus();
      resolvedMilestone = snapped;
    } else {
      if (!widget.canHukum) {
        resolvedMilestone = 57;
      } else {
        widget.onHukum();
        resolvedMilestone = _HukukiSurecSlider.maxValue.toInt();
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _value = resolvedMilestone.toDouble();
      _dragValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.finalized) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final bool locked = widget.finalized || !widget.dragEnabled;
        final double displayV =
            locked ? _lockedValue() : (_dragValue ?? _value);
        final bool greyMode = locked || widget.finalized;
        final Color progressColor = _progressColor(
          displayV,
          lockedGrey: greyMode,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Hüküm onayı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hükmü kesinleştirmek için sürükleyin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 118,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 22,
                    height: 72,
                    child: _SurecBarChart(
                      maxValue: _HukukiSurecSlider.maxValue,
                      value: displayV,
                      barCount: _HukukiSurecSlider.barCount,
                      inactiveColor: _HukukiSurecSlider.trackMuted,
                      activeColor: progressColor,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 96,
                    height: 22,
                    child: _SurecTickRow(width: w),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22, bottom: 24),
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints c) {
                          const double handleR = 11;
                          final double usable = c.maxWidth - 2 * handleR;
                          final double x =
                              handleR + (displayV / _HukukiSurecSlider.maxValue) * usable;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned(
                                left: 0,
                                top: c.maxHeight / 2 -
                                    _SurecHandle.sideForProgress(0) / 2,
                                child: _SurecHandle(
                                  ringColor: greyMode
                                      ? _HukukiSurecSlider.finalizedGrey
                                      : _HukukiSurecSlider.accentForProgress(0),
                                  filled: false,
                                  progress: 0,
                                ),
                              ),
                              Positioned(
                                left: x -
                                    _SurecHandle.sideForProgress(
                                          displayV,
                                        ) /
                                        2,
                                top: c.maxHeight / 2 -
                                    _SurecHandle.sideForProgress(displayV) / 2,
                                child: widget.finalized
                                    ? _SurecHandle(
                                        ringColor:
                                            _HukukiSurecSlider.finalizedGrey,
                                        filled: true,
                                        progress:
                                            _HukukiSurecSlider.maxValue,
                                      )
                                    : GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onHorizontalDragStart: locked
                                            ? null
                                            : (_) {
                                                setState(() {
                                                  _dragValue = _dragValue ?? _value;
                                                });
                                              },
                                        onHorizontalDragUpdate: locked
                                            ? null
                                            : (DragUpdateDetails d) {
                                                setState(() {
                                                  final double cur =
                                                      _dragValue ?? _value;
                                                  final double delta =
                                                      (d.delta.dx / usable) *
                                                          _HukukiSurecSlider
                                                              .maxValue;
                                                  _dragValue = (cur + delta)
                                                      .clamp(
                                                    0.0,
                                                    _HukukiSurecSlider.maxValue,
                                                  );
                                                });
                                              },
                                        onHorizontalDragEnd: locked
                                            ? null
                                            : (_) => _onDragEnd(),
                                        onHorizontalDragCancel: locked
                                            ? null
                                            : () {
                                                setState(() {
                                                  _dragValue = null;
                                                });
                                              },
                                        child: _SurecHandle(
                                          ringColor: greyMode
                                              ? _HukukiSurecSlider
                                                  .finalizedGrey
                                              : progressColor,
                                          filled: true,
                                          progress: displayV,
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        );
      },
    );
  }
}

class _SurecTickRow extends StatelessWidget {
  const _SurecTickRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        for (final int m in _HukukiSurecSlider.milestones)
          Positioned(
            left: width * (m / _HukukiSurecSlider.maxValue) - 12,
            child: Text(
              m == 0 ? '0' : '$m',
              style: TextStyle(
                fontSize: m == 0 ? 13 : 11,
                fontWeight: FontWeight.w800,
                color: m == 0
                    ? _HukukiSurecSlider.accentForProgress(0)
                    : Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }
}

class _SurecHandle extends StatelessWidget {
  const _SurecHandle({
    required this.ringColor,
    required this.filled,
    required this.progress,
  });

  final Color ringColor;
  final bool filled;
  /// 0…114 — en yakın milestone adımına göre çekiç büyür.
  final double progress;

  static const List<double> _milestones = <double>[
    0,
    19,
    38,
    57,
    76,
    95,
    114,
  ];

  static int _nearestIndex(double v) {
    int nearest = 0;
    double bestD = double.infinity;
    for (int i = 0; i < _milestones.length; i++) {
      final double d = (v - _milestones[i]).abs();
      if (d < bestD) {
        bestD = d;
        nearest = i;
      }
    }
    return nearest;
  }

  static double _gavelIconSize(double v) {
    final int n = _nearestIndex(v);
    return 9.5 + n * 1.42 * 3;
  }

  static double sideForProgress(double v) {
    final int n = _nearestIndex(v.clamp(0.0, _HukukiSurecSlider.maxValue));
    return 22 + n * 6.0;
  }

  @override
  Widget build(BuildContext context) {
    final double v = progress.clamp(0.0, _HukukiSurecSlider.maxValue);
    final double side = sideForProgress(v);
    final double iconSize = _gavelIconSize(v);
    final double radius = (side * 0.22).clamp(6.0, 14.0);
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ringColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Icon(
          MdiIcons.gavel,
          size: iconSize,
          color: ringColor,
        ),
      ),
    );
  }
}

class _SurecBarChart extends StatelessWidget {
  const _SurecBarChart({
    required this.maxValue,
    required this.value,
    required this.barCount,
    required this.inactiveColor,
    required this.activeColor,
  });

  final double maxValue;
  final double value;
  final int barCount;
  final Color inactiveColor;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final double fillEnd = (value / maxValue).clamp(0.0, 1.0) * barCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List<Widget>.generate(barCount, (int i) {
        final double h = 18 + (54 * i / (barCount - 1));
        final double t = i.toDouble();
        final bool filled = t < fillEnd - 0.001;
        final double partial = (fillEnd - t).clamp(0.0, 1.0);
        final bool isPartial = !filled && partial > 0 && partial < 1;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: h,
                      color: inactiveColor,
                    ),
                    if (filled)
                      Container(
                        width: double.infinity,
                        height: h,
                        color: activeColor,
                      )
                    else if (isPartial)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          height: h * partial,
                          color: activeColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

