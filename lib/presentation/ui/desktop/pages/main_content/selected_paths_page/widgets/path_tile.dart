import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/confirm/remove_saved_path_confirm_dialog.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PathTile extends HookConsumerWidget {
  const PathTile({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ValueNotifier<bool> isRemoving = useState<bool>(false);
    final SelectedPathsPageNotifier notifier = ref.read(
      selectedPathsPageProvider.notifier,
    );
    final String path = this.path;
    final bool isSelected = ref.watch(
      selectedPathsPageProvider.select(
        (AsyncValue<SelectedPathsPageState> async) =>
            async.asData?.value.selectedPaths.contains(path) ?? false,
      ),
    );
    Future<void> handleRemovePath() async {
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
      isRemoving.value = true;
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
        if (context.mounted) {
          isRemoving.value = false;
        }
      }
    }

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
          onTap: isRemoving.value
              ? null
              : () => notifier.togglePathSelection(path),
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
                isRemoving.value
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

  IconData _resolvePathTypeIcon(String path) {
    final FileSystemEntityType pathType = FileSystemEntity.typeSync(path);
    if (pathType == FileSystemEntityType.file) {
      return LucideIcons.file;
    }
    return LucideIcons.folder;
  }
}
