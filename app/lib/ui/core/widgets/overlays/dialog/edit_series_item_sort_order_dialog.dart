import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_number_stepper_field.dart';
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
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => EditSeriesItemSortOrderDialog(
      seriesId: seriesId,
      comicId: comicId,
      comicTitle: comicTitle,
      initialSortOrder: initialSortOrder,
      onSubmit: (double sortOrder) async {
        await ref.read(seriesRepoProvider).updateSeriesItemSortOrder(
          seriesId: seriesId,
          comicId: comicId,
          sortOrder: sortOrder,
        );
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
    required this.onSubmit,
  });

  final String seriesId;
  final String comicId;
  final String comicTitle;
  final double initialSortOrder;
  final Future<void> Function(double sortOrder) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final valueState = useState<String>(_formatInitial(initialSortOrder));
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
        await onSubmit(parsed);
        if (context.mounted) {
          showSuccessToast(
            context,
            l10n.dialogEditSeriesItemSortOrderSavedToast,
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (context.mounted) {
          showErrorToast(context, error);
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
          onPressed: savingState.value ? null : () => Navigator.of(context).pop(),
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
