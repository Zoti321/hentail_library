import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画语言闭集快捷多选（对齐生产编辑元数据语言 chip）。
class Md3eComicLanguageQuickPick extends StatelessWidget {
  const Md3eComicLanguageQuickPick({
    super.key,
    required this.selected,
    required this.onCanonicalToggled,
  });

  /// 已选规范名（[ComicLanguageNames.closedSet] 元素）。
  final List<String> selected;
  final ValueChanged<String> onCanonicalToggled;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: ComicLanguageNames.closedSet.map((String canonical) {
        final bool isSelected = selected.contains(canonical);
        return M3EChip(
          label: l10n.comicLanguageLabel(canonical),
          type: M3EChipType.filter,
          selected: isSelected,
          onPressed: () => onCanonicalToggled(canonical),
        );
      }).toList(),
    );
  }
}
