import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

/// 删除 Comic 前的确认对话框（与标签/路径等确认框同一套 HentaiDialog 壳）。
class ComicConfirmDeleteDialog extends StatelessWidget {
  const ComicConfirmDeleteDialog({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return HentaiDialog(
      title: l10n.comicDetailDeleteTitle,
      content: Text(
        l10n.comicDetailDeleteConfirm(title),
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
