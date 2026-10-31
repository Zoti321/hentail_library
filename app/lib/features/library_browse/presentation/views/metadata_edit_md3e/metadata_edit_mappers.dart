import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_comic_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:intl/intl.dart';

/// 发布日在 Lab 草稿中以 `yyyy-MM-dd` 文本保存（与 [Md3ePublishedDateTextField] 一致）。
final DateFormat _publishedDateFormat = DateFormat('yyyy-MM-dd');

Md3eComicMetadataEditDraft comicMetadataDraftFromComic(
  Comic comic, {
  String? seriesSortOrderText,
}) {
  final DateTime? publishedAt = comic.publishedAt;
  return Md3eComicMetadataEditDraft(
    title: comic.title,
    description: comic.description ?? '',
    publishedLabel: publishedAt == null
        ? ''
        : _publishedDateFormat.format(publishedAt),
    isR18: comic.contentRating == ContentRating.r18,
    languages: List<String>.from(comic.languages),
    parodies: List<String>.from(comic.parodies),
    authors: <String>[for (final Author author in comic.authors) author.name],
    characters: List<String>.from(comic.characters),
    tags: <String>[for (final Tag tag in comic.tags) tag.name],
    seriesSortOrderText: seriesSortOrderText,
  );
}

/// 将 Lab 草稿还原为生产表单。作者/标签按名称复用原对象，保留既有字段。
ComicMetadataForm comicMetadataFormFromDraft(
  Md3eComicMetadataEditDraft draft,
  Comic original,
) {
  final Map<String, Author> authorsByName = <String, Author>{
    for (final Author author in original.authors) author.name: author,
  };
  final Map<String, Tag> tagsByName = <String, Tag>{
    for (final Tag tag in original.tags) tag.name: tag,
  };
  final String publishedText = draft.publishedLabel.trim();
  return ComicMetadataForm(
    title: draft.title,
    description: draft.description,
    publishedAt: publishedText.isEmpty
        ? null
        : DateTime.tryParse(publishedText),
    isR18: draft.isR18,
    authors: <Author>[
      for (final String name in draft.authors)
        authorsByName[name] ?? Author(name: name),
    ],
    tags: <Tag>[
      for (final String name in draft.tags) tagsByName[name] ?? Tag(name: name),
    ],
    languages: draft.languages,
    parodies: draft.parodies,
    characters: draft.characters,
  );
}

Md3eSeriesMetadataEditDraft seriesMetadataDraftFromSeries(Series series) {
  final SeriesMetadataForm form = SeriesMetadataForm.fromSeries(series);
  return Md3eSeriesMetadataEditDraft(
    name: form.name,
    serializationStatus: Md3eSeriesSerializationStatus.values.byName(
      form.serializationStatus.name,
    ),
    totalCountText: form.totalCountText,
  );
}

SeriesMetadataForm seriesMetadataFormFromDraft(
  Md3eSeriesMetadataEditDraft draft,
  Series series,
) {
  return SeriesMetadataForm.fromSeries(series).copyWith(
    name: draft.name,
    serializationStatus: SerializationStatus.values.byName(
      draft.serializationStatus.name,
    ),
    totalCountText: draft.totalCountText,
  );
}
