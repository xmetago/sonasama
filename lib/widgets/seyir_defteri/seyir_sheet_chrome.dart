import 'package:flutter/material.dart';

import '../../theme/seyir_tokens.dart';

/// Alt sayfanın üstündeki tutamaç.
class SeyirDragHandle extends StatelessWidget {
  const SeyirDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: SeyirTokens.space2,
        bottom: SeyirTokens.space1,
      ),
      child: Center(
        child: Semantics(
          label: 'Sayfayı sürükle',
          child: Container(
            key: const Key('seyir-drag-handle'),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: palette.border,
              borderRadius: SeyirTokens.radiusSmAll,
            ),
          ),
        ),
      ),
    );
  }
}

/// Davacı, davalı ve kategori için küçük etiket.
class SeyirMetaChip extends StatelessWidget {
  const SeyirMetaChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space2,
        vertical: SeyirTokens.space1,
      ),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: SeyirTokens.radiusSmAll,
        border: Border.all(color: palette.tintBorder(SeyirTokens.brand)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: palette.foreground(SeyirTokens.brandDeep)),
          const SizedBox(width: SeyirTokens.space1),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette.caption(
                weight: FontWeight.w700,
                color: palette.foreground(SeyirTokens.brandDeep),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SeyirCountBadge extends StatelessWidget {
  const SeyirCountBadge({
    super.key,
    required this.count,
    required this.accent,
  });

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space2,
        vertical: SeyirTokens.space1,
      ),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: SeyirTokens.radiusMdAll,
      ),
      child: Text(
        '$count',
        style: palette.caption(
          weight: FontWeight.w800,
          color: palette.onSolid(accent),
        ),
      ),
    );
  }
}

/// Aynı future'ı dinleyerek bölüm başlığında adet gösterir.
class SeyirFutureCount<T> extends StatelessWidget {
  const SeyirFutureCount({
    super.key,
    required this.future,
    required this.countOf,
    required this.accent,
  });

  final Future<T>? future;
  final int Function(T data) countOf;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pending = future;
    if (pending == null) return const SizedBox.shrink();
    return FutureBuilder<T>(
      future: pending,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return SeyirCountBadge(
          count: countOf(snapshot.data as T),
          accent: accent,
        );
      },
    );
  }
}

/// Sol şeritli, sayaçlı, açılıp kapanan bölüm kartı.
class SeyirSectionCard extends StatefulWidget {
  const SeyirSectionCard({
    super.key,
    required this.title,
    required this.accent,
    required this.icon,
    required this.child,
    this.badge,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  final String title;
  final Color accent;
  final IconData icon;
  final Widget child;
  final Widget? badge;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<SeyirSectionCard> createState() => _SeyirSectionCardState();
}

class _SeyirSectionCardState extends State<SeyirSectionCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() {
    final next = !_expanded;
    widget.onExpansionChanged?.call(next);
    setState(() => _expanded = next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: palette.border),
        boxShadow: palette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: SeyirTokens.radiusMdAll,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: widget.accent, width: 4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _toggle,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minHeight: SeyirTokens.tapTarget),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeyirTokens.space3,
                      vertical: SeyirTokens.space2,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.tint(widget.accent),
                            borderRadius: SeyirTokens.radiusSmAll,
                            border: Border.all(
                              color: palette.tintBorder(widget.accent),
                            ),
                          ),
                          child:
                              Icon(widget.icon, size: 18, color: widget.accent),
                        ),
                        const SizedBox(width: SeyirTokens.space2),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: palette.title(weight: FontWeight.w700),
                          ),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: SeyirTokens.space2),
                          widget.badge!,
                        ],
                        const SizedBox(width: SeyirTokens.space2),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: SeyirTokens.motion,
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.expand_more,
                            color: widget.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: SeyirTokens.motion,
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _expanded ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SeyirTokens.space3,
                        0,
                        SeyirTokens.space3,
                        SeyirTokens.space3,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İki sütunlu bilgi ızgarasının tek hücresi.
class SeyirInfoTile extends StatelessWidget {
  const SeyirInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.labelTrailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeyirTokens.space3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: SeyirTokens.sectionAppeal),
                      const SizedBox(width: SeyirTokens.space2),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette.caption(weight: FontWeight.w700),
                        ),
                      ),
                      if (labelTrailing != null) labelTrailing!,
                    ],
                  ),
                  const SizedBox(height: SeyirTokens.space2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: palette.title(weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: SeyirTokens.space2),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class SeyirEmptyState extends StatelessWidget {
  const SeyirEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.accent,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final tone = accent ?? palette.textMuted;
    final pad = compact ? SeyirTokens.space3 : SeyirTokens.space4;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: accent == null ? palette.surfaceMuted : palette.tint(tone),
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(
          color: accent == null ? palette.border : palette.tintBorder(tone),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 28 : 36, color: tone),
          const SizedBox(height: SeyirTokens.space2),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: palette.title(color: palette.foreground(tone)),
            ),
            const SizedBox(height: SeyirTokens.space1),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: palette.body(
              color: accent == null
                  ? palette.textSecondary
                  : palette.foreground(tone),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ek paket olmadan kayan iskelet.
class SeyirShimmer extends StatefulWidget {
  const SeyirShimmer({
    super.key,
    this.lines = 3,
    this.height = 14,
  });

  final int lines;
  final double height;

  @override
  State<SeyirShimmer> createState() => _SeyirShimmerState();
}

class _SeyirShimmerState extends State<SeyirShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final base = palette.surfaceMuted;
    final highlight = Color.alphaBlend(
      palette.textPrimary.withValues(alpha: palette.isDark ? 0.14 : 0.08),
      base,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.lines; i++) ...[
              if (i > 0) const SizedBox(height: SeyirTokens.space2),
              Container(
                height: widget.height,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: SeyirTokens.radiusSmAll,
                  gradient: LinearGradient(
                    begin: Alignment(-1.2 + _controller.value * 2.4, 0),
                    end: Alignment(-0.2 + _controller.value * 2.4, 0),
                    colors: [base, highlight, base],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class SeyirLoadingBlock extends StatelessWidget {
  const SeyirLoadingBlock({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SeyirTokens.space4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: palette.border),
      ),
      child: SeyirShimmer(lines: lines),
    );
  }
}

/// Etkileşim hücresi: en az 44px, aktifken dolu ikon, sayıda küçük ölçek.
class SeyirEngagementButton extends StatelessWidget {
  const SeyirEngagementButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.showCount = true,
    this.alwaysShowCount = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final bool showCount;
  final bool alwaysShowCount;

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final color = isActive ? activeColor : inactiveColor;
    final displayCount = showCount && (alwaysShowCount || count > 0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: SeyirTokens.tapTarget,
            minWidth: SeyirTokens.tapTarget,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.12 : 1,
                  duration: SeyirTokens.motion,
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: SeyirTokens.motion,
                    padding: const EdgeInsets.all(SeyirTokens.space1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeColor.withValues(alpha: 0.16)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 22,
                      color: color,
                    ),
                  ),
                ),
                if (displayCount) ...[
                  const SizedBox(width: SeyirTokens.space1),
                  AnimatedSwitcher(
                    duration: SeyirTokens.motion,
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '$count',
                      key: ValueKey<int>(count),
                      style: palette.body(
                        weight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
