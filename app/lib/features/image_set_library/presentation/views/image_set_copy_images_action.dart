import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';

const List<String> kImageSetCopyPickerExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'avif',
];

/// Picks local image paths for copy-in; empty when cancelled.
Future<List<String>> pickImageSetCopySourcePaths(BuildContext context) async {
  final AppLocalizations l10n = context.l10n;
  final FilePickerResult? picked = await FilePicker.pickFiles(
    dialogTitle: l10n.imageSetMutationCopyPickTitle,
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: kImageSetCopyPickerExtensions,
  );
  if (picked == null) {
    return const <String>[];
  }
  return picked.paths
      .whereType<String>()
      .where((String path) => path.isNotEmpty)
      .toList(growable: false);
}
