import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/ui/patterns/shared/age_restriction_chip_mount.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_language_row.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_serialization_chip.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列封面右侧摘要：语言、连载 / R18、卷数进度。
class SeriesDetailSummaryMetaRow extends StatefulWidget {
  const SeriesDetailSummaryMetaRow({super.key, required this.entry});

  final SeriesDetailViewObject entry;

  @override
  State<SeriesDetailSummaryMetaRow> createState() =>
      _SeriesDetailSummaryMetaRowState();
}

class _SeriesDetailSummaryMetaRowState
    extends State<SeriesDetailSummaryMetaRow> {
  bool _ageChipInTree = false;

  @override
  void initState() {
    super.initState();
    _ageChipInTree = widget.entry.showAgeRestrictionChip;
  }

  @override
  void didUpdateWidget(covariant SeriesDetailSummaryMetaRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.showAgeRestrictionChip) {
      _ageChipInTree = true;
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

    final bool showSerialization =
        widget.entry.serializationStatus != SerializationStatus.unknown;

    final List<Widget> chipChildren = <Widget>[];
    if (showSerialization) {
      chipChildren.add(
        SeriesDetailSerializationChip(status: widget.entry.serializationStatus),
      );
    }
    if (_ageChipInTree) {
      chipChildren.add(
        AgeRestrictionChipMount(
          visible: widget.entry.showAgeRestrictionChip,
          onFullyHidden: () => setState(() => _ageChipInTree = false),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: spacing.xs,
      children: <Widget>[
        SeriesDetailLanguageRow(languages: widget.entry.languages),
        if (chipChildren.isNotEmpty)
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
