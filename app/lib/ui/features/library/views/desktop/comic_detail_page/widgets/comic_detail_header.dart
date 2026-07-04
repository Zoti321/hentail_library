import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_metadata_dialog.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_back_header.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_series_nav.dart';
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
                  tooltip: '返回',
                  semanticLabel: '返回',
                  iconSize: 16,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.iconDefault,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor,
                  onPressed: () => ComicDetailBackHeader.popOrGoLibrary(context),
                ),
                const SizedBox(width: 4),
                _ComicDetailOverflowMenuButton(comic: comic),
                const SizedBox(width: 4),
                GhostButton.icon(
                  icon: LucideIcons.pencil,
                  tooltip: '编辑元数据',
                  semanticLabel: '编辑元数据',
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
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => EditMetadataDialog(
        comic: comic,
        onSave: (ComicMetadataForm data) async {
          await data.applyTo(ref.read(comicRepoProvider), comic.comicId);
        },
      ),
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
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return CustomPopupMenu(
      controller: _controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -24,
      menuBuilder: () => PopupMenuPanelShell(
        width: 200,
        blurRadius: 6,
        shadowOffset: const Offset(0, 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ComicDetailOverflowMenuItem(
                icon: LucideIcons.folderOpen,
                label: '在资源管理器中显示',
                onTap: () {
                  _controller.hideMenu();
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
                        '无法在文件资源管理器中显示该项目',
                        cause: error,
                        stackTrace: stackTrace,
                      ),
                    );
                  });
                },
              ),
              _ComicDetailOverflowMenuItem(
                icon: LucideIcons.trash2,
                label: '删除',
                onTap: () {
                  _controller.hideMenu();
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: '更多操作',
        semanticLabel: '打开更多操作',
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

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除漫画？'),
        content: Text('将删除「${widget.comic.title}」。此操作不可撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(deleteComicsUseCaseProvider).call(<String>[
        widget.comic.comicId,
      ]);
      if (!context.mounted) {
        return;
      }
      showSuccessToast(context, '已删除漫画');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/local');
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: cs.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: cs.hentai.iconDefault),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.hentai.textPrimary,
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
