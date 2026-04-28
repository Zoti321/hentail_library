import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/selected_paths_page/widgets/add_path_popover_btn.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/confirm/remove_saved_paths_batch_confirm_dialog.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedPathsPageHeader extends ConsumerStatefulWidget {
  const SelectedPathsPageHeader({super.key});

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _SelectedPathsHeaderSummary(
            totalCount: totalCount,
            selectedCount: selectedCount,
            colorScheme: theme.colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        _SelectedPathsHeaderActions(
          theme: theme,
          hasData: hasData,
          selectedCount: selectedCount,
          isBatchRemoving: isBatchRemoving,
          onRemoveSelected: () => handleRemoveSelectedPaths(context),
        ),
      ],
    );
  }
}

class _SelectedPathsHeaderSummary extends StatelessWidget {
  const _SelectedPathsHeaderSummary({
    required this.totalCount,
    required this.selectedCount,
    required this.colorScheme,
  });

  final int totalCount;
  final int selectedCount;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('选中路径', style: buildSelectedPathsPageTitleStyle(colorScheme)),
        const SizedBox(height: 8),
        Text(
          '管理本地漫画根路径（文件或文件夹），支持批量选择',
          style: TextStyle(color: colorScheme.textTertiary, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _MetaChip(icon: LucideIcons.link, label: '路径 $totalCount'),
            if (selectedCount > 0)
              _MetaChip(
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
    required this.theme,
    required this.hasData,
    required this.selectedCount,
    required this.isBatchRemoving,
    required this.onRemoveSelected,
  });

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
        const AddPathPopoverButton(),
        if (hasData && selectedCount > 0)
          TextButton.icon(
            onPressed: isBatchRemoving ? null : () => onRemoveSelected(),
            icon: isBatchRemoving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(LucideIcons.trash2, size: 16),
            label: Text(isBatchRemoving ? '移除中…' : '清空选择'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color iconColor = theme.colorScheme.onSurfaceVariant;
    final Color backgroundColor = theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle buildSelectedPathsPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: colorScheme.textPrimary,
  );
}
