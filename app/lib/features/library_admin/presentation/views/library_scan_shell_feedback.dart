import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_admin_state_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_scan_toasts.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';

/// Shell-global silent Library sync completion snackbar.
///
/// Mounted on [ResponsiveAppShell] so feedback does not depend on Library page
/// overflow being in the tree.
class LibraryScanShellFeedback extends ConsumerWidget {
  const LibraryScanShellFeedback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ScanLibraryState>(scanLibraryControllerProvider, (
      ScanLibraryState? previous,
      ScanLibraryState next,
    ) {
      if (!shouldShowLibraryScanCompletionToast(
        previousSilent: previous?.silent,
        previousRunning: previous?.running,
        nextRunning: next.running,
      )) {
        return;
      }
      // targetLibraryId is cleared when the run ends; read from previous.
      final String? targetLibraryId = previous?.targetLibraryId;
      showLibraryScanCompletionToast(context, (
        cancelled: next.cancelled,
        error: next.error,
        scanMode: next.scanMode,
        progress: next.progress,
        fromStartup: previous?.fromStartup ?? false,
        imageSetCatalog: _isImageSetTarget(ref, targetLibraryId),
      ));
    });

    return const SizedBox.shrink();
  }
}

bool _isImageSetTarget(WidgetRef ref, String? targetLibraryId) {
  if (targetLibraryId == null) {
    return false;
  }
  final LibrariesState? libraries = ref
      .read(librariesStateProvider)
      .asData
      ?.value;
  if (libraries == null) {
    return false;
  }
  for (final LocalLibrary library in libraries.libraries) {
    if (library.libraryId == targetLibraryId) {
      return isImageSetLibrary(library);
    }
  }
  return false;
}
