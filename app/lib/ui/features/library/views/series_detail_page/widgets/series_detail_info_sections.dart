import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/r18_rating_chip.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_info_sections.dart';

/// 连载状态 chip；[status] 为空时不渲染。
class SeriesSerializationChip extends StatelessWidget {
  const SeriesSerializationChip({super.key, this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final String? label = status?.trim();
    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }
    return OutlinedMetaChip(text: label);
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
    final String? serializationLabel =
        series.serializationStatus == SerializationStatus.unknown
        ? null
        : series.serializationStatus.label;
    final List<Widget> segments = <Widget>[
      Text(
        series.volumeCountLabel,
        style: TextStyle(
          fontSize: tokens.text.bodySm,
          color: cs.hentai.textSecondary,
        ),
      ),
      SeriesSerializationChip(status: serializationLabel),
    ];
    if (showR18) {
      segments.add(const R18RatingChip());
    }

    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments,
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
