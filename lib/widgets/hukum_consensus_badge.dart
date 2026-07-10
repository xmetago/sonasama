import 'package:flutter/material.dart';

import '../services/dava_consensus_service.dart';

/// 8-Hüküm ekranında çoğunluk sonucunu gösteren bilgi kartı.
/// Dava künyesi ile aynı başlık + [AnimatedCrossFade] (showSecond = daraltılmış) düzeni.
class HukumConsensusBadge extends StatefulWidget {
  const HukumConsensusBadge({
    super.key,
    required this.evaluation,
    required this.isLoading,
    this.onRefresh,
  });

  final DavaConsensusEvaluation? evaluation;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  State<HukumConsensusBadge> createState() => _HukumConsensusBadgeState();
}

class _HukumConsensusBadgeState extends State<HukumConsensusBadge> {
  /// [true] iken içerik gizli (dava künyesi ile aynı: `CrossFadeState.showSecond`).
  bool _sectionExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _sectionExpanded = !_sectionExpanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              ' Çoğunluk Kararı',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: Color(0xFF1B2A23),
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _sectionExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.expand_more,
                              color: Colors.grey.shade600,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Yenile',
                    color: Colors.grey.shade700,
                  ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            sizeCurve: Curves.easeInOutCubic,
            duration: const Duration(milliseconds: 280),
            crossFadeState: _sectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _buildInnerBody(context),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerBody(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoading(context);
    }

    if (widget.evaluation == null) {
      return _buildPlaceholder(context);
    }

    return _buildResultCard(context, widget.evaluation!);
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
        color: Colors.blue.shade50,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Çoğunluk kararı yükleniyor...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade100,
      ),
      child: Text(
        'Hüküm verisi henüz hazır değil.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    DavaConsensusEvaluation evaluation,
  ) {
    final bool isFinal = evaluation.isFinal;
    final Color badgeColor =
        isFinal ? Colors.green.shade600 : Colors.orange.shade700;
    final String statusText = isFinal
        ? 'Ortak akıl kararı kesinleşti'
        : 'Ortak akıl kararı bekleniyor';
    final String decisionText = isFinal
        ? 'Çoğunluk sonucu: ${evaluation.verdictLabel}'
        : 'Şu anki çoğunluk: ${evaluation.verdictLabel}';

    final TextStyle? baseStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isFinal ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: isFinal ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'lib/icons/06_left_row_katildigim_davalar_icon.png',
                  width: 19,
                  height: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _buildCountChip(
                context,
                label: 'Olumlu',
                count: evaluation.positiveCount,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 12),
              _buildCountChip(
                context,
                label: 'Olumsuz',
                count: evaluation.negativeCount,
                color: Colors.blue.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            decisionText,
            style: baseStyle?.copyWith(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (!isFinal) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progressFromEvaluation(evaluation),
                minHeight: 6,
                backgroundColor: Colors.orange.shade100,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.orange.shade500),
              ),
            ),
          ],
          if (!isFinal && evaluation.remainingLabel != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Kararın kesinleşmesine kalan süre: ${evaluation.remainingLabel}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  double _progressFromEvaluation(DavaConsensusEvaluation evaluation) {
    final int total = evaluation.positiveCount + evaluation.negativeCount;
    if (total <= 0) {
      return 0;
    }
    return (evaluation.positiveCount / total).clamp(0, 1);
  }

  Widget _buildCountChip(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
