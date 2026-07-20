import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

class TagConfirmDeleteDialog extends StatelessWidget {
  const TagConfirmDeleteDialog({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HentaiDialog(
      title: l10n.confirmDeleteTagsTitle,
      content: Text(l10n.confirmDeleteTagsContent(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}
