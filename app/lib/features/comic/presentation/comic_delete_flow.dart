import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/md3e_confirm_dialog.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 删除入口：轻量确认 → Comic trash（可在「已删除」页恢复）。封面缓存不清。
Future<void> confirmAndTrashComic(
  BuildContext context,
  WidgetRef ref,
  Comic comic, {
  FutureOr<void> Function()? onTrashed,
}) async {
  final l10n = context.l10n;
  final bool confirmed = await showMd3eConfirmDialog(
    context,
    title: l10n.comicDetailDeleteTitle,
    content: Builder(
      builder: (BuildContext dialogContext) {
        final M3EThemeData theme = M3ETheme.of(dialogContext);
        return Text(
          l10n.comicTrashConfirmContent(comic.title),
          style: theme.typeScale.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
    ),
    confirmLabel: l10n.commonDelete,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref.read(comicTrashCommandPortProvider).trash(<String>[
      comic.comicId,
    ]);
    if (!context.mounted) {
      return;
    }
    showSuccessSnackbar(context, l10n.comicTrashedToast);
    await onTrashed?.call();
  } catch (err) {
    if (context.mounted) {
      showErrorSnackbar(context, err);
    }
  }
}
