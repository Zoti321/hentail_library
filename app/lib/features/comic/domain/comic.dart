import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/comic/domain/comic_meta_locks.dart';
import 'package:hentai_library/features/comic/domain/comic_metadata_form.dart';
import 'package:hentai_library/features/comic/domain/comic_metadata_normalization.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

part 'comic.freezed.dart';

/// Comic 投影型实体（ADR-0041）：Dart 侧只持构造不变式、状态迁移与规约。
///
/// 事务边界与「Comic 聚合写集」（`comics` + `comic_meta` + facet junction）、
/// 元数据字段锁合并的权威都在 Rust（ADR-0002 / ADR-0026）；
/// 本实体**不**在 Dart 复刻锁合并或写集校验。
@freezed
abstract class Comic with _$Comic {
  /// freezed 主构造器；业务代码请用 [Comic.restore]（恢复）或
  /// [Comic.createMetadata]（校验后创建）。
  factory Comic({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int resourceSize,
    required DateTime createdAt,
    required DateTime lastUpdatedAt,
    required String title,

    /// Author 引用投影（id + 显示名）；**不是** Author 聚合（ADR-0024/ADR-0034）。
    @Default(<AuthorRef>[]) List<AuthorRef> authors,
    @Default(ContentRating.unknown) ContentRating contentRating,
    @Default(<Tag>[]) List<Tag> tags,

    /// Ordered canonical English Language names; empty = unset.
    @Default(<String>[]) List<String> languages,

    /// Parody (IP / franchise) names; empty = none.
    @Default(<String>[]) List<String> parodies,

    /// Character names; empty = none.
    @Default(<String>[]) List<String> characters,
    required int pageCount,
    String? description,
    DateTime? publishedAt,
    DateTime? lastReadTime,
    @Default(ComicMetaLocks.unlocked) ComicMetaLocks locks,
  }) = _Comic;

  const Comic._();

  /// 恢复入口：FRB 映射与测试夹具。
  ///
  /// 不做业务校验；用于还原 Rust 已持久化的事实（与既有测试夹具）。
  static Comic restore({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int resourceSize,
    required DateTime createdAt,
    required DateTime lastUpdatedAt,
    required String title,
    required int pageCount,
    List<AuthorRef> authors = const <AuthorRef>[],
    ContentRating contentRating = ContentRating.unknown,
    List<Tag> tags = const <Tag>[],
    List<String> languages = const <String>[],
    List<String> parodies = const <String>[],
    List<String> characters = const <String>[],
    String? description,
    DateTime? publishedAt,
    DateTime? lastReadTime,
    ComicMetaLocks locks = ComicMetaLocks.unlocked,
  }) {
    return Comic(
      comicId: comicId,
      path: path,
      resourceType: resourceType,
      resourceSize: resourceSize,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt,
      title: title,
      pageCount: pageCount,
      authors: authors,
      contentRating: contentRating,
      tags: tags,
      languages: languages,
      parodies: parodies,
      characters: characters,
      description: description,
      publishedAt: publishedAt,
      lastReadTime: lastReadTime,
      locks: locks,
    );
  }

  /// 创建入口：真实用户写的元数据构造，执行标题非空与 facet 名称规范化。
  static Comic createMetadata({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int resourceSize,
    required DateTime createdAt,
    required DateTime lastUpdatedAt,
    required String title,
    required int pageCount,
    String? description,
    DateTime? publishedAt,
    ContentRating contentRating = ContentRating.unknown,
    List<AuthorRef> authors = const <AuthorRef>[],
    List<Tag> tags = const <Tag>[],
    List<String> languages = const <String>[],
    List<String> parodies = const <String>[],
    List<String> characters = const <String>[],
    DateTime? lastReadTime,
    ComicMetaLocks locks = ComicMetaLocks.unlocked,
  }) {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', '漫画标题不能为空');
    }
    return Comic.restore(
      comicId: comicId,
      path: path,
      resourceType: resourceType,
      resourceSize: resourceSize,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt,
      title: trimmedTitle,
      pageCount: pageCount,
      description: normalizeOptionalMetadataText(description),
      publishedAt: publishedAt,
      contentRating: contentRating,
      authors: List<AuthorRef>.unmodifiable(authors),
      tags: List<Tag>.unmodifiable(tags),
      languages: normalizeOrderedFacetNames(languages),
      parodies: normalizeOrderedFacetNames(parodies),
      characters: normalizeOrderedFacetNames(characters),
      lastReadTime: lastReadTime,
      locks: locks,
    );
  }

  /// 把已规范化的元数据草稿应用到实体；标题非法时抛 [ArgumentError]。
  Comic applyMetadataDraft(ComicMetadataForm draft) {
    final ComicMetadataForm ready = draft.normalized;
    final ComicMetadataFormValidation validation = ready.validate();
    if (!validation.isValid) {
      throw ArgumentError.value(draft.title, 'draft', validation.titleError);
    }
    return copyWith(
      title: ready.title,
      description: ready.description,
      publishedAt: ready.publishedAt,
      contentRating: ready.isR18 ? ContentRating.r18 : ContentRating.safe,
      authors: ready.authors,
      tags: ready.tags,
      languages: ready.languages,
      parodies: ready.parodies,
      characters: ready.characters,
    );
  }

  /// 相对本实体（原值）的同步差异：校验失败、无变化，或仅含待提交字段。
  ComicMetadataDraftDiff metadataDiffAgainst(ComicMetadataForm draft) {
    final ComicMetadataForm ready = draft.normalized;
    final ComicMetadataFormValidation validation = ready.validate();
    if (!validation.isValid) {
      return ComicMetadataDraftInvalid(validation);
    }

    final String? title = ready.title != this.title ? ready.title : null;
    final String? description = ready.description != this.description
        ? (ready.description ?? '')
        : null;

    final DateTime? publishedAt;
    final bool clearPublishedAt;
    if (ready.publishedAt == this.publishedAt) {
      publishedAt = null;
      clearPublishedAt = false;
    } else if (ready.publishedAt == null) {
      publishedAt = null;
      clearPublishedAt = true;
    } else {
      publishedAt = ready.publishedAt;
      clearPublishedAt = false;
    }

    final bool originalIsR18 = contentRating == ContentRating.r18;
    final ContentRating? changedContentRating = ready.isR18 != originalIsR18
        ? (ready.isR18 ? ContentRating.r18 : ContentRating.safe)
        : null;

    final List<AuthorRef>? authors =
        !sameOrderedFacetNames(
          ready.authors.map((AuthorRef a) => a.name),
          this.authors.map((AuthorRef a) => a.name),
        )
        ? ready.authors
        : null;
    final List<Tag>? tags =
        !sameOrderedFacetNames(
          ready.tags.map((Tag t) => t.name),
          this.tags.map((Tag t) => t.name),
        )
        ? ready.tags
        : null;
    final List<String>? languages =
        !sameOrderedFacetNames(ready.languages, this.languages)
        ? ready.languages
        : null;
    final List<String>? parodies =
        !sameOrderedFacetNames(ready.parodies, this.parodies)
        ? ready.parodies
        : null;
    final List<String>? characters =
        !sameOrderedFacetNames(ready.characters, this.characters)
        ? ready.characters
        : null;

    final bool hasChanges =
        title != null ||
        description != null ||
        publishedAt != null ||
        clearPublishedAt ||
        changedContentRating != null ||
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
      contentRating: changedContentRating,
      authors: authors,
      tags: tags,
      languages: languages,
      parodies: parodies,
      characters: characters,
    );
  }
}

DateTime comicTimestampFromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

int comicTimestampToMs(DateTime dateTime) =>
    dateTime.toUtc().millisecondsSinceEpoch;
