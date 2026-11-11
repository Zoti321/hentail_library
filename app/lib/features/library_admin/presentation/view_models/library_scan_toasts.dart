import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_admin/public/ui/l10n/library_admin_l10n.dart';

/// Finished silent Library sync outcome for shell-global snackbar copy.
typedef LibraryScanCompletion = ({
  bool cancelled,
  String? error,
  ScanMode scanMode,
  SyncLibraryProgress? progress,
  bool fromStartup,
});

enum _LibraryScanToastKind { cancelled, error, warning, success }

/// Whether a controller transition should surface a silent-scan completion snackbar.
bool shouldShowLibraryScanCompletionToast({
  required bool? previousSilent,
  required bool? previousRunning,
  required bool nextRunning,
}) {
  if (previousSilent != true) {
    return false;
  }
  return previousRunning == true && !nextRunning;
}

_LibraryScanToastKind _kindFor(LibraryScanCompletion completion) {
  if (completion.cancelled) {
    return _LibraryScanToastKind.cancelled;
  }
  final String? error = completion.error;
  if (error != null && error.isNotEmpty) {
    return _LibraryScanToastKind.error;
  }
  final String? warning = completion.progress?.errorMessage;
  if (warning != null && warning.isNotEmpty) {
    return _LibraryScanToastKind.warning;
  }
  return _LibraryScanToastKind.success;
}

String libraryScanCompletionMessage(
  AppLocalizations l10n,
  LibraryScanCompletion completion,
) {
  return switch (_kindFor(completion)) {
    _LibraryScanToastKind.cancelled => l10n.libraryScanCancelledToast,
    _LibraryScanToastKind.error => completion.error!,
    _LibraryScanToastKind.warning => completion.progress!.errorMessage!,
    _LibraryScanToastKind.success => l10n.libraryScanSuccessToast(
      mode: completion.scanMode,
      progress: completion.progress,
      fromStartup: completion.fromStartup,
    ),
  };
}

void showLibraryScanCompletionToast(
  BuildContext context,
  LibraryScanCompletion completion,
) {
  final String message = libraryScanCompletionMessage(context.l10n, completion);
  M3ESnackbar.show(
    context,
    message: message,
    duration: const Duration(milliseconds: 4000),
  );
}
