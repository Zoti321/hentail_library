import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_age_restriction_chip_slot.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_language_row.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_serialization_chip.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列封面右侧摘要：语言、连载 / R18、卷数进度。
class Md3eSeriesDetailSummaryMetaRow extends StatefulWidget {
  const Md3eSeriesDetailSummaryMetaRow({super.key, required this.entry});

  final Md3eSeriesDetailEntry entry;

  @override
  State<Md3eSeriesDetailSummaryMetaRow> createState() =>
      _Md3eSeriesDetailSummaryMetaRowState();
}

class _Md3eSeriesDetailSummaryMetaRowState
    extends State<Md3eSeriesDetailSummaryMetaRow> {
  bool _ageChipMounted = false;

  @override
  void initState() {
    super.initState();
    _ageChipMounted = widget.entry.showAgeRestrictionChip;
  }

  @override
  void didUpdateWidget(covariant Md3eSeriesDetailSummaryMetaRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.showAgeRestrictionChip) {
      _ageChipMounted = true;
    }
  }

  void _onAgeChipFullyHidden() {
    if (mounted) {
      setState(() => _ageChipMounted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final TextStyle volumeStyle = theme.typeScale.bodySmall.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final String volumeLabel =
        l10n.seriesVolumeProgressLabel(
          current: widget.entry.volumeCurrent,
          total: widget.entry.volumeTotal,
        ) ??
        l10n.seriesVolumeCountLabel(widget.entry.volumeCurrent);

    final List<Widget> chipChildren = <Widget>[
      Md3eSeriesDetailSerializationChip(status: widget.entry.serializationStatus),
      if (_ageChipMounted)
        Md3eComicDetailAgeRestrictionChipSlot(
          visible: widget.entry.showAgeRestrictionChip,
          onFullyHidden: _onAgeChipFullyHidden,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: spacing.xs,
      children: <Widget>[
        Md3eSeriesDetailLanguageRow(languages: widget.entry.languages),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: chipChildren,
        ),
        Text(volumeLabel, style: volumeStyle),
      ],
    );
  }
}
