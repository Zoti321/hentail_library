import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/remove_saved_path_confirm_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/remote_library_form_dialog.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PathTile extends HookConsumerWidget {
  const PathTile({super.key, required this.library});

  final LocalLibrary library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    final ValueNotifier<bool> isRemoving = useState<bool>(false);
    final CurrentLibraryState? currentState = ref
        .watch(currentLibraryProvider)
        .asData
        ?.value;
    final bool remote = isRemoteLibrary(library);
    final bool isCurrent = library.libraryId == currentState?.currentId;

    Future<void> handleRemove() async {
      final bool confirmed =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) =>
                RemoveSavedPathConfirmDialog(path: library.rootPath),
          ) ??
          false;
      if (!context.mounted || !confirmed) {
        return;
      }
      isRemoving.value = true;
      try {
        await ref.read(libraryRepoProvider).delete(library.libraryId);
        await ref.read(currentLibraryProvider.notifier).refresh();
        ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
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

    Future<void> handleSetCurrent() async {
      if (isCurrent) {
        return;
      }
      try {
        await ref
            .read(currentLibraryProvider.notifier)
            .select(library.libraryId);
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        showErrorToast(context, error);
      }
    }

    Future<void> handleEditRemote() async {
      final RemoteLibraryFormResult? result = await showRemoteLibraryFormDialog(
        context: context,
        existing: library,
      );
      if (result == null || !context.mounted) {
        return;
      }
      try {
        final LibraryRepository repo = ref.read(libraryRepoProvider);
        await repo.updateRemote(
          libraryId: library.libraryId,
          rootUrl: result.rootUrl,
          username: result.username,
          allowHttp: result.allowHttp,
          password: result.passwordChanged ? result.password : null,
        );
        await ref.read(currentLibraryProvider.notifier).refresh();
        ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
        if (!context.mounted) {
          return;
        }
        showSuccessToast(context, l10n.remoteLibraryUpdatedToast);
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        showErrorToast(context, error);
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
                remote ? LucideIcons.cloud : _resolveLocalIcon(library.rootPath),
                size: 20,
                color: theme.colorScheme.hentai.iconDefault,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      library.rootPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remote
                          ? l10n.pathsLibraryKindRemote
                          : l10n.pathsLibraryKindLocal,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.hentai.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    LucideIcons.star,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                GhostButton.icon(
                  icon: LucideIcons.star,
                  tooltip: l10n.setCurrentLibrary,
                  semanticLabel: l10n.setCurrentLibrary,
                  iconSize: 16,
                  size: 28,
                  borderRadius: 8,
                  foregroundColor: theme.colorScheme.hentai.iconDefault,
                  hoverColor: theme.colorScheme.primary.withAlpha(10),
                  overlayColor: theme.colorScheme.primary.withAlpha(14),
                  delayTooltipThreeSeconds: true,
                  onPressed: handleSetCurrent,
                ),
              if (remote)
                GhostButton.icon(
                  icon: LucideIcons.pencil,
                  tooltip: l10n.remoteLibraryEditAction,
                  semanticLabel: l10n.remoteLibraryEditAction,
                  iconSize: 16,
                  size: 28,
                  borderRadius: 8,
                  foregroundColor: theme.colorScheme.hentai.iconDefault,
                  hoverColor: theme.colorScheme.primary.withAlpha(10),
                  overlayColor: theme.colorScheme.primary.withAlpha(14),
                  delayTooltipThreeSeconds: true,
                  onPressed: handleEditRemote,
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
                      onPressed: handleRemove,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveLocalIcon(String path) {
    final FileSystemEntityType pathType = FileSystemEntity.typeSync(path);
    if (pathType == FileSystemEntityType.file) {
      return LucideIcons.file;
    }
    return LucideIcons.folder;
  }
}
