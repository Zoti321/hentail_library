import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/add_comics_to_series_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/series_confirm_delete_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/rename_series_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/reorder_series_items_dialog.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_back_header.dart';
import 'package:hentai_library/ui/features/metadata/view_models/series_management_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailHeader extends ConsumerWidget {
  const SeriesDetailHeader({super.key, required this.series});

  final Series series;

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
                _SeriesDetailOverflowMenuButton(series: series),
                const Spacer(),
                GhostButton.icon(
                  icon: LucideIcons.pencil,
                  tooltip: '编辑系列',
                  semanticLabel: '编辑系列',
                  iconSize: 16,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.iconDefault,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor,
                  onPressed: () => _openRenameDialog(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRenameDialog(BuildContext context, WidgetRef ref) async {
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => RenameSeriesDialog(series: series),
    );
    if (newName == null || !context.mounted) {
      return;
    }
    showSuccessToast(context, '已重命名');
    context.goNamed(
      '系列详情',
      pathParameters: <String, String>{'name': newName},
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
              _SeriesDetailOverflowMenuItem(
                icon: LucideIcons.plus,
                label: '添加漫画',
                onTap: () {
                  _controller.hideMenu();
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) => AddComicsToSeriesDialog(
                      key: ValueKey<String>(widget.series.name),
                      series: widget.series,
                    ),
                  );
                },
              ),
              _SeriesDetailOverflowMenuItem(
                icon: LucideIcons.arrowUpDown,
                label: '调整顺序',
                onTap: () {
                  _controller.hideMenu();
                  if (widget.series.items.length < 2) {
                    showInfoToast(context, '至少需要 2 本漫画才能调整顺序');
                    return;
                  }
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) =>
                        ReorderSeriesItemsDialog(series: widget.series),
                  );
                },
              ),
              _SeriesDetailOverflowMenuItem(
                icon: LucideIcons.trash2,
                label: '删除系列',
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
      builder: (BuildContext context) =>
          SeriesConfirmDeleteDialog(series: widget.series),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(seriesActionsProvider).delete(widget.series.name);
      if (!context.mounted) {
        return;
      }
      showSuccessToast(context, '已删除系列');
      ComicDetailBackHeader.popOrGoLibrary(context);
    } catch (error) {
      if (context.mounted) {
        showErrorToast(context, error);
      }
    }
  }
}

class _SeriesDetailOverflowMenuItem extends StatelessWidget {
  const _SeriesDetailOverflowMenuItem({
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
