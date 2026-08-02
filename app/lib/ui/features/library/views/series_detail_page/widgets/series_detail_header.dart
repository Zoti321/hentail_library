import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/page_size_menu.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_series_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/metadata_refresh_progress_dialog.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_back_header.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailHeader extends ConsumerWidget {
  const SeriesDetailHeader({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final int activePageSize = ref.watch(seriesDetailActivePageSizeProvider);
    final AppLocalizations l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.hentai.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                GhostButton.icon(
                  icon: LucideIcons.arrowLeft,
                  tooltip: l10n.shellBack,
                  semanticLabel: l10n.shellBack,
                  iconSize: 16,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.iconDefault,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor,
                  onPressed: () =>
                      ComicDetailBackHeader.popOrGoLibrary(context),
                ),
                const SizedBox(width: 4),
                _SeriesDetailOverflowMenuButton(series: series),
                const SizedBox(width: 4),
                GhostButton.icon(
                  icon: LucideIcons.pencil,
                  tooltip: l10n.seriesDetailEdit,
                  semanticLabel: l10n.seriesDetailEdit,
                  iconSize: 16,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.iconDefault,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor,
                  onPressed: () {
                    showEditSeriesDialog(context: context, series: series);
                  },
                ),
                const Spacer(),
                PageSizeMenuButton(
                  activePageSize: activePageSize,
                  onSelected: (int pageSize) {
                    ref
                        .read(seriesDetailPageSizeProvider.notifier)
                        .setPageSize(pageSize);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesDetailOverflowMenuButton extends ConsumerStatefulWidget {
  const _SeriesDetailOverflowMenuButton({required this.series});

  final Series series;

  @override
  ConsumerState<_SeriesDetailOverflowMenuButton> createState() =>
      _SeriesDetailOverflowMenuButtonState();
}

class _SeriesDetailOverflowMenuButtonState
    extends ConsumerState<_SeriesDetailOverflowMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final bool writeBusy =
        ref.watch(scanLibraryControllerProvider).running ||
        ref.watch(metadataRefreshControllerProvider).running;
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -32,
      menuBuilder: () => PopupMenuPanelShell(
        width: 200,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        borderRadius: tokens.radius.xs,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SeriesDetailOverflowMenuItem(
                icon: LucideIcons.refreshCw,
                label: l10n.refreshMetadata,
                enabled: !writeBusy,
                onTap: () {
                  _controller.hideMenu();
                  _refreshMetadata(context);
                },
              ),
              _SeriesDetailOverflowMenuItem(
                icon: LucideIcons.folderOpen,
                label: l10n.comicDetailShowInExplorer,
                onTap: () {
                  _controller.hideMenu();
                  showInFileExplorer(widget.series.folderPath).catchError((
                    Object error,
                    StackTrace stackTrace,
                  ) {
                    if (!context.mounted) {
                      return;
                    }
                    if (error is AppException) {
                      showErrorToast(context, error);
                      return;
                    }
                    showErrorToast(
                      context,
                      AppException(
                        l10n.comicDetailShowInExplorerFailed,
                        cause: error,
                        stackTrace: stackTrace,
                      ),
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: l10n.libraryMoreActions,
        semanticLabel: l10n.libraryMoreActionsSemantic,
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.iconDefault,
        hoverColor: theme.hoverColor,
        overlayColor: theme.hoverColor,
        onPressed: () => _controller.toggleMenu(),
      ),
    );
  }

  Future<void> _refreshMetadata(BuildContext context) async {
    final Future<void> future = ref
        .read(metadataRefreshControllerProvider.notifier)
        .refreshSeries(
          seriesId: widget.series.id,
          name: widget.series.name,
        )
        .then<void>((_) {});
    if (!context.mounted) {
      return;
    }
    await showMetadataRefreshProgressDialog(context);
    try {
      await future;
    } catch (_) {
      // 错误已在进度对话框中展示。
    }
  }
}

class _SeriesDetailOverflowMenuItem extends StatelessWidget {
  const _SeriesDetailOverflowMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = enabled
        ? cs.hentai.iconDefault
        : cs.hentai.iconDefault.withValues(alpha: 0.38);
    final Color text = enabled
        ? cs.hentai.textPrimary
        : cs.hentai.textPrimary.withValues(alpha: 0.38);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        hoverColor: cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
