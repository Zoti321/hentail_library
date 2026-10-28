import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_band.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_progress.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 阅读器底栏：scrim 上的进度 · 翻页 · 自动播放。
class Md3eReaderBottomBar extends StatelessWidget {
  const Md3eReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onPreviousPage,
    required this.onNextPage,
    this.autoPlayEnabled = false,
    this.onAutoPlayChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final bool autoPlayEnabled;
  final ValueChanged<bool>? onAutoPlayChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final MediaQueryData media = MediaQuery.of(context);
    final bool canPrev = currentPage > 1;
    final bool canNext = totalPages > 0 && currentPage < totalPages;
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      12,
      8,
      12,
      media.padding.bottom + Md3eReaderChromeMetrics.edgeGap,
    );

    return Md3eReaderChromeBand(
      edge: Md3eReaderChromeBandEdge.bottom,
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Md3eReaderChromeMetrics.bottomBarMinHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Md3eReaderPageProgress(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageChanged: onPageChanged,
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                _iconButton(
                  context: context,
                  icon: Symbols.chevron_left,
                  tooltip: l10n.readerPrevPage,
                  semanticLabel: l10n.readerPrevPage,
                  onPressed: canPrev ? onPreviousPage : null,
                ),
                const Spacer(),
                if (onAutoPlayChanged != null)
                  _iconButton(
                    context: context,
                    icon: autoPlayEnabled ? Symbols.pause : Symbols.play_arrow,
                    tooltip: l10n.readerSettingsAutoPlay,
                    semanticLabel: l10n.readerSettingsAutoPlay,
                    onPressed: () => onAutoPlayChanged!(!autoPlayEnabled),
                    filled: autoPlayEnabled,
                  ),
                const Spacer(),
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
    final Color foreground = Md3eReaderChromeScope.of(context).onChrome;
    return M3EIconButton(
      icon: Icon(
        icon,
        size: Md3eReaderChromeMetrics.actionIconSize,
        color: foreground,
      ),
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
