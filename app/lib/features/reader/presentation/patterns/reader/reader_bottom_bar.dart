import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reader/domain/auto_play_interval.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_chrome_band.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_page_progress.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 阅读器底栏：tonal 面板上的进度 · 翻页 · 自动播放。
class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onPreviousPage,
    required this.onNextPage,
    this.autoPlayEnabled = false,
    this.autoPlayIntervalSeconds = kReaderAutoPlayIntervalDefault,
    this.onAutoPlayChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final bool autoPlayEnabled;
  final int autoPlayIntervalSeconds;
  final ValueChanged<bool>? onAutoPlayChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final MediaQueryData media = MediaQuery.of(context);
    final double width = media.size.width;
    final bool canPrev = currentPage > 1;
    final bool canNext = totalPages > 0 && currentPage < totalPages;
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      ReaderChromeMetrics.chromeContentHorizontalPadding(width),
      ReaderChromeMetrics.bottomBarTopPaddingOf(width),
      ReaderChromeMetrics.chromeContentHorizontalPadding(width),
      media.padding.bottom + ReaderChromeMetrics.edgeGapOf(width),
    );

    return ReaderChromeBand(
      edge: ReaderChromeBandEdge.bottom,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: ReaderChromeMetrics.bottomBarMinHeightOf(width),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ReaderPageProgress(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageChanged: onPageChanged,
              autoPlayEnabled: autoPlayEnabled,
              autoPlayIntervalSeconds: autoPlayIntervalSeconds,
            ),
            SizedBox(height: ReaderChromeMetrics.progressControlsGapOf(width)),
            Row(
              children: <Widget>[
                _iconButton(
                  context: context,
                  icon: Symbols.chevron_left,
                  tooltip: l10n.readerPrevPage,
                  semanticLabel: l10n.readerPrevPage,
                  onPressed: canPrev ? onPreviousPage : null,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: onAutoPlayChanged != null
                        ? _iconButton(
                            context: context,
                            icon: autoPlayEnabled
                                ? Symbols.pause
                                : Symbols.play_arrow,
                            tooltip: l10n.readerSettingsAutoPlay,
                            semanticLabel: l10n.readerSettingsAutoPlay,
                            onPressed: () =>
                                onAutoPlayChanged!(!autoPlayEnabled),
                            filled: autoPlayEnabled,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                _iconButton(
                  context: context,
                  icon: Symbols.chevron_right,
                  tooltip: l10n.readerNextPage,
                  semanticLabel: l10n.readerNextPage,
                  onPressed: canNext ? onNextPage : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _iconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required String semanticLabel,
    VoidCallback? onPressed,
    bool filled = false,
  }) {
    final double iconSize = ReaderChromeMetrics.actionIconSizeOf(
      MediaQuery.sizeOf(context).width,
    );
    return M3EIconButton(
      icon: Icon(icon, size: iconSize),
      variant: filled
          ? M3EIconButtonVariant.tonal
          : M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
    );
  }
}
