import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/layout/detail_meta_chip_row_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/r18_rating_chip.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_info_sections.dart';

/// 休刊状态 chip 描边/文字色（仅系列详情页使用）。
const Color _kSeriesHiatusChipColor = Color(0xFFF59E0B);

Color _serializationChipAccentColor(
  ColorScheme cs,
  SerializationStatus status,
) {
  return switch (status) {
    SerializationStatus.ongoing => cs.hentai.success,
    SerializationStatus.ended => cs.hentai.textTertiary,
    SerializationStatus.hiatus => _kSeriesHiatusChipColor,
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
      text: status.label,
      borderColor: accentColor,
      textColor: accentColor,
    );
  }
}

class SeriesDetailSummaryMetaRow extends StatelessWidget {
  const SeriesDetailSummaryMetaRow({
    super.key,
    required this.series,
    required this.comicsById,
  });

  final Series series;
  final Map<String, Comic> comicsById;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool showR18 = series.hasR18Comic(comicsById: comicsById);
    final bool showSerialization =
        series.serializationStatus != SerializationStatus.unknown;
    final List<Widget> chipRowChildren = <Widget>[
      if (showSerialization)
        SeriesSerializationChip(status: series.serializationStatus),
      if (showR18) const R18RatingChip(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.xs,
      children: <Widget>[
        SizedBox(
          height: kDetailMetaChipRowHeight,
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
          series.volumeProgressLabel ?? series.volumeCountLabel,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textSecondary,
          ),
        ),
      ],
    );
  }
}

bool seriesDetailHasMetadataBlock(
  List<SeriesItem> sortedItems,
  Map<String, Comic> comicsById,
) {
  return _aggregateAuthors(sortedItems, comicsById).isNotEmpty ||
      _aggregateTags(sortedItems, comicsById).isNotEmpty;
}

class SeriesDetailMetadataBlock extends StatelessWidget {
  const SeriesDetailMetadataBlock({
    super.key,
    required this.sortedItems,
    required this.comicsById,
  });

  final List<SeriesItem> sortedItems;
  final Map<String, Comic> comicsById;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final List<String> authors = _aggregateAuthors(sortedItems, comicsById);
    final List<String> tags = _aggregateTags(sortedItems, comicsById);
    final List<Widget> rows = <Widget>[];
    if (authors.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: '作者', items: authors));
    }
    if (tags.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: '标签', items: tags));
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

List<String> _aggregateAuthors(
  List<SeriesItem> sortedItems,
  Map<String, Comic> comicsById,
) {
  final Set<String> seen = <String>{};
  final List<String> authors = <String>[];
  for (final SeriesItem item in sortedItems) {
    final Comic? comic = comicsById[item.comicId];
    if (comic == null) {
      continue;
    }
    for (final author in comic.authors) {
      if (seen.add(author.name)) {
        authors.add(author.name);
      }
    }
  }
  return authors;
}

List<String> _aggregateTags(
  List<SeriesItem> sortedItems,
  Map<String, Comic> comicsById,
) {
  final Set<String> seen = <String>{};
  final List<String> tags = <String>[];
  for (final SeriesItem item in sortedItems) {
    final Comic? comic = comicsById[item.comicId];
    if (comic == null) {
      continue;
    }
    for (final tag in comic.tags) {
      if (seen.add(tag.name)) {
        tags.add(tag.name);
      }
    }
  }
  return tags;
}

Map<String, Comic> comicsByIdFromList(List<Comic> comics) {
  return <String, Comic>{
    for (final Comic comic in comics) comic.comicId: comic,
  };
}
