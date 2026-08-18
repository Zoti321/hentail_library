import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/tag_dictionary_import_result.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/features/metadata/state/tag_dictionary_import_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<TagDictionaryImportResult?> showTagDictionaryImportDialog({
  required BuildContext context,
  required TagDictionaryImportController controller,
  required Future<TagDictionaryImportResult?> Function({
    void Function(int received, int total)? onDownloadProgress,
  })
  importFromNetwork,
}) {
  return showDialog<TagDictionaryImportResult>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return TagDictionaryImportDialog(
        controller: controller,
        importFromNetwork: importFromNetwork,
      );
    },
  );
}

class TagDictionaryImportDialog extends HookConsumerWidget {
  const TagDictionaryImportDialog({
    required this.controller,
    required this.importFromNetwork,
    super.key,
  });

  final TagDictionaryImportController controller;
  final Future<TagDictionaryImportResult?> Function({
    void Function(int received, int total)? onDownloadProgress,
  })
  importFromNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final ValueNotifier<double?> progress = useState<double?>(null);
    final ValueNotifier<bool> started = useState<bool>(false);

    useEffect(() {
      if (started.value) {
        return null;
      }
      started.value = true;
      Future<void>(() async {
        final TagDictionaryImportResult? result = await importFromNetwork(
          onDownloadProgress: (int received, int total) {
            if (total <= 0) {
              progress.value = null;
              return;
            }
            progress.value = received / total;
          },
        );
        if (!context.mounted) {
          return;
        }
        if (result != null) {
          Navigator.of(context).pop(result);
        } else {
          Navigator.of(context).pop();
        }
      });
      return null;
    }, <Object?>[started.value]);

    return HentaiDialog(
      title: l10n.metadataImportEhTagDialogTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.metadataImportEhTagDialogBody,
            style: TextStyle(color: colorScheme.hentai.textSecondary),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress.value,
            minHeight: 4,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            controller.cancel();
            Navigator.of(context).pop();
          },
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}
