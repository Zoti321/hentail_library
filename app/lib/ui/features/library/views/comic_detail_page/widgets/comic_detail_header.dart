import 'package:flutter/material.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/anchored_overlay_menu.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_delete_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_metadata_dialog.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_apply.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_back_header.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_series_nav.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailHeader extends ConsumerWidget {
  const ComicDetailHeader({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
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
                _ComicDetailOverflowMenuButton(comic: comic),
                const SizedBox(width: 4),
                GhostButton.icon(
                  icon: LucideIcons.pencil,
                  tooltip: l10n.comicDetailEditMetadata,
                  semanticLabel: l10n.comicDetailEditMetadata,
                  iconSize: 16,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.iconDefault,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor,
                  onPressed: () => _openEditMetadata(context, ref),
                ),
                const Spacer(),
                ComicDetailSeriesNav(comicId: comic.comicId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditMetadata(BuildContext context, WidgetRef ref) {
    showEditMetadataDialog(
      context: context,
      comic: comic,
      onSave: (ComicMetadataForm data) async {
        await applyComicMetadataForm(
          ref.read(comicRepoProvider),
          data,
          comic,
          invalidate: ref.invalidate,
        );
      },
    );
  }
}

class _ComicDetailOverflowMenuButton extends ConsumerStatefulWidget {
  const _ComicDetailOverflowMenuButton({required this.comic});

  final Comic comic;

  @override
  ConsumerState<_ComicDetailOverflowMenuButton> createState() =>
      _ComicDetailOverflowMenuButtonState();
}

class _ComicDetailOverflowMenuButtonState
    extends ConsumerState<_ComicDetailOverflowMenuButton> {
  final AnchoredOverlayMenuController _controller =
      AnchoredOverlayMenuController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    // Material-aligned overlay coords (ancestor: overlay) — avoids
    // custom_pop_up_menu misplacement when the desktop sidebar is expanded.
    // `under` keeps the panel below the trigger like other header menus.
    return AnchoredOverlayMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      position: AnchoredOverlayMenuPosition.under,
      menuBuilder: (VoidCallback hideMenu) => PopupMenuPanelShell(
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
              _ComicDetailOverflowMenuItem(
                icon: LucideIcons.refreshCw,
                label: l10n.refreshMetadata,
                enabled: !_isLibraryWriteBusy(ref),
                onTap: () {
                  hideMenu();
                  _refreshMetadata(context);
                },
              ),
              _ComicDetailOverflowMenuItem(
                icon: LucideIcons.folderOpen,
                label: l10n.comicDetailShowInExplorer,
                onTap: () {
                  hideMenu();
                  showInFileExplorer(widget.comic.path).catchError((
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
              _ComicDetailOverflowMenuItem(
                icon: LucideIcons.trash2,
                label: l10n.comicDetailDelete,
                onTap: () {
                  hideMenu();
                  _confirmDelete(context);
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

  bool _isLibraryWriteBusy(WidgetRef ref) {
    return ref.watch(scanLibraryControllerProvider).running ||
        ref.watch(metadataRefreshControllerProvider).running;
  }

  Future<void> _refreshMetadata(BuildContext context) async {
    final AppLocalizations l10n = context.l10n;
    try {
      await ref
          .read(metadataRefreshControllerProvider.notifier)
          .refreshComic(
            comicId: widget.comic.comicId,
            title: widget.comic.title,
          );
      if (!context.mounted) {
        return;
      }
      showSuccessToast(context, l10n.refreshMetadataComicSuccess);
    } catch (err) {
      if (context.mounted) {
        showErrorToast(context, err);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          ComicConfirmDeleteDialog(title: widget.comic.title),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(comicDeletionServiceProvider).deleteComics(<String>[
        widget.comic.comicId,
      ]);
      ref.read(comicCoverCacheManagerProvider.notifier).clearForComics(<String>[
        widget.comic.comicId,
      ]);
      if (!context.mounted) {
        return;
      }
      showSuccessToast(context, l10n.comicDetailDeletedToast);
      if (context.canPop()) {
        context.pop();
      } else {
        LibraryManagementActions.goCurrentLibraryBrowseFromContext(context);
      }
    } catch (err) {
      if (context.mounted) {
        showErrorToast(context, err);
      }
    }
  }
}

class _ComicDetailOverflowMenuItem extends StatelessWidget {
  const _ComicDetailOverflowMenuItem({
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
