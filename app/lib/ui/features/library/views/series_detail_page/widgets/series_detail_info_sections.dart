import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/layout/detail_meta_chip_row_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/r18_rating_chip.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_info_sections.dart';

/// 休刊状态 chip 描边/文字色（仅系列详情页使用）。
Color _serializationChipAccentColor(
  ColorScheme cs,
  SerializationStatus status,
) {
  return switch (status) {
    SerializationStatus.ongoing => cs.hentai.success,
    SerializationStatus.ended => cs.hentai.textTertiary,
    SerializationStatus.hiatus => cs.hentai.serializationHiatus,
    SerializationStatus.unknown => cs.hentai.textSecondary,
  };
}

/// 连载状态 chip；[status] 为 [SerializationStatus.unknown] 时不渲染。
class SeriesSerializationChip extends StatelessWidget {
  const SeriesSerializationChip({super.key, required this.status});

  final SerializationStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == SerializationStatus.unknown) {
      return const SizedBox.shrink();
    }
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accentColor = _serializationChipAccentColor(cs, status);
    return OutlinedMetaChip(
      text: context.l10n.serializationStatusLabel(status),
      borderColor: accentColor,
      textColor: accentColor,
      compact: true,
    );
  }
}

class SeriesDetailSummaryMetaRow extends StatelessWidget {
  const SeriesDetailSummaryMetaRow({
    super.key,
    required this.series,
    this.hasR18 = false,
    this.languages = const <String>[],
    this.parodies = const <String>[],
  });

  final Series series;
  final bool hasR18;
  final List<String> languages;
  final List<String> parodies;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final bool showSerialization =
        series.serializationStatus != SerializationStatus.unknown;
    final bool hasLanguages = languages.isNotEmpty;
    final bool hasParodies = parodies.isNotEmpty;
    final List<Widget> chipRowChildren = <Widget>[
      if (showSerialization)
        SeriesSerializationChip(status: series.serializationStatus),
      if (hasR18) const R18RatingChip(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.xs,
      children: <Widget>[
        // Align with Comic cover-right: Language → Parody → status chips → volume.
        if (hasLanguages) ComicLanguageSegments(languages: languages),
        if (hasParodies) ComicParodyChipRow(parodies: parodies),
        SizedBox(
          height: kSeriesDetailMetaChipRowHeight,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: tokens.spacing.sm,
              children: chipRowChildren,
            ),
          ),
        ),
        Text(
          l10n.seriesVolumeProgressLabel(
                current: series.items.length,
                total: series.totalCount,
              ) ??
              l10n.seriesVolumeCountLabel(series.items.length),
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textSecondary,
          ),
        ),
      ],
    );
  }
}

class SeriesDetailMetadataBlock extends StatelessWidget {
  const SeriesDetailMetadataBlock({
    super.key,
    required this.authors,
    required this.tags,
    this.characters = const <String>[],
  });

  final List<String> authors;
  final List<String> tags;
  final List<String> characters;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final List<Widget> rows = <Widget>[];
    if (authors.isNotEmpty) {
      rows.add(
        LabeledMetaChipRow(label: l10n.comicDetailAuthors, items: authors),
      );
    }
    if (tags.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: l10n.comicDetailTags, items: tags));
    }
    if (characters.isNotEmpty) {
      // Character labeled chip 行（Tags 下方）；与 Comic 一致占位 no-op（#75 / #74）。
      rows.add(
        LabeledMetaChipRow(
          label: l10n.comicDetailCharacters,
          items: characters,
          // TODO(#75/#74): field-scoped search for Character — placeholder no-op.
          onItemTap: (_) {},
        ),
      );
    }
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.md,
      children: rows,
    );
  }
}
