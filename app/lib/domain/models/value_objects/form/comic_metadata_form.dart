import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';

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

/// [ComicMetadataForm.applyTo] 的结果：非法不调仓储；成功已落库。
/// 仓储异常仍向上抛，由 UI toast。
sealed class ComicMetadataApplyResult {
  const ComicMetadataApplyResult();
}

final class ComicMetadataApplyInvalid extends ComicMetadataApplyResult {
  const ComicMetadataApplyInvalid(this.validation);

  final ComicMetadataFormValidation validation;
}

final class ComicMetadataApplySucceeded extends ComicMetadataApplyResult {
  const ComicMetadataApplySucceeded();
}

extension ComicMetadataFormOps on ComicMetadataForm {
  /// 一次算出字段错误（目前仅标题）。
  ComicMetadataFormValidation validate() {
    return ComicMetadataFormValidation(
      titleError: title.trim().isEmpty ? '漫画标题不能为空' : null,
    );
  }

  /// trim 标题；概要空白 → `null`；Language trim + 保序去重。
  ComicMetadataForm get normalized {
    return copyWith(
      title: title.trim(),
      description: _normalizeOptionalText(description),
      languages: _normalizeOrderedNames(languages),
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

  /// 非法 → [ComicMetadataApplyInvalid]；相对 [original] 仅提交值变化字段 →
  /// [ComicMetadataApplySucceeded]。无变化时不调仓储。`isR18` → Content rating。
  Future<ComicMetadataApplyResult> applyTo(
    ComicRepository repository,
    Comic original,
  ) async {
    final ComicMetadataForm ready = normalized;
    final ComicMetadataFormValidation validation = ready.validate();
    if (!validation.isValid) {
      return ComicMetadataApplyInvalid(validation);
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

    final bool hasChanges =
        title != null ||
        description != null ||
        publishedAt != null ||
        clearPublishedAt ||
        contentRating != null ||
        authors != null ||
        tags != null ||
        languages != null;
    if (!hasChanges) {
      return const ComicMetadataApplySucceeded();
    }

    await repository.updateUserMeta(
      original.comicId,
      title: title,
      description: description,
      publishedAt: publishedAt,
      clearPublishedAt: clearPublishedAt,
      authors: authors,
      contentRating: contentRating,
      tags: tags,
      languages: languages,
    );
    return const ComicMetadataApplySucceeded();
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
