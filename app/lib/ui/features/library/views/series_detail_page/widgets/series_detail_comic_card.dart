import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/series_item_context_menu.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_metadata_dialog.dart';
import 'package:hentai_library/ui/features/library/comic_delete_flow.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_apply.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailComicCard extends HookConsumerWidget {
  const SeriesDetailComicCard({
    super.key,
    required this.seriesId,
    required this.item,
    required this.onTap,
    this.gridIndex,
    this.reorderMode = false,
  });

  final String seriesId;
  final SeriesComicPageItem item;
  final VoidCallback onTap;
  final int? gridIndex;

  /// Series reorder mode：角标、禁点进详情/菜单/悬停编辑；拖拽由外层 ReorderableBuilder 处理。
  final bool reorderMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Comic comic = item.comic;
    final bool compact = AppLayoutBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;

    Widget card = CatalogCoverCardShell(
      onTap: reorderMode ? null : onTap,
      onSecondaryTapUp: reorderMode
          ? null
          : (TapUpDetails details) {
              _showContextMenu(context, ref, details.globalPosition);
            },
      cover: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _SeriesDetailComicCover(
            comicId: comic.comicId,
            gridIndex: gridIndex,
            showEditOnHover: !reorderMode && !compact,
            onEdit: () => _openEditMetadata(context, ref),
          ),
          if (reorderMode)
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing.xs),
                child: _ReorderBadge(
                  semanticLabel: l10n.seriesDetailReorderBadgeSemantic,
                ),
              ),
            ),
        ],
      ),
      info: (bool isHover) => _SeriesDetailComicCardInfo(
        title: comic.title,
        pageCount: comic.pageCount,
        isHover: isHover && !reorderMode,
      ),
    );

    if (reorderMode) {
      card = MouseRegion(cursor: SystemMouseCursors.grab, child: card);
    }
    return card;
  }

  void _openEditMetadata(BuildContext context, WidgetRef ref) {
    final Comic comic = item.comic;
    showEditMetadataDialog(
      context: context,
      comic: comic,
      seriesItemSort: (
        seriesId: seriesId,
        sortOrder: item.sortOrder,
        sortOrderLocked: item.sortOrderLocked,
      ),
      onSave: (ComicMetadataForm data) async {
        await applyComicMetadataForm(
          ref.read(comicRepoProvider),
          data,
          comic,
          invalidate: ref.invalidate,
          notifyExternalChange: () =>
              ref.read(libraryRevisionProvider.notifier).notifyExternalChange(),
        );
      },
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
  ) {
    SeriesItemContextMenu.show(
      context,
      position: globalPosition,
      comicTitle: item.comic.title,
      onAction: (SeriesItemContextAction action) {
        _handleContextAction(context, ref, action);
      },
    );
  }

  void _handleContextAction(
    BuildContext context,
    WidgetRef ref,
    SeriesItemContextAction action,
  ) {
    final l10n = context.l10n;
    switch (action) {
      case SeriesItemContextAction.editMetadata:
        _openEditMetadata(context, ref);
      case SeriesItemContextAction.showInExplorer:
        showInFileExplorer(item.comic.path).catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint(
            'showInFileExplorer failed for "${item.comic.path}": $error',
          );
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
      case SeriesItemContextAction.delete:
        confirmAndDeleteComic(context, ref, item.comic);
    }
  }
}

class _SeriesDetailComicCover extends HookWidget {
  const _SeriesDetailComicCover({
    required this.comicId,
    required this.gridIndex,
    required this.showEditOnHover,
    required this.onEdit,
  });

  final String comicId;
  final int? gridIndex;
  final bool showEditOnHover;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isHover = useState(false);

    return MouseRegion(
      onEnter: showEditOnHover ? (_) => isHover.value = true : null,
      onExit: showEditOnHover ? (_) => isHover.value = false : null,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ComicCoverContent(comicId: comicId, gridIndex: gridIndex),
          if (showEditOnHover && isHover.value)
            _CoverEditButton(onPressed: onEdit),
        ],
      ),
    );
  }
}

class _CoverEditButton extends StatelessWidget {
  const _CoverEditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.xs),
        child: Material(
          color: cs.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(tokens.radius.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radius.sm),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.xs),
              child: Icon(
                LucideIcons.pencil,
                size: 14,
                color: cs.hentai.iconDefault,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesDetailComicCardInfo extends StatelessWidget {
  const _SeriesDetailComicCardInfo({
    required this.title,
    required this.pageCount,
    required this.isHover,
  });

  final String title;
  final int pageCount;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: tokens.text.bodyMd,
            fontWeight: FontWeight.w600,
            fontFamily: 'MI_Sans_Regular',
            height: 1.25,
            color: isHover ? cs.primary : cs.hentai.textPrimary,
          ),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text(
          l10n.comicDetailPageCount(pageCount),
          style: TextStyle(
            fontSize: tokens.text.labelXs - 1,
            color: cs.hentai.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// 左上角拖拽模式角标：primaryContainer 背景 + gripVertical（#121）。
class _ReorderBadge extends StatelessWidget {
  const _ReorderBadge({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: EdgeInsets.all(tokens.spacing.xs),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(tokens.radius.sm),
        ),
        child: Icon(
          LucideIcons.gripVertical,
          size: 14,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
