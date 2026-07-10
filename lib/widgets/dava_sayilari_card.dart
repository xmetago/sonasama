import 'package:flutter/material.dart';

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
    required this.accentDark,
  });

  final IconData icon;
  final String label;
  final String shortLabel;
  final int count;
  final Color accent;
  final Color accentDark;
}

/// Dava sayıları özeti kartı — seyir defteri kartlarıyla uyumlu modern düzen.
class DavaSayilariCard extends StatelessWidget {
  static const Color _borderColor = Color(0xFFE6E6E6);
  static const Color _titleColor = Color(0xFF1B2A23);
  static const Color _mutedColor = Color(0xFF6B7280);

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
          accent: const Color(0xFF3B82F6),
          accentDark: const Color(0xFF1D4ED8),
        ),
        _StatMetric(
          icon: Icons.verified_rounded,
          label: 'Haklı olduğum',
          shortLabel: 'Haklı',
          count: hakli,
          accent: const Color(0xFF34DFAE),
          accentDark: const Color(0xFF0C7A54),
        ),
        _StatMetric(
          icon: Icons.highlight_off_rounded,
          label: 'Haksız olduğum',
          shortLabel: 'Haksız',
          count: haksiz,
          accent: const Color(0xFFF87171),
          accentDark: const Color(0xFFB91C1C),
        ),
        _StatMetric(
          icon: Icons.mark_email_unread_rounded,
          label: 'Bana açılan',
          shortLabel: 'Açılan',
          count: banaAcilan,
          accent: const Color(0xFFFBBF24),
          accentDark: const Color(0xFFB45309),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHeaderTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xFFECFDF5),
                            Color(0xFFD1FAE5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        size: 20,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Dava Sayıları',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                              letterSpacing: 0.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TotalBadge(count: katildigim),
                    const SizedBox(width: 8),
                    _ExpandChip(expanded: expanded),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            sizeCurve: Curves.easeInOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      const double gap = 10;
                      final double tileWidth =
                          (constraints.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: _metrics
                            .map(
                              (_StatMetric m) => SizedBox(
                                width: tileWidth,
                                child: _StatTile(
                                  icon: m.icon,
                                  label: m.label,
                                  count: m.count,
                                  accent: m.accent,
                                  accentDark: m.accentDark,
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
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _metrics
                          .map(
                            (_StatMetric m) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _MiniStatChip(
                                icon: m.icon,
                                label: m.shortLabel,
                                count: m.count,
                                accent: m.accent,
                                accentDark: m.accentDark,
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
    );
  }
}

class _TotalBadge extends StatelessWidget {
  final int count;

  const _TotalBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.gavel_rounded,
            size: 13,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandChip extends StatelessWidget {
  final bool expanded;

  const _ExpandChip({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: expanded ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: expanded ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
        ),
      ),
      child: AnimatedRotation(
        turns: expanded ? 0 : 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: expanded ? const Color(0xFF15803D) : const Color(0xFF6B7280),
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
  final Color? accentDark;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.accent,
    this.accentDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color dark = accentDark ?? accent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: dark),
              ),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: dark,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
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
  final Color accentDark;

  const _MiniStatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.accent,
    required this.accentDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: accentDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accentDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
