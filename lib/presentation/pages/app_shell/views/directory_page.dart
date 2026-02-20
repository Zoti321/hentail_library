import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DirectoryPage extends ConsumerWidget {
  const DirectoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(directoryViewProvider);
    final viewState = asyncState.asData?.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _DirectoryPageHeader(
            totalCount: viewState?.dirs.length ?? 0,
            selectedCount: viewState?.selectedDirs.length ?? 0,
            isSelectionMode: viewState?.isSelectionMode ?? false,
            hasData: viewState != null,
          ),
          const SizedBox(height: 18),
          asyncState.when(
            data: (state) => _DirectoryCard(viewState: state),
            loading: () => const _LoadingCard(),
            error: (error, _) => _ErrorCard(error: error),
          ),
        ],
      ),
    );
  }
}

class _DirectoryPageHeader extends ConsumerWidget {
  const _DirectoryPageHeader({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(directoryViewProvider.notifier);

    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                '文件目录',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: theme.colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '管理本地漫画目录，支持批量选择',
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
                  _MetaChip(icon: LucideIcons.folder, label: '目录 $totalCount'),
                  if (isSelectionMode)
                    _MetaChip(
                      icon: LucideIcons.circleCheckBig,
                      label: '已选 $selectedCount',
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
            FilledButton.icon(
              onPressed: () async {
                final dir = await FilePicker.platform.getDirectoryPath();
                if (dir == null) return;
                try {
                  await ref.read(dirRepoProvider).addDir(dir);
                  if (context.mounted) {
                    showSuccessSnackBar(context, '已添加目录');
                  }
                } catch (e) {
                  if (context.mounted) showErrorSnackBar(context, e);
                }
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('添加目录'),
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
            ),
            OutlinedButton.icon(
              onPressed: hasData ? notifier.toggleSelectionMode : null,
              icon: Icon(
                isSelectionMode
                    ? LucideIcons.squareX
                    : LucideIcons.squareCheckBig,
                size: 16,
              ),
              label: Text(isSelectionMode ? '退出选择' : '选择模式'),
            ),
            if (isSelectionMode && selectedCount > 0)
              TextButton.icon(
                onPressed: notifier.clearSelection,
                icon: const Icon(LucideIcons.eraser, size: 16),
                label: const Text('清空选择'),
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
        : theme.colorScheme.surfaceContainerHighest.withAlpha(90);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
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

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.viewState});

  final DirectoryViewState viewState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dirs = viewState.dirs;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.folderOpen,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '本地目录',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '共 ${dirs.length} 项',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (dirs.isEmpty)
              const _EmptyDirectories()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dirs.length,
                separatorBuilder: (_, index) =>
                    Divider(height: 1, color: theme.colorScheme.borderSubtle),
                itemBuilder: (context, index) {
                  final dir = dirs[index];
                  return _DirectoryTile(
                    dir: dir,
                    isSelectionMode: viewState.isSelectionMode,
                    isSelected: viewState.selectedDirs.contains(dir),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryTile extends ConsumerWidget {
  const _DirectoryTile({
    required this.dir,
    required this.isSelectionMode,
    required this.isSelected,
  });

  final String dir;
  final bool isSelectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(directoryViewProvider.notifier);

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
          notifier.toggleDirSelection(dir);
        },
        onLongPress: () {
          if (isSelectionMode) return;
          notifier.setSelectionMode(true);
          notifier.toggleDirSelection(dir);
        },
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
                        LucideIcons.folder,
                        key: const ValueKey<String>('folder'),
                        size: 20,
                        color: Colors.amber[700],
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dir,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (!isSelectionMode)
                IconButton(
                  tooltip: '移除目录',
                  onPressed: () async {
                    try {
                      await ref.read(dirRepoProvider).removeDir(dir);
                      if (context.mounted) {
                        showSuccessSnackBar(context, '已移除目录');
                      }
                    } catch (e) {
                      if (context.mounted) showErrorSnackBar(context, e);
                    }
                  },
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
    );
  }
}

class _ErrorCard extends ConsumerWidget {
  const _ErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            '目录加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.warning,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(directoryViewProvider.notifier).refreshDirs();
            },
            icon: const Icon(LucideIcons.rotateCw, size: 16),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDirectories extends StatelessWidget {
  const _EmptyDirectories();

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
            const SizedBox(height: 10),
            Text(
              '暂无目录，请先添加本地文件夹',
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
