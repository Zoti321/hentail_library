import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';

/// Lab 漫画元数据编辑草稿（无领域 / Riverpod）。
class Md3eComicMetadataEditDraft {
  const Md3eComicMetadataEditDraft({
    required this.title,
    this.description = '',
    this.publishedLabel = '',
    this.isR18 = false,
    this.languages = const <String>[],
    this.parodies = const <String>[],
    this.authors = const <String>[],
    this.characters = const <String>[],
    this.tags = const <String>[],
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

  factory Md3eComicMetadataEditDraft.fromEntry(Md3eComicDetailEntry entry) {
    return Md3eComicMetadataEditDraft(
      title: entry.title,
      description: entry.description ?? '',
      publishedLabel: entry.publishedLabel ?? '',
      isR18: entry.showAgeRestrictionChip,
      languages: const <String>[],
      parodies: List<String>.from(entry.parodies),
      authors: List<String>.from(entry.authors),
      characters: List<String>.from(entry.characters),
      tags: List<String>.from(entry.tags),
    );
  }

  Md3eComicMetadataEditDraft copyWith({
    String? title,
    String? description,
    String? publishedLabel,
    bool? isR18,
    List<String>? languages,
    List<String>? parodies,
    List<String>? authors,
    List<String>? characters,
    List<String>? tags,
  }) {
    return Md3eComicMetadataEditDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      publishedLabel: publishedLabel ?? this.publishedLabel,
      isR18: isR18 ?? this.isR18,
      languages: languages ?? this.languages,
      parodies: parodies ?? this.parodies,
      authors: authors ?? this.authors,
      characters: characters ?? this.characters,
      tags: tags ?? this.tags,
    );
  }

  String? validateTitle() {
    if (title.trim().isEmpty) {
      return '标题不能为空';
    }
    return null;
  }
}
