import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_cover_editor_notifier.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 以当前阅读页为封面的页码（0 基）。
int readerCoverPageIndex(int currentIndex) =>
    (currentIndex - 1).clamp(0, 1 << 30);

/// 将当前页设为漫画封面。
Future<void> setComicCoverFromReader(
  BuildContext context,
  WidgetRef ref, {
  required ReaderViewModelKey viewKey,
  required AppLocalizations l10n,
}) {
  return _runCoverAction(
    context,
    ref,
    viewKey: viewKey,
    notStateReadyMessage: l10n.readerStateNotReady,
    action: (ReaderUiState state) => ref
        .read(readerCoverEditorProvider.notifier)
        .setComicCover(
          state.comic,
          pageIndex: readerCoverPageIndex(state.currentIndex),
        ),
    successMessage: l10n.readerComicCoverSet,
    failureMessage: (Object error) => l10n.readerComicCoverSetFailed('$error'),
  );
}

/// 将当前页设为所属系列的封面。
Future<void> setSeriesCoverFromReader(
  BuildContext context,
  WidgetRef ref, {
  required ReaderViewModelKey viewKey,
  required String seriesId,
  required AppLocalizations l10n,
}) {
  return _runCoverAction(
    context,
    ref,
    viewKey: viewKey,
    notStateReadyMessage: l10n.readerStateNotReady,
    action: (ReaderUiState state) => ref
        .read(readerCoverEditorProvider.notifier)
        .setSeriesCover(
          seriesId.trim(),
          state.comic,
          pageIndex: readerCoverPageIndex(state.currentIndex),
        ),
    successMessage: l10n.readerSeriesCoverSet,
    failureMessage: (Object error) => l10n.readerSeriesCoverSetFailed('$error'),
  );
}

Future<void> _runCoverAction(
  BuildContext context,
  WidgetRef ref, {
  required ReaderViewModelKey viewKey,
  required String notStateReadyMessage,
  required Future<void> Function(ReaderUiState state) action,
  required String successMessage,
  required String Function(Object error) failureMessage,
}) async {
  final ReaderUiState? state = ref
      .read(readerViewModelProvider(viewKey))
      .asData
      ?.value;
  if (state == null) {
    showInfoSnackbar(context, notStateReadyMessage);
    return;
  }
  try {
    await action(state);
    if (context.mounted) {
      showSuccessSnackbar(context, successMessage);
    }
  } on Object catch (error) {
    if (context.mounted) {
      showErrorSnackbar(context, failureMessage(error));
    }
  }
}
