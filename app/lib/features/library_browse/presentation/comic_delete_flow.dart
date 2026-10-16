import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_trash_dialog.dart';
import 'package:hentai_library/ui/features/shell/view_models/comic_trash_actions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 删除入口：轻量确认 → Comic trash（可在「已删除」页恢复）。封面缓存不清。
Future<void> confirmAndTrashComic(
  BuildContext context,
  WidgetRef ref,
  Comic comic, {
  FutureOr<void> Function()? onTrashed,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) =>
        ComicConfirmTrashDialog(title: comic.title),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  final l10n = context.l10n;
  try {
    await ref.read(comicTrashActionsProvider.notifier).trash(<String>[
      comic.comicId,
    ]);
    if (!context.mounted) {
      return;
    }
    showSuccessToast(context, l10n.comicTrashedToast);
    await onTrashed?.call();
  } catch (err) {
    if (context.mounted) {
      showErrorToast(context, err);
    }
  }
}
