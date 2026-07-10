import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Metin içindeki #hashtag yapılarını mavi renkte göstermek için TextSpan listesi üretir.
/// Örnek: "Merhaba #Epstein dünya" -> normal metin + mavi #Epstein + normal metin
List<InlineSpan> buildHashtagAwareSpans(
  String text, {
  required TextStyle baseStyle,
  Color? hashtagColor,
}) {
  if (text.isEmpty) {
    return [TextSpan(text: '', style: baseStyle)];
  }
  final color = hashtagColor ?? AppTheme.infoColor; // Mavi
  final regex = RegExp(r'#\w+');
  final spans = <InlineSpan>[];
  int lastEnd = 0;
  for (final m in regex.allMatches(text)) {
    if (m.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, m.start),
        style: baseStyle,
      ));
    }
    spans.add(TextSpan(
      text: m.group(0),
      style: baseStyle.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ));
    lastEnd = m.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: baseStyle,
    ));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: baseStyle));
  }
  return spans;
}
