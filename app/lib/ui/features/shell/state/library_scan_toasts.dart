import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';

/// Finished silent Library sync outcome for shell-global Toast copy.
typedef LibraryScanCompletion = ({
  bool cancelled,
  String? error,
  ScanMode scanMode,
  SyncLibraryProgress? progress,
  bool fromStartup,
});

enum _LibraryScanToastKind { cancelled, error, warning, success }

/// Whether a controller transition should surface a silent-scan completion Toast.
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

AppToastType libraryScanCompletionToastType(LibraryScanCompletion completion) {
  return switch (_kindFor(completion)) {
    _LibraryScanToastKind.cancelled ||
    _LibraryScanToastKind.warning => AppToastType.info,
    _LibraryScanToastKind.error => AppToastType.error,
    _LibraryScanToastKind.success => AppToastType.success,
  };
}

void showLibraryScanCompletionToast(
  BuildContext context,
  LibraryScanCompletion completion,
) {
  final String message = libraryScanCompletionMessage(context.l10n, completion);
  showCustomToast(
    context,
    message: message,
    type: libraryScanCompletionToastType(completion),
  );
}
