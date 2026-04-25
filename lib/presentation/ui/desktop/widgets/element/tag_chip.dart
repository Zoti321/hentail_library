import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius radius = BorderRadius.circular(tokens.radius.pill);
    const Color chipBackground = Color(0xFFFFFFFF);
    final TextStyle textStyle = TextStyle(
      fontSize: tokens.text.labelXs,
      height: 1.2,
      letterSpacing: 0.1,
      color: cs.textSecondary,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: BoxConstraints(maxWidth: 128),
        decoration: BoxDecoration(
          color: chipBackground,
          borderRadius: radius,
          border: Border.all(color: cs.borderSubtle, width: 1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isTruncated = _isTextTruncated(
              context: context,
              maxWidth: constraints.maxWidth,
              textStyle: textStyle,
            );
            Widget textWidget = Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            );
            if (isTruncated) {
              textWidget = Tooltip(
                message: text,
                waitDuration: const Duration(milliseconds: 1200),
                child: textWidget,
              );
            }
            return textWidget;
          },
        ),
      ),
    );
  }

  bool _isTextTruncated({
    required BuildContext context,
    required double maxWidth,
    required TextStyle textStyle,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }
}
