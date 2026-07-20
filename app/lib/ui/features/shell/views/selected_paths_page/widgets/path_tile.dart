import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/remove_saved_path_confirm_dialog.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PathTile extends HookConsumerWidget {
  const PathTile({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    final ValueNotifier<bool> isRemoving = useState<bool>(false);
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
        showSuccessToast(context, l10n.pathsRemovedToast);
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

    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: theme.colorScheme.primary.withAlpha(10),
      ),
      child: Material(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(
                _resolvePathTypeIcon(path),
                size: 20,
                color: theme.colorScheme.hentai.iconDefault,
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
                    color: theme.colorScheme.onSurface,
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
                      tooltip: l10n.pathsRemoveAction,
                      semanticLabel: l10n.pathsRemoveAction,
                      iconSize: 16,
                      size: 28,
                      borderRadius: 8,
                      foregroundColor: theme.colorScheme.hentai.iconDefault,
                      hoverColor: theme.colorScheme.primary.withAlpha(10),
                      overlayColor: theme.colorScheme.primary.withAlpha(14),
                      delayTooltipThreeSeconds: true,
                      onPressed: handleRemovePath,
                    ),
            ],
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
