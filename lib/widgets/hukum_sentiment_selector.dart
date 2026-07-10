import 'package:flutter/material.dart';

import '../models/hukum_sentiment.dart';

/// Hüküm metni için olumlu/olumsuz seçim yapılmasını sağlayan widget.
class HukumSentimentSelector extends StatelessWidget {
  final HukumSentiment? selectedSentiment;
  final ValueChanged<HukumSentiment
  > onSentimentSelected;
  final bool isDisabled;
  final bool hidePartySideLabels;
  /// Hüküm kesinleşince veya üst widget gizlediğinde başlık satırını gösterme.
  final bool hidePromptTitle;

  const HukumSentimentSelector({
    super.key,
    required this.selectedSentiment,
    required this.onSentimentSelected,
    this.isDisabled = false,
    this.hidePartySideLabels = false,
    this.hidePromptTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!hidePromptTitle) ...<Widget>[
          Text(
            'Hüküm Yönünüzü Seçin',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDisabled ? Colors.grey.shade500 : Colors.grey.shade800,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: <Widget>[
            Expanded(child: _buildOption(context, HukumSentiment.positive)),
            const SizedBox(width: 12),
            Expanded(child: _buildOption(context, HukumSentiment.negative)),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, HukumSentiment sentiment) {
    final bool isSelected = selectedSentiment == sentiment;
    final Color baseColor = sentiment.color;
    final bool disabled = isDisabled;

    return Semantics(
      button: true,
      toggled: isSelected,
      label: sentiment.label,
      hint: sentiment.description,
      child: InkWell(
        onTap: disabled ? null : () => onSentimentSelected(sentiment),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isSelected
                ? LinearGradient(
                    colors: <Color>[
                      baseColor.withOpacity(0.28),
                      baseColor.withOpacity(0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: <Color>[
                      disabled ? Colors.grey.shade200 : Colors.grey.shade100,
                      disabled ? Colors.grey.shade300 : Colors.grey.shade200,
                    ],
                  ),
            border: Border.all(
              color: isSelected
                  ? (disabled ? baseColor.withOpacity(0.6) : baseColor)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: (disabled ? baseColor.withOpacity(0.18) : baseColor.withOpacity(0.28)),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                sentiment.icon,
                size: 28,
                color: isSelected
                    ? Colors.white
                    : (disabled ? baseColor.withOpacity(0.5) : baseColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      sentiment.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (disabled ? baseColor.withOpacity(0.6) : baseColor),
                          ),
                    ),
                    if (!hidePartySideLabels) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        sentiment == HukumSentiment.positive
                            ? 'Davacı Haklı'
                            : 'Davalı Haklı',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : (disabled
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade700),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

