import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

part 'comic_metadata_form.freezed.dart';

/// Comic 用户元数据编辑草稿。
@freezed
abstract class ComicMetadataForm with _$ComicMetadataForm {
  factory ComicMetadataForm({
    required String title,
    String? description,
    DateTime? publishedAt,
    @Default(false) bool isR18,
    @Default([]) List<Tag> tags,
    @Default([]) List<Author> authors,
    @Default([]) List<String> languages,
    @Default([]) List<String> parodies,
    @Default([]) List<String> characters,
  }) = _ComicMetadataForm;

  factory ComicMetadataForm.fromComic(Comic comic) {
    return ComicMetadataForm(
      title: comic.title,
      description: comic.description,
      publishedAt: comic.publishedAt,
      isR18: comic.contentRating == ContentRating.r18,
      tags: List<Tag>.from(comic.tags),
      authors: List<Author>.from(comic.authors),
      languages: List<String>.from(comic.languages),
      parodies: List<String>.from(comic.parodies),
      characters: List<String>.from(comic.characters),
    );
  }
}

/// 字段级校验结果；[isValid] 为 true 时方可落库。
@freezed
abstract class ComicMetadataFormValidation with _$ComicMetadataFormValidation {
  const factory ComicMetadataFormValidation({String? titleError}) =
      _ComicMetadataFormValidation;

  const ComicMetadataFormValidation._();

  bool get isValid => titleError == null;
}

/// 草稿相对原 Comic 的同步差异。
sealed class ComicMetadataDraftDiff {
  const ComicMetadataDraftDiff();
}

/// 标题等校验未通过，没有待提交字段。
final class ComicMetadataDraftInvalid extends ComicMetadataDraftDiff {
  const ComicMetadataDraftInvalid(this.validation);

  final ComicMetadataFormValidation validation;
}

/// 规范化后与原 Comic 没有值变化。
final class ComicMetadataDraftUnchanged extends ComicMetadataDraftDiff {
  const ComicMetadataDraftUnchanged();
}

/// 仅含相对原 Comic 值发生变化的字段。
///
/// `null` 表示该字段不提交。清空发布日用 [clearPublishedAt]，
/// 不靠 [publishedAt] 本身区分。`isR18` 映射为 Content rating。
final class ComicMetadataDraftChanges extends ComicMetadataDraftDiff {
  const ComicMetadataDraftChanges({
    this.title,
    this.description,
    this.publishedAt,
    this.clearPublishedAt = false,
    this.contentRating,
    this.authors,
    this.tags,
    this.languages,
    this.parodies,
    this.characters,
  });

  final String? title;
  final String? description;
  final DateTime? publishedAt;
  final bool clearPublishedAt;
  final ContentRating? contentRating;
  final List<Author>? authors;
  final List<Tag>? tags;
  final List<String>? languages;
  final List<String>? parodies;
  final List<String>? characters;
}

extension ComicMetadataFormOps on ComicMetadataForm {
  /// 一次算出字段错误（目前仅标题）。
  ComicMetadataFormValidation validate() {
    return ComicMetadataFormValidation(
      titleError: title.trim().isEmpty ? '漫画标题不能为空' : null,
    );
  }

  /// trim 标题；概要空白 → `null`；Language / Parody / Character trim + 保序去重。
  ComicMetadataForm get normalized {
    return copyWith(
      title: title.trim(),
      description: _normalizeOptionalText(description),
      languages: _normalizeOrderedNames(languages),
      parodies: _normalizeOrderedNames(parodies),
      characters: _normalizeOrderedNames(characters),
    );
  }

  ComicMetadataForm addAuthor(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    if (authors.any((Author a) => a.name == trimmed)) {
      return this;
    }
    return copyWith(
      authors: <Author>[
        ...authors,
        Author(name: trimmed),
      ],
    );
  }

  ComicMetadataForm removeAuthor(String name) {
    return copyWith(
      authors: authors.where((Author a) => a.name != name).toList(),
    );
  }

  ComicMetadataForm addTag(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    if (tags.any((Tag t) => t.name == trimmed)) {
      return this;
    }
    return copyWith(
      tags: <Tag>[
        ...tags,
        Tag(name: trimmed),
      ],
    );
  }

  ComicMetadataForm removeTag(String name) {
    return copyWith(tags: tags.where((Tag t) => t.name != name).toList());
  }

  ComicMetadataForm addLanguage(String canonical) {
    final String trimmed = canonical.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    if (languages.contains(trimmed)) {
      return this;
    }
    return copyWith(languages: <String>[...languages, trimmed]);
  }

  ComicMetadataForm removeLanguage(String canonical) {
    return copyWith(
      languages: languages.where((String name) => name != canonical).toList(),
    );
  }

  ComicMetadataForm addParody(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    if (parodies.contains(trimmed)) {
      return this;
    }
    return copyWith(parodies: <String>[...parodies, trimmed]);
  }

  ComicMetadataForm removeParody(String name) {
    return copyWith(parodies: parodies.where((String n) => n != name).toList());
  }

  ComicMetadataForm addCharacter(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    if (characters.contains(trimmed)) {
      return this;
    }
    return copyWith(characters: <String>[...characters, trimmed]);
  }

  ComicMetadataForm removeCharacter(String name) {
    return copyWith(
      characters: characters.where((String n) => n != name).toList(),
    );
  }

  /// 相对 [original] 的同步差异：校验失败、无变化，或仅含待提交字段。
  ComicMetadataDraftDiff diffAgainst(Comic original) {
    final ComicMetadataForm ready = normalized;
    final ComicMetadataFormValidation validation = ready.validate();
    if (!validation.isValid) {
      return ComicMetadataDraftInvalid(validation);
    }

    final String? title = ready.title != original.title ? ready.title : null;
    final String? description = ready.description != original.description
        ? (ready.description ?? '')
        : null;

    final DateTime? publishedAt;
    final bool clearPublishedAt;
    if (ready.publishedAt == original.publishedAt) {
      publishedAt = null;
      clearPublishedAt = false;
    } else if (ready.publishedAt == null) {
      publishedAt = null;
      clearPublishedAt = true;
    } else {
      publishedAt = ready.publishedAt;
      clearPublishedAt = false;
    }

    final bool originalIsR18 = original.contentRating == ContentRating.r18;
    final ContentRating? contentRating = ready.isR18 != originalIsR18
        ? (ready.isR18 ? ContentRating.r18 : ContentRating.safe)
        : null;

    final List<Author>? authors =
        !_sameOrderedNames(
          ready.authors.map((Author a) => a.name),
          original.authors.map((Author a) => a.name),
        )
        ? ready.authors
        : null;
    final List<Tag>? tags =
        !_sameOrderedNames(
          ready.tags.map((Tag t) => t.name),
          original.tags.map((Tag t) => t.name),
        )
        ? ready.tags
        : null;
    final List<String>? languages =
        !_sameOrderedNames(ready.languages, original.languages)
        ? ready.languages
        : null;
    final List<String>? parodies =
        !_sameOrderedNames(ready.parodies, original.parodies)
        ? ready.parodies
        : null;
    final List<String>? characters =
        !_sameOrderedNames(ready.characters, original.characters)
        ? ready.characters
        : null;

    final bool hasChanges =
        title != null ||
        description != null ||
        publishedAt != null ||
        clearPublishedAt ||
        contentRating != null ||
        authors != null ||
        tags != null ||
        languages != null ||
        parodies != null ||
        characters != null;
    if (!hasChanges) {
      return const ComicMetadataDraftUnchanged();
    }

    return ComicMetadataDraftChanges(
      title: title,
      description: description,
      publishedAt: publishedAt,
      clearPublishedAt: clearPublishedAt,
      contentRating: contentRating,
      authors: authors,
      tags: tags,
      languages: languages,
      parodies: parodies,
      characters: characters,
    );
  }
}

String? _normalizeOptionalText(String? value) {
  if (value == null) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _normalizeOrderedNames(Iterable<String> source) {
  final List<String> out = <String>[];
  for (final String raw in source) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || out.contains(trimmed)) {
      continue;
    }
    out.add(trimmed);
  }
  return out;
}

bool _sameOrderedNames(Iterable<String> a, Iterable<String> b) {
  final List<String> left = a.toList();
  final List<String> right = b.toList();
  if (left.length != right.length) {
    return false;
  }
  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
