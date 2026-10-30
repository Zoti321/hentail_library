import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_copy.dart';
import 'package:hentai_library/md3e/theme/md3e_lab_text.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 阅读画布：打开中（静态）。
class Md3eReaderViewportLoading extends StatelessWidget {
  const Md3eReaderViewportLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceBright,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              Md3eReaderPageCopy.viewportLoading,
              style: theme.typeScale.bodyLarge.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lab 阅读画布：打开失败（静态；与生产 ReaderOpenErrorPanel 操作项对齐）。
class Md3eReaderViewportErrorPanel extends StatelessWidget {
  const Md3eReaderViewportErrorPanel({
    super.key,
    this.onBack,
    this.onRetry,
  });

  final VoidCallback? onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle actionLabelStyle =
        md3eLabButtonLabelStyle(theme, M3EButtonSize.sm);
    return ColoredBox(
      color: theme.colorScheme.surfaceBright,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  Md3eReaderPageCopy.viewportErrorMessage,
                  textAlign: TextAlign.center,
                  style: theme.typeScale.bodyLarge.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    if (onBack != null)
                      M3EButton(
                        onPressed: onBack,
                        style: M3EButtonStyle.text,
                        decoration: M3EButtonDecoration(
                          textStyle: actionLabelStyle,
                        ),
                        label: Text(Md3eReaderPageCopy.viewportErrorBack),
                      ),
                    if (onRetry != null)
                      M3EButton(
                        onPressed: onRetry,
                        style: M3EButtonStyle.filled,
                        decoration: M3EButtonDecoration(
                          textStyle: actionLabelStyle,
                        ),
                        label: Text(Md3eReaderPageCopy.viewportErrorRetry),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
