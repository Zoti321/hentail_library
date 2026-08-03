import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_number_stepper_field.dart';
import 'package:hentai_library/ui/core/widgets/form/metadata_lock_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> showEditSeriesItemSortOrderDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String seriesId,
  required String comicId,
  required String comicTitle,
  required double initialSortOrder,
  required bool initialSortOrderLocked,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => EditSeriesItemSortOrderDialog(
      seriesId: seriesId,
      comicId: comicId,
      comicTitle: comicTitle,
      initialSortOrder: initialSortOrder,
      initialSortOrderLocked: initialSortOrderLocked,
      onSubmit: (double sortOrder, bool locked) async {
        final repo = ref.read(seriesRepoProvider);
        await repo.updateSeriesItemSortOrder(
          seriesId: seriesId,
          comicId: comicId,
          sortOrder: sortOrder,
        );
        // Saving sort order always locks; if user wants unlocked, clear after.
        if (!locked) {
          await repo.setSeriesItemSortOrderLocked(
            seriesId: seriesId,
            comicId: comicId,
            locked: false,
          );
        }
        ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
        ref
            .read(
              seriesDetailComicsCatalogControllerProvider(seriesId).notifier,
            )
            .refresh();
      },
    ),
  );
}

class EditSeriesItemSortOrderDialog extends HookConsumerWidget {
  const EditSeriesItemSortOrderDialog({
    super.key,
    required this.seriesId,
    required this.comicId,
    required this.comicTitle,
    required this.initialSortOrder,
    required this.initialSortOrderLocked,
    required this.onSubmit,
  });

  final String seriesId;
  final String comicId;
  final String comicTitle;
  final double initialSortOrder;
  final bool initialSortOrderLocked;
  final Future<void> Function(double sortOrder, bool locked) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final valueState = useState<String>(_formatInitial(initialSortOrder));
    final lockedState = useState<bool>(initialSortOrderLocked);
    final errorState = useState<String?>(null);
    final savingState = useState(false);

    Future<void> handleSave() async {
      if (savingState.value) {
        return;
      }

      final String trimmed = valueState.value.trim();
      final double? parsed = double.tryParse(trimmed);
      if (trimmed.isEmpty || parsed == null || !parsed.isFinite) {
        errorState.value = l10n.formSeriesItemSortOrderInvalid;
        return;
      }

      savingState.value = true;
      try {
        await onSubmit(parsed, lockedState.value);
        if (context.mounted) {
          showSuccessToast(context, l10n.commonSavedToast);
          Navigator.of(context).pop();
        }
      } catch (_) {
        if (context.mounted) {
          showCustomToast(
            context,
            message: l10n.commonSaveFailedToast,
            type: AppToastType.error,
          );
        }
      } finally {
        savingState.value = false;
      }
    }

    return HentaiDialog(
      title: l10n.dialogEditSeriesItemSortOrderTitle,
      content: FluentNumberStepperField(
        initialValue: valueState.value,
        labelText: l10n.formSeriesItemSortOrderLabel,
        labelTrailing: MetadataLockButton(
          locked: lockedState.value,
          enabled: !savingState.value,
          onChanged: (bool locked) => lockedState.value = locked,
        ),
        errorText: errorState.value,
        autofocus: true,
        isDense: true,
        onChanged: (String next) {
          valueState.value = next;
          if (errorState.value != null) {
            errorState.value = null;
          }
        },
        onSubmitted: (_) => handleSave(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: savingState.value
              ? null
              : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: savingState.value ? null : handleSave,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: savingState.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}

String _formatInitial(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}
