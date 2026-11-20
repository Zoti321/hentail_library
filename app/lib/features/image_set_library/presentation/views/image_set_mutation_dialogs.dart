import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';

Future<bool> confirmDeleteImageSetImagesOnDisk(
  BuildContext context, {
  required int count,
}) {
  final AppLocalizations l10n = context.l10n;
  return showConfirmDialog(
    context,
    title: l10n.imageSetMutationDeleteOnDiskTitle,
    content: Text(l10n.imageSetMutationDeleteOnDiskBody(count)),
    confirmLabel: l10n.imageSetMutationDeleteOnDiskConfirm,
    destructive: true,
  );
}

Future<bool> confirmTakeOverImageSetManagedLayout(BuildContext context) {
  final AppLocalizations l10n = context.l10n;
  return showConfirmDialog(
    context,
    title: l10n.imageSetMutationTakeoverTitle,
    content: Text(l10n.imageSetMutationTakeoverBody),
    confirmLabel: l10n.imageSetMutationTakeoverConfirm,
    destructive: true,
  );
}