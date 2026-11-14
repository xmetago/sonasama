import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';
import 'home_feed_card_shell.dart';

/// Tek bir dava istatistik satırı (geriye dönük uyumluluk).
class DavaRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final Color countColor;

  const DavaRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return _StatTile(
      icon: icon,
      label: label,
      count: count,
      accent: countColor,
      ratio: 1,
    );
  }
}

class _StatMetric {
  const _StatMetric({
    required this.icon,
    required this.label,
    required this.shortLabel,
    required this.count,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String shortLabel;
  final int count;
  final Color accent;
}

/// Dava sayıları özeti. Sayılar büyük, karolar marka renginde, altında oran çubuğu.
class DavaSayilariCard extends StatelessWidget {
  final int katildigim;
  final int hakli;
  final int haksiz;
  final int banaAcilan;
  final bool expanded;
  final VoidCallback? onHeaderTap;

  /// [true] ise metinler açtığım davalar (davacı) sayfasına göre gösterilir.
  final bool actigimMode;

  const DavaSayilariCard({
    super.key,
    required this.katildigim,
    required this.hakli,
    required this.haksiz,
    required this.banaAcilan,
    this.expanded = true,
    this.onHeaderTap,
    this.actigimMode = false,
  });

  String get _subtitle =>
      actigimMode ? 'Açılan dava ve sonuç özeti' : 'Katılım ve sonuç özeti';

  List<_StatMetric> get _metrics => <_StatMetric>[
        _StatMetric(
          icon: actigimMode ? Icons.gavel_rounded : Icons.groups_rounded,
          label: actigimMode ? 'Açtığım' : 'Katıldığım',
          shortLabel: actigimMode ? 'Açılan' : 'Katılım',
          count: katildigim,
          accent: SeyirTokens.brandDeep,
        ),
        _StatMetric(
          icon: Icons.verified_rounded,
          label: 'Haklı olduğum',
          shortLabel: 'Haklı',
          count: hakli,
          accent: SeyirTokens.accept,
        ),
        _StatMetric(
          icon: Icons.highlight_off_rounded,
          label: 'Haksız olduğum',
          shortLabel: 'Haksız',
          count: haksiz,
          accent: SeyirTokens.reject,
        ),
        _StatMetric(
          icon: Icons.mark_email_unread_rounded,
          label: 'Bana açılan',
          shortLabel: 'Açılan',
          count: banaAcilan,
          accent: SeyirTokens.brand,
        ),
      ];

  int get _peak {
    var peak = 0;
    for (final _StatMetric metric in _metrics) {
      if (metric.count > peak) peak = metric.count;
    }
    return peak;
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Padding(
      padding: HomeFeedCardShell.cardMargin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusMdAll,
          border: Border.all(color: palette.border),
          boxShadow: palette.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: SeyirTokens.radiusMdAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onHeaderTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SeyirTokens.space4,
                      SeyirTokens.space4,
                      SeyirTokens.space3,
                      SeyirTokens.space4,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: SeyirTokens.tapTarget,
                          height: SeyirTokens.tapTarget,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.brandSoft,
                            borderRadius: SeyirTokens.radiusMdAll,
                          ),
                          child: Icon(
                            Icons.analytics_outlined,
                            size: 22,
                            color: palette.foreground(SeyirTokens.brandDeep),
                          ),
                        ),
                        const SizedBox(width: SeyirTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Dava Sayıları', style: palette.title()),
                              const SizedBox(height: SeyirTokens.space1),
                              Text(
                                _subtitle,
                                style: palette.caption(),
                              ),
                            ],
                          ),
                        ),
                        _TotalBadge(count: katildigim),
                        const SizedBox(width: SeyirTokens.space2),
                        _ExpandChip(expanded: expanded),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: SeyirTokens.motion,
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeInCubic,
                sizeCurve: Curves.easeInOutCubic,
                crossFadeState: expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SeyirTokens.space3,
                    0,
                    SeyirTokens.space3,
                    SeyirTokens.space4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Divider(height: 1, color: palette.border),
                      const SizedBox(height: SeyirTokens.space3),
                      LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          const double gap = SeyirTokens.space2;
                          final double tileWidth =
                              (constraints.maxWidth - gap) / 2;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: _metrics
                                .map(
                                  (_StatMetric metric) => SizedBox(
                                    width: tileWidth,
                                    child: _StatTile(
                                      icon: metric.icon,
                                      label: metric.label,
                                      count: metric.count,
                                      accent: metric.accent,
                                      ratio: _peak == 0
                                          ? 0
                                          : metric.count / _peak,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SeyirTokens.space3,
                    0,
                    SeyirTokens.space3,
                    SeyirTokens.space4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Divider(height: 1, color: palette.border),
                      const SizedBox(height: SeyirTokens.space2),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _metrics
                              .map(
                                (_StatMetric metric) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: SeyirTokens.space2,
                                  ),
                                  child: _MiniStatChip(
                                    icon: metric.icon,
                                    label: metric.shortLabel,
                                    count: metric.count,
                                    accent: metric.accent,
                                    ratio: _peak == 0
                                        ? 0
                                        : metric.count / _peak,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
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

class _TotalBadge extends StatelessWidget {
  final int count;

  const _TotalBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space3,
        vertical: SeyirTokens.space1,
      ),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
        border: Border.all(color: palette.tintBorder(SeyirTokens.brand)),
      ),
      child: Text(
        '$count',
        style: palette.body(
          weight: FontWeight.w800,
          color: palette.foreground(SeyirTokens.brandDeep),
        ),
      ),
    );
  }
}

class _ExpandChip extends StatelessWidget {
  final bool expanded;

  const _ExpandChip({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: SeyirTokens.tapTarget,
      height: SeyirTokens.tapTarget,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: expanded ? palette.brandSoft : palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusSmAll,
        border: Border.all(
          color: expanded
              ? palette.tintBorder(SeyirTokens.brand)
              : palette.border,
        ),
      ),
      child: AnimatedRotation(
        turns: expanded ? 0 : 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 22,
          color: expanded
              ? palette.foreground(SeyirTokens.brandDeep)
              : palette.textSecondary,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color accent;
  final double ratio;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.accent,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color ink = palette.foreground(accent);
    return Container(
      padding: const EdgeInsets.all(SeyirTokens.space3),
      decoration: BoxDecoration(
        color: palette.tint(accent),
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: palette.tintBorder(accent)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: ink),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            '$count',
            style: palette.display(color: ink),
          ),
          const SizedBox(height: SeyirTokens.space1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.caption(color: palette.textPrimary),
          ),
          const SizedBox(height: SeyirTokens.space2),
          ClipRRect(
            borderRadius: SeyirTokens.radiusSmAll,
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 6,
              backgroundColor: palette.surfaceMuted,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color accent;
  final double ratio;

  const _MiniStatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.accent,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color ink = palette.foreground(accent);
    return Container(
      width: 132,
      padding: const EdgeInsets.all(SeyirTokens.space2),
      decoration: BoxDecoration(
        color: palette.tint(accent),
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: palette.tintBorder(accent)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: ink),
              const SizedBox(width: SeyirTokens.space1),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette.caption(color: palette.textPrimary),
                ),
              ),
              Text(
                '$count',
                style: palette.body(weight: FontWeight.w800, color: ink),
              ),
            ],
          ),
          const SizedBox(height: SeyirTokens.space2),
          ClipRRect(
            borderRadius: SeyirTokens.radiusSmAll,
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 4,
              backgroundColor: palette.surfaceMuted,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
