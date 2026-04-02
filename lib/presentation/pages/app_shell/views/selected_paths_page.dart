import 'dart:io' show FileSystemEntity, FileSystemEntityType, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/common/status/status_card_shell.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedPathsPage extends ConsumerWidget {
  const SelectedPathsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(selectedPathsPageProvider);
    final viewState = asyncState.asData?.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectedPathsPageHeader(
            totalCount: viewState?.paths.length ?? 0,
            selectedCount: viewState?.selectedPaths.length ?? 0,
            isSelectionMode: viewState?.isSelectionMode ?? false,
            hasData: viewState != null,
          ),
          const SizedBox(height: 20),
          asyncState.when(
            data: (state) => _SelectedPathsCard(viewState: state),
            loading: () => const _LoadingCard(),
            error: (error, _) => _ErrorCard(error: error),
          ),
        ],
      ),
    );
  }
}

class _SelectedPathsPageHeader extends ConsumerStatefulWidget {
  const _SelectedPathsPageHeader({
    required this.totalCount,
    required this.selectedCount,
    required this.isSelectionMode,
    required this.hasData,
  });

  final int totalCount;
  final int selectedCount;
  final bool isSelectionMode;
  final bool hasData;

  @override
  ConsumerState<_SelectedPathsPageHeader> createState() =>
      _SelectedPathsPageHeaderState();
}

class _SelectedPathsPageHeaderState extends ConsumerState<_SelectedPathsPageHeader> {
  final MenuController _menuController = MenuController();
  bool _isPicking = false;

  Future<void> _addFiles() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        allowCompression: false,
      );
      if (result == null || result.files.isEmpty) return;
      final pathRepo = ref.read(pathRepoProvider);
      var added = 0;
      for (final f in result.files) {
        final p = f.path;
        if (p == null) continue;
        await pathRepo.add(p);
        added++;
      }
      if (mounted && added > 0) {
        showSuccessSnackBar(context, added == 1 ? '已添加 1 个路径' : '已添加 $added 个路径');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _addFolder() async {
    setState(() => _isPicking = true);
    try {
      final dir = await FilePicker.platform.getDirectoryPath();
      if (dir == null) return;
      await ref.read(pathRepoProvider).add(dir);
      if (mounted) showSuccessSnackBar(context, '已添加路径');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickMixedMac() async {
    if (!Platform.isMacOS) return;
    setState(() => _isPicking = true);
    try {
      final paths = await FilePicker.platform.pickFileAndDirectoryPaths(
        type: FileType.any,
      );
      if (paths == null || paths.isEmpty) return;
      final pathRepo = ref.read(pathRepoProvider);
      for (final p in paths) {
        await pathRepo.add(p);
      }
      if (mounted) {
        showSuccessSnackBar(
          context,
          paths.length == 1 ? '已添加 1 个路径' : '已添加 ${paths.length} 个路径',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(selectedPathsPageProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选中路径',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: theme.colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '管理本地漫画根路径（文件或文件夹），支持批量选择',
                style: TextStyle(
                  color: theme.colorScheme.textTertiary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: LucideIcons.link,
                    label: '路径 ${widget.totalCount}',
                  ),
                  if (widget.isSelectionMode)
                    _MetaChip(
                      icon: LucideIcons.circleCheckBig,
                      label: '已选 ${widget.selectedCount}',
                      highlighted: true,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MenuAnchor(
              controller: _menuController,
              menuChildren: [
                if (Platform.isMacOS)
                  MenuItemButton(
                    onPressed: _isPicking
                        ? null
                        : () {
                            _menuController.close();
                            _pickMixedMac();
                          },
                    child: const Text('混合选择…'),
                  ),
                MenuItemButton(
                  onPressed: _isPicking
                      ? null
                      : () {
                          _menuController.close();
                          _addFiles();
                        },
                  child: const Text('添加文件'),
                ),
                MenuItemButton(
                  onPressed: _isPicking
                      ? null
                      : () {
                          _menuController.close();
                          _addFolder();
                        },
                  child: const Text('添加文件夹'),
                ),
              ],
              builder: (context, controller, child) {
                return FilledButton.icon(
                  onPressed: _isPicking
                      ? null
                      : () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                  icon: _isPicking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.plus, size: 16),
                  label: Text(_isPicking ? '处理中…' : '添加路径'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            OutlinedButton.icon(
              onPressed: widget.hasData ? notifier.toggleSelectionMode : null,
              icon: Icon(
                widget.isSelectionMode
                    ? LucideIcons.squareX
                    : LucideIcons.squareCheckBig,
                size: 16,
              ),
              label: Text(widget.isSelectionMode ? '退出选择' : '选择模式'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.borderSubtle),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (widget.isSelectionMode && widget.selectedCount > 0)
              TextButton.icon(
                onPressed: notifier.clearSelection,
                icon: const Icon(LucideIcons.eraser, size: 16),
                label: const Text('清空选择'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ],
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
    final theme = Theme.of(context);
    final iconColor = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final bgColor = highlighted
        ? theme.colorScheme.primaryContainer.withAlpha(130)
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

class _SelectedPathsCard extends StatelessWidget {
  const _SelectedPathsCard({required this.viewState});

  final SelectedPathsPageState viewState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paths = viewState.paths;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.folderTree,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已保存路径',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '共 ${paths.length} 项',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (paths.isEmpty)
              const _EmptyPaths()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paths.length,
                separatorBuilder: (_, index) =>
                    Divider(height: 1, color: theme.colorScheme.borderSubtle),
                itemBuilder: (context, index) {
                  final path = paths[index];
                  return _PathTile(
                    path: path,
                    isSelectionMode: viewState.isSelectionMode,
                    isSelected: viewState.selectedPaths.contains(path),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

IconData _pathRowIcon(String path) {
  final t = FileSystemEntity.typeSync(path);
  if (t == FileSystemEntityType.file) {
    return LucideIcons.file;
  }
  return LucideIcons.folder;
}

class _PathTile extends ConsumerStatefulWidget {
  const _PathTile({
    required this.path,
    required this.isSelectionMode,
    required this.isSelected,
  });

  final String path;
  final bool isSelectionMode;
  final bool isSelected;

  @override
  ConsumerState<_PathTile> createState() => _PathTileState();
}

class _PathTileState extends ConsumerState<_PathTile> {
  bool _isRemoving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(selectedPathsPageProvider.notifier);
    final path = widget.path;
    final isSelectionMode = widget.isSelectionMode;
    final isSelected = widget.isSelected;

    final textColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    final bgColor = isSelected
        ? theme.colorScheme.primaryContainer.withAlpha(90)
        : theme.colorScheme.surface;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          if (!isSelectionMode) return;
          notifier.togglePathSelection(path);
        },
        onLongPress: () {
          if (isSelectionMode) return;
          notifier.setSelectionMode(true);
          notifier.togglePathSelection(path);
        },
        splashColor: theme.colorScheme.buttonRipple,
        highlightColor: theme.colorScheme.buttonPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: isSelectionMode
                    ? Icon(
                        isSelected
                            ? LucideIcons.circleCheckBig
                            : LucideIcons.circle,
                        key: ValueKey<bool>(isSelected),
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      )
                    : Icon(
                        _pathRowIcon(path),
                        key: ValueKey<String>(path),
                        size: 20,
                        color: theme.colorScheme.iconDefault,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (!widget.isSelectionMode)
                IconButton(
                  tooltip: '移除路径',
                  onPressed: _isRemoving
                      ? null
                      : () async {
                          setState(() => _isRemoving = true);
                          try {
                            await ref.read(pathRepoProvider).remove(path);
                            if (!context.mounted) return;
                            showSuccessSnackBar(context, '已移除路径');
                          } catch (e) {
                            if (!context.mounted) return;
                            showErrorSnackBar(context, e);
                          } finally {
                            if (mounted) setState(() => _isRemoving = false);
                          }
                        },
                  icon: _isRemoving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: theme.colorScheme.iconDefault,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: const EdgeInsets.symmetric(vertical: 42),
      borderRadius: 14,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ErrorCard extends ConsumerStatefulWidget {
  const _ErrorCard({required this.error});

  final Object error;

  @override
  ConsumerState<_ErrorCard> createState() => _ErrorCardState();
}

class _ErrorCardState extends ConsumerState<_ErrorCard> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: const EdgeInsets.all(20),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '路径加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.warning,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.error.toString(),
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isRetrying
                ? null
                : () async {
                    setState(() => _isRetrying = true);
                    try {
                      await ref
                          .read(selectedPathsPageProvider.notifier)
                          .refreshPaths();
                    } finally {
                      if (mounted) setState(() => _isRetrying = false);
                    }
                  },
            icon: _isRetrying
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(LucideIcons.rotateCw, size: 16),
            label: Text(_isRetrying ? '重试中…' : '重试'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPaths extends StatelessWidget {
  const _EmptyPaths();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
        child: Column(
          children: [
            Icon(
              LucideIcons.folderSearch2,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '暂无路径，请添加文件或文件夹',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
