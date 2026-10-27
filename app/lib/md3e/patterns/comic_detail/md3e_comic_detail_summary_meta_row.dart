import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/shared/md3e_age_restriction_chip_mount.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const String kMd3eComicDetailSummaryMetaSeparator = ' • ';

/// 封面右侧摘要：年龄限制 chip、页数、出版日期。
class Md3eComicDetailSummaryMetaRow extends StatefulWidget {
  const Md3eComicDetailSummaryMetaRow({super.key, required this.entry});

  final Md3eComicDetailEntry entry;

  @override
  State<Md3eComicDetailSummaryMetaRow> createState() =>
      _Md3eComicDetailSummaryMetaRowState();
}

class _Md3eComicDetailSummaryMetaRowState
    extends State<Md3eComicDetailSummaryMetaRow> {
  bool _ageChipInTree = false;

  @override
  void initState() {
    super.initState();
    _ageChipInTree = widget.entry.showAgeRestrictionChip;
  }

  @override
  void didUpdateWidget(covariant Md3eComicDetailSummaryMetaRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.showAgeRestrictionChip) {
      _ageChipInTree = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ETypeScale type = M3ETheme.of(context).typeScale;
    final Color secondary = M3ETheme.of(context).colorScheme.onSurfaceVariant;
    final TextStyle style = type.bodySmall.copyWith(color: secondary);
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    final String? pageLabel = widget.entry.pageCount == null
        ? null
        : l10n.comicDetailPageCount(widget.entry.pageCount!);
    final String? publishedLabel = widget.entry.publishedLabel;

    final List<Widget> children = <Widget>[];

    if (_ageChipInTree) {
      children.add(
        Md3eAgeRestrictionChipMount(
          visible: widget.entry.showAgeRestrictionChip,
          onFullyHidden: () => setState(() => _ageChipInTree = false),
        ),
      );
    }

    if (pageLabel != null || publishedLabel != null) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (pageLabel != null) Text(pageLabel, style: style),
            if (pageLabel != null && publishedLabel != null)
              Text(kMd3eComicDetailSummaryMetaSeparator, style: style),
            if (publishedLabel != null) Text(publishedLabel, style: style),
          ],
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
