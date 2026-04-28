import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

class HentaiDialog extends StatelessWidget {
  const HentaiDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.width = 420,
    this.cardSurfaceKey,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final double width;

  final Key? cardSurfaceKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 三层阴影：环境光（与页面分离）+ 主抬升 + 贴边接触阴影，浅色下尤其增强层次感
    final ambient = isDark
        ? Colors.black.withAlpha(52)
        : Colors.black.withAlpha(14);
    final contact = isDark
        ? Colors.black.withAlpha(72)
        : Colors.black.withAlpha(22);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        key: cardSurfaceKey,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: cs.cardHover,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: ambient,
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: cs.cardShadowHover,
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: cs.cardShadow,
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: contact,
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: content,
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: cs.borderSubtle, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
