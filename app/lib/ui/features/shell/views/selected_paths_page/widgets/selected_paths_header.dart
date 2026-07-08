import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/selected_paths_layout_constants.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/widgets/add_path_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/remove_saved_paths_batch_confirm_dialog.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedPathsPageHeader extends ConsumerStatefulWidget {
  const SelectedPathsPageHeader({
    required this.layoutTier,
    this.onOpenNavigation,
    super.key,
  });

  final SelectedPathsLayoutTier layoutTier;
  final VoidCallback? onOpenNavigation;

  @override
  ConsumerState<SelectedPathsPageHeader> createState() =>
      _SelectedPathsPageHeaderState();
}

class _SelectedPathsPageHeaderState
    extends ConsumerState<SelectedPathsPageHeader> {
  bool isBatchRemoving = false;

  Future<void> handleRemoveSelectedPaths(BuildContext context) async {
    final SelectedPathsPageState? pageState = ref
        .read(selectedPathsPageProvider)
        .asData
        ?.value;
    if (pageState == null || pageState.selectedPaths.isEmpty) {
      return;
    }
    final List<String> orderedSelected = pageState.paths
        .where((String path) => pageState.selectedPaths.contains(path))
        .toList();
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) =>
              RemoveSavedPathsBatchConfirmDialog(paths: orderedSelected),
        ) ??
        false;
    if (!context.mounted || !confirmed) {
      return;
    }
    setState(() => isBatchRemoving = true);
    try {
      await ref.read(selectedPathsPageProvider.notifier).removeSelectedPaths();
      if (!context.mounted) {
        return;
      }
      final int removedCount = orderedSelected.length;
      showSuccessToast(
        context,
        removedCount == 1 ? '已移除 1 条路径' : '已移除 $removedCount 条路径',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() => isBatchRemoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (int totalCount, int selectedCount, bool hasData) = ref.watch(
      selectedPathsPageProvider.select((
        AsyncValue<SelectedPathsPageState> async,
      ) {
        return async.maybeWhen(
          data: (SelectedPathsPageState state) =>
              (state.paths.length, state.selectedPaths.length, true),
          orElse: () => (0, 0, false),
        );
      }),
    );

    final Widget summary = _SelectedPathsHeaderSummary(
      layoutTier: widget.layoutTier,
      totalCount: totalCount,
      selectedCount: selectedCount,
      colorScheme: theme.colorScheme,
      onOpenNavigation: widget.onOpenNavigation,
    );
    final Widget actions = _SelectedPathsHeaderActions(
      layoutTier: widget.layoutTier,
      theme: theme,
      hasData: hasData,
      selectedCount: selectedCount,
      isBatchRemoving: isBatchRemoving,
      onRemoveSelected: () => handleRemoveSelectedPaths(context),
    );

    if (selectedPathsHeaderIsVertical(widget.layoutTier)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          summary,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: summary),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }
}

class _SelectedPathsHeaderSummary extends StatelessWidget {
  const _SelectedPathsHeaderSummary({
    required this.layoutTier,
    required this.totalCount,
    required this.selectedCount,
    required this.colorScheme,
    this.onOpenNavigation,
  });

  final SelectedPathsLayoutTier layoutTier;
  final int totalCount;
  final int selectedCount;
  final ColorScheme colorScheme;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (onOpenNavigation != null) ...<Widget>[
          GhostButton.icon(
            icon: LucideIcons.menu,
            semanticLabel: '打开导航菜单',
            tooltip: '',
            iconSize: 16,
            size: 32,
            borderRadius: 8,
            foregroundColor: colorScheme.hentai.iconDefault,
            hoverColor: colorScheme.primary.withAlpha(10),
            overlayColor: colorScheme.primary.withAlpha(14),
            onPressed: onOpenNavigation,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          '选中路径',
          style: buildSelectedPathsPageTitleStyle(colorScheme, layoutTier),
        ),
        if (selectedPathsShowsSubtitle(layoutTier)) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            '管理本地漫画根目录，支持批量选择',
            style: TextStyle(
              color: colorScheme.hentai.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            MetaChip(icon: LucideIcons.link, label: '路径 $totalCount'),
            if (selectedCount > 0)
              MetaChip(
                icon: LucideIcons.circleCheckBig,
                label: '已选 $selectedCount',
              ),
          ],
        ),
      ],
    );
  }
}

class _SelectedPathsHeaderActions extends StatelessWidget {
  const _SelectedPathsHeaderActions({
    required this.layoutTier,
    required this.theme,
    required this.hasData,
    required this.selectedCount,
    required this.isBatchRemoving,
    required this.onRemoveSelected,
  });

  final SelectedPathsLayoutTier layoutTier;
  final ThemeData theme;
  final bool hasData;
  final int selectedCount;
  final bool isBatchRemoving;
  final Future<void> Function() onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        const AddPathButton(),
        if (hasData && selectedCount > 0) _buildClearButton(context),
      ],
    );
  }

  Widget _buildClearButton(BuildContext context) {
    final ColorScheme colorScheme = theme.colorScheme;
    final Future<void> Function()? onPressed = isBatchRemoving
        ? null
        : () => onRemoveSelected();

    if (selectedPathsHeaderUsesIconOnlyClear(layoutTier)) {
      if (isBatchRemoving) {
        return SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
        );
      }
      return GhostButton.icon(
        icon: LucideIcons.trash2,
        tooltip: '清空选择',
        semanticLabel: '清空选择',
        onPressed: onPressed,
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: colorScheme.onSurface,
        hoverColor: colorScheme.primary.withAlpha(10),
        overlayColor: colorScheme.primary.withAlpha(14),
        delayTooltipThreeSeconds: true,
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: isBatchRemoving
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : const Icon(LucideIcons.trash2, size: 16),
      label: Text(isBatchRemoving ? '移除中…' : '清空选择'),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

TextStyle buildSelectedPathsPageTitleStyle(
  ColorScheme colorScheme,
  SelectedPathsLayoutTier layoutTier,
) {
  return TextStyle(
    fontSize: selectedPathsPageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: colorScheme.hentai.textPrimary,
  );
}
