import 'package:flutter/material.dart';

/// Uzun yorum metinlerini kırpar; gerektiğinde "Daha fazla gör" bağlantısı gösterir.
class ExpandableCommentText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final String expandLabel;
  final String collapseLabel;
  final Color? linkColor;

  const ExpandableCommentText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 4,
    this.expandLabel = 'Daha fazla gör',
    this.collapseLabel = 'Daha az gör',
    this.linkColor,
  });

  @override
  State<ExpandableCommentText> createState() => _ExpandableCommentTextState();
}

class _ExpandableCommentTextState extends State<ExpandableCommentText> {
  bool _isExpanded = false;
  bool? _isOverflowing;

  @override
  void didUpdateWidget(ExpandableCommentText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.maxLines != widget.maxLines ||
        oldWidget.style != widget.style) {
      _isExpanded = false;
      _isOverflowing = null;
    }
  }

  bool _checkOverflow(double maxWidth, BuildContext context) {
    final effectiveWidth = maxWidth.isFinite && maxWidth > 0
        ? maxWidth
        : MediaQuery.sizeOf(context).width - 48;
    final textStyle = widget.style ?? const TextStyle();
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: textStyle),
      maxLines: widget.maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: effectiveWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    final textStyle = widget.style ?? const TextStyle();
    final linkColor = widget.linkColor ?? Colors.blue.shade700;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isOverflowing =
            _isOverflowing ?? _checkOverflow(maxWidth, context);
        if (_isOverflowing == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final overflow = _checkOverflow(maxWidth, context);
            if (_isOverflowing != overflow) {
              setState(() => _isOverflowing = overflow);
            }
          });
        }

        final showToggle = isOverflowing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: textStyle,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (showToggle)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? widget.collapseLabel : widget.expandLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: linkColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
