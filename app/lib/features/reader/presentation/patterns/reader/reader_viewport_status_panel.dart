import 'package:flutter/material.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_page_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'reader_viewport_error_panel.dart';

/// Lab 阅读画布：打开中（静态）。
class ReaderViewportLoading extends StatelessWidget {
  const ReaderViewportLoading({super.key});

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
              ReaderPageCopy.viewportLoading,
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
