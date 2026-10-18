import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/confirm/remove_saved_path_confirm_dialog.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/features/library_admin/presentation/views/dialogs/library_form_dialog.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';

/// Shared Library create / edit / delete / scan actions for sidebar + paths page.
abstract final class LibraryManagementActions {
  static Future<void> addLocalLibrary(WidgetRef ref, BuildContext context) {
    return showLibraryFormDialog(
      context: context,
      mode: LibraryFormMode.createLocal,
    );
  }

  static Future<void> addRemoteLibrary(WidgetRef ref, BuildContext context) {
    return showLibraryFormDialog(
      context: context,
      mode: LibraryFormMode.createRemote,
    );
  }

  static Future<void> editRemoteLibrary(
    WidgetRef ref,
    BuildContext context,
    LocalLibrary library,
  ) {
    if (!isRemoteLibrary(library)) {
      return Future<void>.value();
    }
    return showLibraryFormDialog(
      context: context,
      mode: LibraryFormMode.edit,
      library: library,
    );
  }

  static Future<void> editLibrarySettings(
    WidgetRef ref,
    BuildContext context,
    LocalLibrary library,
  ) {
    return showLibraryFormDialog(
      context: context,
      mode: LibraryFormMode.edit,
      library: library,
    );
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
        ref.read(currentLibraryStateProvider).asData?.value.currentId ==
            deletedId;

    await ref.read(currentLibraryPortProvider).deleteLibrary(deletedId);
    if (!context.mounted) {
      return;
    }
    showSuccessToast(context, context.l10n.libraryRemovedToast);

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
        .read(currentLibraryStateProvider)
        .asData
        ?.value;
    final List<LocalLibrary> remaining =
        state?.libraries ?? const <LocalLibrary>[];
    final AfterLibraryDeleteNavigation nav = afterLibraryDeleteNavigation(
      remainingLibraryIds: remaining
          .map((LocalLibrary library) => library.libraryId)
          .toList(),
    );
    final String? selectId = nav.selectLibraryId;
    if (selectId == null) {
      await ref.read(currentLibraryPortProvider).clear();
      if (!context.mounted) {
        return;
      }
      context.go(nav.goPath);
      return;
    }
    await ref.read(currentLibraryPortProvider).select(selectId);
    if (!context.mounted) {
      return;
    }
    context.go(nav.goPath);
  }

  static Future<void> openLibrary(
    WidgetRef ref,
    BuildContext context,
    String libraryId,
  ) async {
    ref.read(comicDetailReturnSeriesPortProvider).clear();
    await ref.read(currentLibraryPortProvider).select(libraryId);
    if (!context.mounted) {
      return;
    }
    context.go(LibrariesRoutes.library(libraryId));
  }

  /// Best-effort clear of the return-series memory when [context] may sit outside a [ProviderScope].
  static void _clearComicDetailReturnSeriesFromContext(BuildContext context) {
    try {
      ProviderScope.containerOf(
        context,
      ).read(comicDetailReturnSeriesPortProvider).clear();
    } catch (_) {}
  }

  static void goAllLibraries(BuildContext context) {
    _clearComicDetailReturnSeriesFromContext(context);
    context.go(LibrariesRoutes.all);
  }

  static void goCurrentLibraryBrowse(WidgetRef ref, BuildContext context) {
    ref.read(comicDetailReturnSeriesPortProvider).clear();
    final String? currentId = ref
        .read(currentLibraryStateProvider)
        .asData
        ?.value
        .currentId;
    context.go(LibrariesRoutes.browsePathForCurrent(currentId));
  }

  /// For call sites without [WidgetRef] (e.g. plain StatelessWidget).
  static void goCurrentLibraryBrowseFromContext(BuildContext context) {
    try {
      final ProviderContainer container = ProviderScope.containerOf(context);
      container.read(comicDetailReturnSeriesPortProvider).clear();
      final String? currentId = container
          .read(currentLibraryStateProvider)
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
    bool navigate = false,
  }) async {
    await ref.read(currentLibraryPortProvider).select(libraryId);
    if (!context.mounted) {
      return;
    }
    if (navigate) {
      context.go(LibrariesRoutes.library(libraryId));
    }
    await ref
        .read(libraryScanCommandPortProvider)
        .start(mode: mode, silent: true);
  }

  static Future<void> scanAllLibraries(
    WidgetRef ref, {
    ScanMode mode = ScanMode.incremental,
  }) async {
    await ref
        .read(libraryScanCommandPortProvider)
        .start(mode: mode, syncAll: true, silent: true);
  }
}
