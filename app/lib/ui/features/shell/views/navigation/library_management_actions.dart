import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/remove_saved_path_confirm_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/remote_library_form_dialog.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';
import 'package:hentai_library/ui/providers.dart';

/// Shared Library create / edit / delete / scan actions for sidebar + paths page.
abstract final class LibraryManagementActions {
  static Future<void> addLocalLibrary(WidgetRef ref, BuildContext context) async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null || directoryPath.isEmpty) {
      return;
    }
    final PathRepository pathRepository = ref.read(pathRepoProvider);
    await pathRepository.add(directoryPath);
    await ref.read(currentLibraryProvider.notifier).refresh();
    if (!context.mounted) {
      return;
    }
    showSuccessToast(context, context.l10n.pathsAddedOneToast);
  }

  static Future<void> addRemoteLibrary(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final RemoteLibraryFormResult? result = await showRemoteLibraryFormDialog(
      context: context,
    );
    if (result == null || !context.mounted) {
      return;
    }
    await ref.read(libraryRepoProvider).createRemote(
      rootUrl: result.rootUrl,
      username: result.username,
      password: result.password,
      allowHttp: result.allowHttp,
    );
    await ref.read(currentLibraryProvider.notifier).refresh();
    ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    if (!context.mounted) {
      return;
    }
    showSuccessToast(context, context.l10n.remoteLibraryAddedToast);
  }

  static Future<void> editRemoteLibrary(
    WidgetRef ref,
    BuildContext context,
    LocalLibrary library,
  ) async {
    if (!isRemoteLibrary(library)) {
      return;
    }
    final RemoteLibraryFormResult? result = await showRemoteLibraryFormDialog(
      context: context,
      existing: library,
    );
    if (result == null || !context.mounted) {
      return;
    }
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
    showSuccessToast(context, context.l10n.remoteLibraryUpdatedToast);
  }

  static Future<void> deleteLibrary(
    WidgetRef ref,
    BuildContext context,
    LocalLibrary library, {
    bool navigateAfter = true,
  }) async {
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
    final String deletedId = library.libraryId;
    final String path = GoRouterState.of(context).uri.path;
    final bool wasViewing =
        LibrariesRoutes.libraryIdFromPath(path) == deletedId ||
        ref.read(currentLibraryProvider).asData?.value.currentId == deletedId;

    await ref.read(libraryRepoProvider).delete(deletedId);
    await ref.read(currentLibraryProvider.notifier).refresh();
    ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    if (!context.mounted) {
      return;
    }
    showSuccessToast(context, context.l10n.pathsRemovedToast);

    if (!navigateAfter || !wasViewing) {
      return;
    }
    await navigateAfterLibraryDeleted(ref, context);
  }

  static Future<void> navigateAfterLibraryDeleted(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final CurrentLibraryState? state = ref
        .read(currentLibraryProvider)
        .asData
        ?.value;
    final List<LocalLibrary> remaining = state?.libraries ?? const <LocalLibrary>[];
    if (remaining.isEmpty) {
      await ref.read(currentLibraryProvider.notifier).clear();
      if (!context.mounted) {
        return;
      }
      context.go(LibrariesRoutes.all);
      return;
    }
    final String nextId = remaining.first.libraryId;
    await ref.read(currentLibraryProvider.notifier).select(nextId);
    if (!context.mounted) {
      return;
    }
    context.go(LibrariesRoutes.library(nextId));
  }

  static Future<void> openLibrary(
    WidgetRef ref,
    BuildContext context,
    String libraryId,
  ) async {
    await ref.read(currentLibraryProvider.notifier).select(libraryId);
    if (!context.mounted) {
      return;
    }
    context.go(LibrariesRoutes.library(libraryId));
  }

  static void goAllLibraries(BuildContext context) {
    context.go(LibrariesRoutes.all);
  }

  static void goCurrentLibraryBrowse(WidgetRef ref, BuildContext context) {
    final String? currentId = ref
        .read(currentLibraryProvider)
        .asData
        ?.value
        .currentId;
    context.go(LibrariesRoutes.browsePathForCurrent(currentId));
  }

  /// For call sites without [WidgetRef] (e.g. plain StatelessWidget).
  static void goCurrentLibraryBrowseFromContext(BuildContext context) {
    try {
      final ProviderContainer container = ProviderScope.containerOf(context);
      final String? currentId = container
          .read(currentLibraryProvider)
          .asData
          ?.value
          .currentId;
      context.go(LibrariesRoutes.browsePathForCurrent(currentId));
    } catch (_) {
      context.go(LibrariesRoutes.all);
    }
  }

  static Future<void> scanLibrary(
    WidgetRef ref,
    BuildContext context,
    String libraryId, {
    ScanMode mode = ScanMode.incremental,
  }) async {
    await ref.read(currentLibraryProvider.notifier).select(libraryId);
    if (!context.mounted) {
      return;
    }
    context.go(LibrariesRoutes.library(libraryId));
    await ref
        .read(scanLibraryControllerProvider.notifier)
        .start(mode: mode, silent: true);
  }

  static Future<void> scanAllLibraries(
    WidgetRef ref, {
    ScanMode mode = ScanMode.incremental,
  }) async {
    await ref
        .read(scanLibraryControllerProvider.notifier)
        .start(mode: mode, syncAll: true, silent: true);
  }
}
