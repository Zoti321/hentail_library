import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_delete_dialog.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> confirmAndDeleteComic(
  BuildContext context,
  WidgetRef ref,
  Comic comic, {
  FutureOr<void> Function()? onDeleted,
}) async {
  final bool isLocal = isLocalComicResource(comic);
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) =>
        ComicConfirmDeleteDialog(title: comic.title, isLocal: isLocal),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  final l10n = context.l10n;
  try {
    await ref.read(comicDeletionServiceProvider).deleteComics(<String>[
      comic.comicId,
    ]);
    ref.read(comicCoverCacheManagerProvider.notifier).clearForComics(<String>[
      comic.comicId,
    ]);
    if (!context.mounted) {
      return;
    }
    showSuccessToast(
      context,
      isLocal
          ? l10n.comicDetailDeletedWithResourceToast
          : l10n.comicDetailRemovedFromLibraryToast,
    );
    await onDeleted?.call();
  } catch (err) {
    if (context.mounted) {
      showErrorToast(context, err);
    }
  }
}

bool isLocalComicResource(Comic comic) {
  final String lowerPath = comic.path.trim().toLowerCase();
  return !(lowerPath.startsWith('http://') || lowerPath.startsWith('https://'));
}
