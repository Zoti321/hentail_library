import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library_md3e/library_md3e_confirm_dialog.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library_md3e/library_md3e_form_dialog.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';

/// library_admin 对 [LibraryManagementPort] 的实现（#292）。
///
/// 由 bootstrap 通过 [libraryManagementPortProvider] 的 `overrideWith` 注入。
class _LibraryManagementAdapter implements LibraryManagementPort {
  _LibraryManagementAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> addLocalLibrary(BuildContext context) =>
      showLibraryMd3eFormDialog(
        context: context,
        mode: LibraryFormMode.createLocal,
      );

  @override
  Future<void> addRemoteLibrary(BuildContext context) =>
      showLibraryMd3eFormDialog(
        context: context,
        mode: LibraryFormMode.createRemote,
      );

  @override
  Future<void> editRemoteLibrary(BuildContext context, LocalLibrary library) {
    if (!isRemoteLibrary(library)) {
      return Future<void>.value();
    }
    return showLibraryMd3eFormDialog(
      context: context,
      mode: LibraryFormMode.edit,
      library: library,
    );
  }

  @override
  Future<void> editLibrarySettings(
    BuildContext context,
    LocalLibrary library,
  ) => showLibraryMd3eFormDialog(
    context: context,
    mode: LibraryFormMode.edit,
    library: library,
  );

  @override
  Future<void> deleteLibrary(
    BuildContext context,
    LocalLibrary library, {
    bool navigateAfter = true,
  }) async {
    final bool confirmed = await showLibraryMd3eRemovePathConfirm(
      context,
      path: library.rootPath,
    );
    if (!context.mounted || !confirmed) {
      return;
    }
    final String deletedId = library.libraryId;
    final String path = GoRouterState.of(context).uri.path;
    final bool wasViewing =
        LibrariesRoutes.libraryIdFromPath(path) == deletedId ||
        _ref.read(currentLibraryStateProvider).asData?.value.currentId ==
            deletedId;

    await _ref.read(currentLibraryPortProvider).deleteLibrary(deletedId);
    if (!context.mounted) {
      return;
    }
    showSuccessToast(context, context.l10n.libraryRemovedToast);

    if (!navigateAfter || !wasViewing) {
      return;
    }
    await _navigateAfterLibraryDeleted(context);
  }

  Future<void> _navigateAfterLibraryDeleted(BuildContext context) async {
    final CurrentLibraryState? state = _ref
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
      await _ref.read(currentLibraryPortProvider).clear();
      if (!context.mounted) {
        return;
      }
      context.go(nav.goPath);
      return;
    }
    await _ref.read(currentLibraryPortProvider).select(selectId);
    if (!context.mounted) {
      return;
    }
    context.go(nav.goPath);
  }

  @override
  Future<void> openLibrary(BuildContext context, String libraryId) async {
    _ref.read(comicDetailReturnSeriesPortProvider).clear();
    await _ref.read(currentLibraryPortProvider).select(libraryId);
    if (!context.mounted) {
      return;
    }
    context.go(LibrariesRoutes.library(libraryId));
  }

  @override
  void goAllLibraries(BuildContext context) {
    _ref.read(comicDetailReturnSeriesPortProvider).clear();
    context.go(LibrariesRoutes.all);
  }

  @override
  void goCurrentLibraryBrowse(BuildContext context) {
    _ref.read(comicDetailReturnSeriesPortProvider).clear();
    final String? currentId = _ref
        .read(currentLibraryStateProvider)
        .asData
        ?.value
        .currentId;
    context.go(LibrariesRoutes.browsePathForCurrent(currentId));
  }

  @override
  Future<void> scanLibrary(
    BuildContext context,
    String libraryId, {
    ScanMode mode = ScanMode.incremental,
    bool navigate = false,
  }) async {
    await _ref.read(currentLibraryPortProvider).select(libraryId);
    if (!context.mounted) {
      return;
    }
    if (navigate) {
      context.go(LibrariesRoutes.library(libraryId));
    }
    await _ref
        .read(libraryScanCommandPortProvider)
        .start(mode: mode, silent: true);
  }

  @override
  Future<void> scanAllLibraries({ScanMode mode = ScanMode.incremental}) async {
    await _ref
        .read(libraryScanCommandPortProvider)
        .start(mode: mode, syncAll: true, silent: true);
  }
}

LibraryManagementPort createLibraryManagementPort(Ref ref) =>
    _LibraryManagementAdapter(ref);
