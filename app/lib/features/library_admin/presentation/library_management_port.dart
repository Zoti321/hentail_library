import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/constants/app_routes.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_delete_confirm_dialog.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_form_dialog.dart';
import 'package:hentai_library/shared/di/app_navigator_provider.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';

/// library_admin 对 [LibraryManagementPort] 的实现（#292）。
class _LibraryManagementAdapter implements LibraryManagementPort {
  _LibraryManagementAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> addLocalLibrary(BuildContext context) => showLibraryFormDialog(
    context: context,
    mode: LibraryFormMode.createLocal,
  );

  @override
  Future<void> addRemoteLibrary(BuildContext context) => showLibraryFormDialog(
    context: context,
    mode: LibraryFormMode.createRemote,
  );

  @override
  Future<void> editRemoteLibrary(BuildContext context, LocalLibrary library) {
    if (!isRemoteLibrary(library)) {
      return Future<void>.value();
    }
    return showLibraryFormDialog(
      context: context,
      mode: LibraryFormMode.edit,
      library: library,
    );
  }

  @override
  Future<void> editLibrarySettings(
    BuildContext context,
    LocalLibrary library,
  ) => showLibraryFormDialog(
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
    final bool confirmed = await showHomeLibraryDeleteConfirmDialog(
      context: context,
      libraryDisplayName: localLibraryDisplayName(library),
    );
    if (!context.mounted || !confirmed) {
      return;
    }
    final String deletedId = library.libraryId;
    final String path = _ref.read(appNavigatorProvider).currentPath();
    final bool wasViewing = AppRoutes.libraryIdFromPath(path) == deletedId;

    await _ref.read(librariesPortProvider).deleteLibrary(deletedId);
    if (!context.mounted) {
      return;
    }
    showSuccessSnackbar(context, context.l10n.libraryRemovedToast);

    if (!navigateAfter || !wasViewing) {
      return;
    }
    _navigateAfterLibraryDeleted(context);
  }

  void _navigateAfterLibraryDeleted(BuildContext context) {
    final LibrariesState? state = _ref
        .read(librariesStateProvider)
        .asData
        ?.value;
    final List<LocalLibrary> remaining =
        state?.libraries ?? const <LocalLibrary>[];
    final AfterLibraryDeleteNavigation nav = afterLibraryDeleteNavigation(
      remainingLibraryIds: remaining
          .map((LocalLibrary library) => library.libraryId)
          .toList(),
    );
    _ref.read(appNavigatorProvider).goLocation(nav.goPath);
  }

  @override
  Future<void> openLibrary(BuildContext context, String libraryId) async {
    _ref.read(comicDetailReturnSeriesPortProvider).clear();
    if (!context.mounted) {
      return;
    }
    _ref.read(appNavigatorProvider).goLibrary(libraryId);
  }

  @override
  void goDefaultLibraryBrowse(BuildContext context) {
    _ref.read(comicDetailReturnSeriesPortProvider).clear();
    _ref.read(appNavigatorProvider).goHome();
  }

  @override
  Future<void> scanLibrary(
    BuildContext context,
    String libraryId, {
    ScanMode mode = ScanMode.incremental,
    bool navigate = false,
  }) async {
    if (navigate && context.mounted) {
      _ref.read(appNavigatorProvider).goLibrary(libraryId);
    }
    await _ref
        .read(libraryScanCommandPortProvider)
        .start(mode: mode, targetLibraryId: libraryId, silent: true);
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
