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
  }) = _ComicMetadataForm;

  factory ComicMetadataForm.fromComic(Comic comic) {
    return ComicMetadataForm(
      title: comic.title,
      description: comic.description,
      publishedAt: comic.publishedAt,
      isR18: comic.contentRating == ContentRating.r18,
      tags: List<Tag>.from(comic.tags),
      authors: List<Author>.from(comic.authors),
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

  /// trim 标题；概要空白 → `null`。
  ComicMetadataForm get normalized {
    return copyWith(
      title: title.trim(),
      description: _normalizeOptionalText(description),
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

  /// 非法 → [ComicMetadataApplyInvalid]；合法用 [normalized] 落库 →
  /// [ComicMetadataApplySucceeded]。`isR18` → Content rating。
  Future<ComicMetadataApplyResult> applyTo(
    ComicRepository repository,
    String comicId,
  ) async {
    final ComicMetadataForm ready = normalized;
    final ComicMetadataFormValidation validation = ready.validate();
    if (!validation.isValid) {
      return ComicMetadataApplyInvalid(validation);
    }

    await repository.updateUserMeta(
      comicId,
      title: ready.title,
      description: ready.description ?? '',
      publishedAt: ready.publishedAt,
      authors: ready.authors,
      contentRating: ready.isR18 ? ContentRating.r18 : ContentRating.safe,
      tags: ready.tags,
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
