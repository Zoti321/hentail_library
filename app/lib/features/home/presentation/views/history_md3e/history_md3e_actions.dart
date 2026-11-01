import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/home/presentation/view_models/history_paged_feed_controller.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';

Future<void> clearAllReadingHistory(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = context.l10n;
  try {
    await ref
        .read(historyPagedFeedControllerProvider.notifier)
        .clearAllHistory();
    if (context.mounted) {
      showSuccessToast(context, l10n.historyClearedToast);
    }
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
  }
}

Future<void> deleteReadingHistoryRecord({
  required BuildContext context,
  required WidgetRef ref,
  required String comicId,
}) async {
  final AppLocalizations l10n = context.l10n;
  try {
    await ref
        .read(historyPagedFeedControllerProvider.notifier)
        .deleteHistory(comicId);
    if (context.mounted) {
      showSuccessToast(context, l10n.historyDeletedToast);
    }
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
  }
}
