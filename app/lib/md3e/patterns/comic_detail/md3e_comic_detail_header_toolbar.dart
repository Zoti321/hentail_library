import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_detail_header_toolbar.dart';

/// 漫画详情顶栏左侧工具条。
class Md3eComicDetailHeaderToolbar extends StatelessWidget {
  const Md3eComicDetailHeaderToolbar({
    super.key,
    this.onBack,
    this.onEdit,
    this.moreMenuEntries = const <M3EMenuNode>[],
  });

  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final List<M3EMenuNode> moreMenuEntries;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Md3eDetailHeaderToolbar(
      onBack: onBack,
      onEdit: onEdit,
      editTooltip: l10n.comicDetailEditMetadata,
      moreMenuEntries: moreMenuEntries,
    );
  }
}
