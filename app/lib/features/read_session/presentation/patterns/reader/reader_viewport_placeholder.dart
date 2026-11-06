import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_page_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 阅读画布占位：竖向贴边、左右 letterbox（非 FRB 图像）。
class ReaderViewportPlaceholder extends StatelessWidget {
  const ReaderViewportPlaceholder({super.key, required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final M3ETypeScale type = M3ETheme.of(context).typeScale;
    final double horizontalInset =
        ReaderChromeMetrics.viewportHorizontalInset(
          MediaQuery.sizeOf(context).width,
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: ColoredBox(
        color: scheme.surfaceBright,
        child: Center(
          child: Text(
            ReaderPageCopy.viewportPlaceholder(page),
            style: type.bodyLarge.copyWith(
              color: scheme.scrim.withValues(alpha: 0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
