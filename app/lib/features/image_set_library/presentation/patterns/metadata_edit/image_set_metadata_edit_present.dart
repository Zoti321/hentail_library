import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_metadata_edit_sheet.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_actions.dart';

/// Opens Image set metadata edit: [showAdaptiveFormDialog] (narrow full-screen, wide basic dialog).
Future<ImageSet?> showImageSetMetadataEdit({
  required BuildContext context,
  required ImageSet imageSet,
  required ImageSetFacets initialFacets,
}) {
  final GlobalKey pageKey = GlobalKey();
  final AppLocalizations l10n = context.l10n;

  return showAdaptiveFormDialog<ImageSet>(
    context,
    title: l10n.imageSetMetadataEditTitle,
    form: ImageSetMetadataEditSheet(
      key: pageKey,
      imageSet: imageSet,
      initialFacets: initialFacets,
      presentation: MetadataEditPresentation.labFormBody,
    ),
    confirmLabel: l10n.commonSave,
    dismissLabel: l10n.commonCancel,
    onConfirm: () {
      final MetadataEditSaveActions? state =
          pageKey.currentState as MetadataEditSaveActions?;
      if (state != null) {
        unawaited(state.saveAndPop());
      }
    },
    basicMaxWidth: MetadataEditFormMetrics.comicMaxWidth,
  );
}

/// Alias for older call sites.
Future<ImageSet?> showImageSetMetadataEditSheet({
  required BuildContext context,
  required ImageSet imageSet,
  required ImageSetFacets initialFacets,
}) => showImageSetMetadataEdit(
  context: context,
  imageSet: imageSet,
  initialFacets: initialFacets,
);