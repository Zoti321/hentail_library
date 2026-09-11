import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

/// 删除 Comic 前的确认对话框（与标签/路径等确认框同一套 HentaiDialog 壳）。
class ComicConfirmDeleteDialog extends HookWidget {
  const ComicConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.isLocal,
  });

  final String title;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final acknowledgement = useState(false);
    final bool canConfirm = !isLocal || acknowledgement.value;
    return HentaiDialog(
      title: l10n.comicDetailDeleteTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isLocal
                ? l10n.comicDetailDeleteLocalConfirm(title)
                : l10n.comicDetailDeleteRemoteConfirm(title),
            style: TextStyle(fontSize: 14, color: cs.hentai.textSecondary),
          ),
          if (isLocal) ...<Widget>[
            const SizedBox(height: 12),
            CheckboxListTile(
              value: acknowledgement.value,
              onChanged: (bool? value) =>
                  acknowledgement.value = value ?? false,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                l10n.comicDetailDeleteLocalAcknowledge,
                style: TextStyle(fontSize: 14, color: cs.hentai.textPrimary),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        DestructiveFilledButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}
