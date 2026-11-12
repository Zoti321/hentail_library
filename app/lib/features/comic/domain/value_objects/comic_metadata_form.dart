import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/comic_metadata_normalization.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

part 'comic_metadata_form.freezed.dart';

/// Comic 用户元数据编辑草稿（UI 编辑态）。
///
/// 语义迁移（应用到实体、与实体求差异）在 [Comic] 上（ADR-0041）；
/// 本类型只保留草稿编辑操作（增删 facet、规范化、去重）。
@freezed
abstract class ComicMetadataForm with _$ComicMetadataForm {
  factory ComicMetadataForm({
    required String title,
    String? description,
    DateTime? publishedAt,
    @Default(false) bool isR18,
    @Default([]) List<Tag> tags,
    @Default([]) List<AuthorRef> authors,
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
      tags: List<Tag>.of(comic.tags),
      authors: List<AuthorRef>.of(comic.authors),
      languages: List<String>.of(comic.languages),
      parodies: List<String>.of(comic.parodies),
      characters: List<String>.of(comic.characters),
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
  final List<AuthorRef>? authors;
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
      description: normalizeOptionalMetadataText(description),
      languages: normalizeOrderedFacetNames(languages),
      parodies: normalizeOrderedFacetNames(parodies),
      characters: normalizeOrderedFacetNames(characters),
    );
  }

  ComicMetadataForm addAuthor(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    if (authors.any((AuthorRef a) => a.name == trimmed)) {
      return this;
    }
    return copyWith(
      authors: <AuthorRef>[...authors, AuthorRef.byName(trimmed)],
    );
  }

  ComicMetadataForm removeAuthor(String name) {
    return copyWith(
      authors: authors.where((AuthorRef a) => a.name != name).toList(),
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
}
