import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/features/comic/domain/comic_metadata_form.dart';
import 'package:intl/intl.dart';

/// 发布日在 Lab 草稿中以 `yyyy-MM-dd` 文本保存（与 [PublishedDateTextField] 一致）。
final DateFormat _publishedDateFormat = DateFormat('yyyy-MM-dd');

ComicMetadataEditDraft comicMetadataDraftFromComic(
  Comic comic, {
  String? seriesSortOrderText,
}) {
  final DateTime? publishedAt = comic.publishedAt;
  return ComicMetadataEditDraft(
    title: comic.title,
    description: comic.description ?? '',
    publishedLabel: publishedAt == null
        ? ''
        : _publishedDateFormat.format(publishedAt),
    isR18: comic.contentRating == ContentRating.r18,
    languages: List<String>.from(comic.languages),
    parodies: List<String>.from(comic.parodies),
    authors: <String>[
      for (final AuthorRef author in comic.authors) author.name,
    ],
    characters: List<String>.from(comic.characters),
    tags: <String>[for (final Tag tag in comic.tags) tag.name],
    seriesSortOrderText: seriesSortOrderText,
  );
}

/// 将 Lab 草稿还原为生产表单。作者/标签按名称复用原对象，保留既有字段。
ComicMetadataForm comicMetadataFormFromDraft(
  ComicMetadataEditDraft draft,
  Comic original,
) {
  final Map<String, AuthorRef> authorsByName = <String, AuthorRef>{
    for (final AuthorRef author in original.authors) author.name: author,
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
    authors: <AuthorRef>[
      for (final String name in draft.authors)
        authorsByName[name] ?? AuthorRef.byName(name),
    ],
    tags: <Tag>[
      for (final String name in draft.tags) tagsByName[name] ?? Tag(name: name),
    ],
    languages: draft.languages,
    parodies: draft.parodies,
    characters: draft.characters,
  );
}
