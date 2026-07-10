import 'package:flutter/material.dart';

/// Tek satır [shortName] veya `\n` ile iki satır (ilk büyük / ikinci küçük).
class HukumGiftShortNameText extends StatelessWidget {
  const HukumGiftShortNameText({
    super.key,
    required this.shortName,
    required this.primaryStyle,
    required this.secondaryStyle,
    this.textAlign = TextAlign.center,
    this.maxLines = 2,
  });

  final String shortName;
  final TextStyle primaryStyle;
  final TextStyle secondaryStyle;
  final TextAlign textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final int i = shortName.indexOf('\n');
    if (i < 0) {
      return Text(
        shortName,
        style: primaryStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final String line1 = shortName.substring(0, i);
    final String line2 = shortName.substring(i + 1);
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: line1, style: primaryStyle),
          const TextSpan(text: '\n'),
          TextSpan(text: line2, style: secondaryStyle),
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
