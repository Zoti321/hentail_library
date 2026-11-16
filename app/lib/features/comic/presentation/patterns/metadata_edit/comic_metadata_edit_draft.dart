import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

/// Lab 漫画元数据编辑草稿（无领域 / Riverpod）。
class ComicMetadataEditDraft {
  const ComicMetadataEditDraft({
    required this.title,
    this.description = '',
    this.publishedLabel = '',
    this.isR18 = false,
    this.languages = const <String>[],
    this.parodies = const <String>[],
    this.authors = const <String>[],
    this.characters = const <String>[],
    this.tags = const <String>[],
    this.seriesSortOrderText,
  });

  final String title;
  final String description;
  final String publishedLabel;
  final bool isR18;
  final List<String> languages;
  final List<String> parodies;
  final List<String> authors;
  final List<String> characters;
  final List<String> tags;

  /// 所属系列内排序文本；null 表示该漫画不属于系列，不显示排序字段。
  final String? seriesSortOrderText;

  factory ComicMetadataEditDraft.fromEntry(ComicDetailViewObject entry) {
    return ComicMetadataEditDraft(
      title: entry.title,
      description: entry.description ?? '',
      publishedLabel: entry.publishedLabel ?? '',
      isR18: entry.showAgeRestrictionChip,
      languages: const <String>[],
      parodies: List<String>.of(entry.parodies),
      authors: <String>[for (final AuthorRef a in entry.authors) a.name],
      characters: List<String>.of(entry.characters),
      tags: List<String>.of(entry.tags),
    );
  }

  ComicMetadataEditDraft copyWith({
    String? title,
    String? description,
    String? publishedLabel,
    bool? isR18,
    List<String>? languages,
    List<String>? parodies,
    List<String>? authors,
    List<String>? characters,
    List<String>? tags,
    String? seriesSortOrderText,
  }) {
    return ComicMetadataEditDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      publishedLabel: publishedLabel ?? this.publishedLabel,
      isR18: isR18 ?? this.isR18,
      languages: languages ?? this.languages,
      parodies: parodies ?? this.parodies,
      authors: authors ?? this.authors,
      characters: characters ?? this.characters,
      tags: tags ?? this.tags,
      seriesSortOrderText: seriesSortOrderText ?? this.seriesSortOrderText,
    );
  }

  String? validateTitle() {
    if (title.trim().isEmpty) {
      return '标题不能为空';
    }
    return null;
  }
}
