import 'dart:io' show Platform;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/repository/dir_repo.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/confirm/remove_saved_paths_batch_confirm_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

TextStyle buildSelectedPathsPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: colorScheme.textPrimary,
  );
}

class SelectedPathsPageHeader extends ConsumerStatefulWidget {
  const SelectedPathsPageHeader({super.key});

  @override
  ConsumerState<SelectedPathsPageHeader> createState() =>
      _SelectedPathsPageHeaderState();
}

class _SelectedPathsPageHeaderState extends ConsumerState<SelectedPathsPageHeader> {
  final CustomPopupMenuController addPathMenuController =
      CustomPopupMenuController();
  bool isPicking = false;
  bool isBatchRemoving = false;

  Future<void> executePickingTask(Future<void> Function() task) async {
    setState(() => isPicking = true);
    try {
      await task();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() => isPicking = false);
      }
    }
  }

  Future<void> savePickedPaths(List<String> paths) async {
    final PathRepository pathRepository = ref.read(pathRepoProvider);
    int addedCount = 0;
    for (final String path in paths) {
      if (path.isEmpty) {
        continue;
      }
      await pathRepository.add(path);
      addedCount++;
    }
    if (!mounted || addedCount == 0) {
      return;
    }
    showSuccessToast(
      context,
      addedCount == 1 ? '已添加 1 个路径' : '已添加 $addedCount 个路径',
    );
  }

  Future<void> addFiles() async {
    await executePickingTask(() async {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        allowCompression: false,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final List<String> paths = result.files
          .map((PlatformFile file) => file.path)
          .whereType<String>()
          .toList();
      await savePickedPaths(paths);
    });
  }

  Future<void> addFolder() async {
    await executePickingTask(() async {
      final String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) {
        return;
      }
      await savePickedPaths(<String>[directoryPath]);
    });
  }

  Future<void> pickMixedMac() async {
    if (!Platform.isMacOS) {
      return;
    }
    await executePickingTask(() async {
      final List<String>? paths = await FilePicker.platform
          .pickFileAndDirectoryPaths(type: FileType.any);
      if (paths == null || paths.isEmpty) {
        return;
      }
      await savePickedPaths(paths);
    });
  }

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
          addPathMenuController: addPathMenuController,
          isPicking: isPicking,
          hasData: hasData,
          selectedCount: selectedCount,
          isBatchRemoving: isBatchRemoving,
          onPickMixed: pickMixedMac,
          onAddFiles: addFiles,
          onAddFolder: addFolder,
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
                highlighted: true,
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
    required this.addPathMenuController,
    required this.isPicking,
    required this.hasData,
    required this.selectedCount,
    required this.isBatchRemoving,
    required this.onPickMixed,
    required this.onAddFiles,
    required this.onAddFolder,
    required this.onRemoveSelected,
  });

  final ThemeData theme;
  final CustomPopupMenuController addPathMenuController;
  final bool isPicking;
  final bool hasData;
  final int selectedCount;
  final bool isBatchRemoving;
  final VoidCallback onPickMixed;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;
  final Future<void> Function() onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        CustomPopupMenu(
          controller: addPathMenuController,
          barrierColor: Colors.transparent,
          pressType: PressType.singleClick,
          showArrow: false,
          verticalMargin: -26,
          menuBuilder: () => _AddPathMenuPanel(
            isPicking: isPicking,
            onPickMixed: () {
              addPathMenuController.hideMenu();
              onPickMixed();
            },
            onAddFiles: () {
              addPathMenuController.hideMenu();
              onAddFiles();
            },
            onAddFolder: () {
              addPathMenuController.hideMenu();
              onAddFolder();
            },
          ),
          child: FilledButton.icon(
            onPressed: isPicking ? null : () => addPathMenuController.toggleMenu(),
            icon: isPicking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.plus, size: 16),
            label: Text(isPicking ? '处理中…' : '添加路径'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
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

class _AddPathMenuPanel extends StatelessWidget {
  const _AddPathMenuPanel({
    required this.isPicking,
    required this.onPickMixed,
    required this.onAddFiles,
    required this.onAddFolder,
  });

  final bool isPicking;
  final VoidCallback onPickMixed;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      width: 260,
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: colorScheme.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (Platform.isMacOS) ...<Widget>[
              _AddPathMenuItem(
                icon: LucideIcons.layers,
                title: '混合选择…',
                subtitle: '文件与文件夹',
                enabled: !isPicking,
                onPressed: onPickMixed,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
                child: Divider(height: 1, color: colorScheme.borderSubtle),
              ),
            ],
            _AddPathMenuItem(
              icon: LucideIcons.fileStack,
              title: '添加文件',
              subtitle: '可多选',
              enabled: !isPicking,
              onPressed: onAddFiles,
            ),
            _AddPathMenuItem(
              icon: LucideIcons.folderOpen,
              title: '添加文件夹',
              subtitle: '选择目录',
              enabled: !isPicking,
              onPressed: onAddFolder,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPathMenuItem extends StatelessWidget {
  const _AddPathMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        hoverColor: colorScheme.primary.withAlpha(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: enabled ? colorScheme.primary : colorScheme.textTertiary,
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? colorScheme.textPrimary
                            : colorScheme.textDisabled,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: tokens.text.labelXs,
                        color: colorScheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color iconColor = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final Color backgroundColor = highlighted
        ? theme.colorScheme.primaryContainer.withAlpha(130)
        : theme.colorScheme.surfaceContainerHighest;
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
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
