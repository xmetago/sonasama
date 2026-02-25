import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../services/dava_consensus_service.dart';

/// 8-Hüküm ekranında çoğunluk sonucunu gösteren bilgi kartı.
class HukumConsensusBadge extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoading(context);
    }

    if (evaluation == null) {
      return _buildPlaceholder(context);
    }

    return _buildResultCard(context, evaluation!);
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
    final Color badgeColor = isFinal ? Colors.green.shade600 : Colors.orange.shade600;
    final IconData badgeIcon =
        isFinal ? MdiIcons.shieldCheck : MdiIcons.timerSand;
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: <Color>[
            badgeColor.withOpacity(0.18),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: badgeColor.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: badgeColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(badgeIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Yenile',
                  color: badgeColor,
                ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text(
            decisionText,
            style: baseStyle?.copyWith(
              fontSize: 15,
              color: badgeColor,
            ),
          ),
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

  Widget _buildCountChip(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          color: color.withOpacity(0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }
}

