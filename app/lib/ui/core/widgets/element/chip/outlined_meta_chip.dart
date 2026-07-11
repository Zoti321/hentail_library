import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// 描边胶囊 chip，用于详情页作者/标签等元数据展示。
class OutlinedMetaChip extends StatelessWidget {
  const OutlinedMetaChip({
    super.key,
    required this.text,
    this.borderColor,
    this.textColor,
  });

  final String text;
  final Color? borderColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final TextStyle textStyle = TextStyle(
      fontSize: tokens.text.labelXs,
      height: 1.2,
      color: textColor ?? cs.hentai.textSecondary,
      fontWeight: FontWeight.w500,
    );
    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(tokens.radius.pill),
          border: Border.all(color: borderColor ?? cs.hentai.borderSubtle),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      ),
    );
  }
}
