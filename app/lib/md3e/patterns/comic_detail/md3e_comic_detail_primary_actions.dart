import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读 / 无痕阅读主操作。
class Md3eComicDetailPrimaryActions extends StatelessWidget {
  const Md3eComicDetailPrimaryActions({
    super.key,
    this.onRead,
    this.onReadIncognito,
  });

  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Wrap(
      spacing: spacing.md,
      runSpacing: spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        M3EButton.icon(
          onPressed: onRead,
          icon: const Icon(Symbols.menu_book, size: 18),
          label: Text(l10n.comicDetailRead),
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
        ),
        M3EButton.icon(
          onPressed: onReadIncognito,
          icon: const Icon(Symbols.visibility_off, size: 18),
          label: Text(l10n.comicDetailReadIncognito),
          style: M3EButtonStyle.tonal,
          size: M3EButtonSize.sm,
        ),
      ],
    );
  }
}
