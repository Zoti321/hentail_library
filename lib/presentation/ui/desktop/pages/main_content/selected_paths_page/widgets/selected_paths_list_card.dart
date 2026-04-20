import 'dart:io' show FileSystemEntity, FileSystemEntityType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/confirm/remove_saved_path_confirm_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedPathsListCard extends ConsumerWidget {
  const SelectedPathsListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<String> paths = ref.watch(
      selectedPathsPageProvider.select(
        (AsyncValue<SelectedPathsPageState> async) =>
            async.asData?.value.paths ?? const <String>[],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.borderSubtle),
        boxShadow: <BoxShadow>[
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
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.borderSubtle),
                ),
              ),
              child: Row(
                children: <Widget>[
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
                separatorBuilder: (_, int index) =>
                    Divider(height: 1, color: theme.colorScheme.borderSubtle),
                itemBuilder: (BuildContext context, int index) {
                  final String path = paths[index];
                  return _PathTile(path: path);
                },
              ),
          ],
        ),
      ),
    );
  }
}

IconData _resolvePathTypeIcon(String path) {
  final FileSystemEntityType pathType = FileSystemEntity.typeSync(path);
  if (pathType == FileSystemEntityType.file) {
    return LucideIcons.file;
  }
  return LucideIcons.folder;
}

class _PathTile extends ConsumerStatefulWidget {
  const _PathTile({required this.path});

  final String path;

  @override
  ConsumerState<_PathTile> createState() => _PathTileState();
}

class _PathTileState extends ConsumerState<_PathTile> {
  bool isRemoving = false;

  Future<void> handleRemovePath() async {
    final String path = widget.path;
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) =>
              RemoveSavedPathConfirmDialog(path: path),
        ) ??
        false;
    if (!context.mounted || !confirmed) {
      return;
    }
    setState(() => isRemoving = true);
    try {
      await ref.read(pathRepoProvider).remove(path);
      if (!context.mounted) {
        return;
      }
      showSuccessToast(context, '已移除路径');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() => isRemoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SelectedPathsPageNotifier notifier = ref.read(
      selectedPathsPageProvider.notifier,
    );
    final String path = widget.path;
    final bool isSelected = ref.watch(
      selectedPathsPageProvider.select(
        (AsyncValue<SelectedPathsPageState> async) =>
            async.asData?.value.selectedPaths.contains(path) ?? false,
      ),
    );
    final Color textColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    final Color backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withAlpha(90)
        : theme.colorScheme.surface;
    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: theme.colorScheme.primary.withAlpha(10),
      ),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: isRemoving ? null : () => notifier.togglePathSelection(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Icon(
                  isSelected ? LucideIcons.squareCheckBig : LucideIcons.square,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.textTertiary,
                ),
                const SizedBox(width: 16),
                Icon(
                  _resolvePathTypeIcon(path),
                  size: 20,
                  color: theme.colorScheme.iconDefault,
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
                isRemoving
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : GhostButton.icon(
                        icon: LucideIcons.trash2,
                        tooltip: '移除路径',
                        semanticLabel: '移除路径',
                        iconSize: 16,
                        size: 28,
                        borderRadius: 8,
                        foregroundColor: theme.colorScheme.iconDefault,
                        hoverColor: theme.colorScheme.primary.withAlpha(10),
                        overlayColor: theme.colorScheme.primary.withAlpha(14),
                        delayTooltipThreeSeconds: true,
                        onPressed: handleRemovePath,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPaths extends StatelessWidget {
  const _EmptyPaths();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
        child: Column(
          children: <Widget>[
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
