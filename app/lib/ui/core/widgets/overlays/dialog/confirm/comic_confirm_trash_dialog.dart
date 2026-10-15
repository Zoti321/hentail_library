import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

/// Comic trash 前的轻量确认：可恢复操作，无勾选闸门、普通样式按钮。
class ComicConfirmTrashDialog extends StatelessWidget {
  const ComicConfirmTrashDialog({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return HentaiDialog(
      title: l10n.comicDetailDeleteTitle,
      content: Text(
        l10n.comicTrashConfirmContent(title),
        style: TextStyle(fontSize: 14, color: cs.hentai.textSecondary),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}
