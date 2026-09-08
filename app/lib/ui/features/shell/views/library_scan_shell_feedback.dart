import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/terminal_spinner.dart';
import 'package:hentai_library/ui/features/shell/state/library_scan_toasts.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';

/// Shell-global silent Library sync completion Toasts + visible busy strip.
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
      showLibraryScanCompletionToast(context, (
        cancelled: next.cancelled,
        error: next.error,
        scanMode: next.scanMode,
        progress: next.progress,
        fromStartup: previous?.fromStartup ?? false,
      ));
    });

    final bool silentBusy = ref.watch(
      scanLibraryControllerProvider.select(
        (ScanLibraryState s) => s.running && s.silent,
      ),
    );
    if (!silentBusy) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool deep = ref.watch(
      scanLibraryControllerProvider.select(
        (ScanLibraryState s) => s.scanMode == ScanMode.full,
      ),
    );

    return Material(
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Container(
        width: double.infinity,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.hentai.borderSubtle),
          ),
        ),
        child: Row(
          children: <Widget>[
            TerminalSpinner(color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                deep ? l10n.libraryScanningDeep : l10n.libraryScanning,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.hentai.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
