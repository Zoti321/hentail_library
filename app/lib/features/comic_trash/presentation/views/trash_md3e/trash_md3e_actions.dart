import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_controller.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash_md3e/trash_md3e_purge_dialog.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_purge_strategy.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';

/// 「已删除」页的恢复 / 永久删除入口（MD3E 页面共用，业务经 [trashPageControllerProvider]）。
Future<void> restoreTrashedComics(
  BuildContext context,
  WidgetRef ref,
  List<String> comicIds,
) async {
  final AppLocalizations l10n = context.l10n;
  try {
    final int restored = await ref
        .read(trashPageControllerProvider.notifier)
        .restore(comicIds);
    if (context.mounted) {
      showSuccessSnackbar(context, l10n.trashRestoredToast(restored));
    }
  } catch (err) {
    if (context.mounted) {
      showErrorSnackbar(context, err);
    }
  }
}

Future<void> restoreAllTrashedComics(
  BuildContext context,
  WidgetRef ref,
) async {
  final AppLocalizations l10n = context.l10n;
  try {
    final int restored = await ref
        .read(trashPageControllerProvider.notifier)
        .restoreAll();
    if (context.mounted && restored > 0) {
      showSuccessSnackbar(context, l10n.trashRestoredToast(restored));
    }
  } catch (err) {
    if (context.mounted) {
      showErrorSnackbar(context, err);
    }
  }
}

Future<void> purgeTrashedComics(
  BuildContext context,
  WidgetRef ref,
  List<TrashedComic> items,
) async {
  if (items.isEmpty) {
    return;
  }
  final bool confirmed = await showTrashMd3ePurgeConfirmDialog(
    context: context,
    title: items.length == 1 ? items.single.comic.title : null,
    counts: countPurgeTargets(items),
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  await _runPurge(
    context,
    () => ref
        .read(trashPageControllerProvider.notifier)
        .purge(items.map((TrashedComic item) => item.comic.comicId).toList()),
  );
}

Future<void> purgeAllTrashedComics(
  BuildContext context,
  WidgetRef ref,
  PurgeTargetCounts counts,
) async {
  final bool confirmed = await showTrashMd3ePurgeConfirmDialog(
    context: context,
    counts: counts,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  await _runPurge(
    context,
    () => ref.read(trashPageControllerProvider.notifier).purgeAll(),
  );
}

Future<void> _runPurge(
  BuildContext context,
  Future<ComicPurgeResult> Function() purge,
) async {
  final AppLocalizations l10n = context.l10n;
  try {
    final ComicPurgeResult result = await purge();
    if (!context.mounted) {
      return;
    }
    switch (purgeSummaryKindFor(result)) {
      case PurgeSummaryKind.nothing:
        break;
      case PurgeSummaryKind.allSucceeded:
        showSuccessSnackbar(
          context,
          l10n.trashPurgeSucceededToast(result.succeeded),
        );
      case PurgeSummaryKind.partial:
        showInfoSnackbar(
          context,
          l10n.trashPurgePartialToast(result.succeeded, result.failed),
        );
      case PurgeSummaryKind.allFailed:
        showErrorSnackbar(context, l10n.trashPurgeFailedToast(result.failed));
    }
  } catch (err) {
    if (context.mounted) {
      showErrorSnackbar(context, err);
    }
  }
}
