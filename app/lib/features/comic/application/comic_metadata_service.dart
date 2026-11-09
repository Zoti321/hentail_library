import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/features/comic/domain/comic_user_metadata_repository.dart';

/// 浏览侧保存 Comic 元数据草稿的结果。仓储异常仍向上抛，由 UI toast。
sealed class ComicMetadataApplyResult {
  const ComicMetadataApplyResult();
}

final class ComicMetadataApplyInvalid extends ComicMetadataApplyResult {
  const ComicMetadataApplyInvalid(this.validation);

  final ComicMetadataFormValidation validation;
}

final class ComicMetadataApplySucceeded extends ComicMetadataApplyResult {
  const ComicMetadataApplySucceeded({
    this.persisted = false,
    this.tagsWritten = false,
    this.parodiesWritten = false,
    this.charactersWritten = false,
  });

  /// 本次是否实际调用了仓储写入（无字段变化时为 false）。
  final bool persisted;

  /// 本次是否向仓储提交了 Tag 列表（可能写入全局 Tag 字典）。
  final bool tagsWritten;

  /// 本次是否向仓储提交了 Parody 列表（可能写入全局 Parody 字典）。
  final bool parodiesWritten;

  /// 本次是否向仓储提交了 Character 列表（可能写入全局 Character 字典）。
  final bool charactersWritten;
}

/// 按草稿相对原 Comic 的差异写入用户元数据，并发布 [ComicMetadataPersisted]。
Future<ComicMetadataApplyResult> applyComicMetadataForm(
  ComicUserMetadataRepository repository,
  ComicMetadataForm form,
  Comic original, {
  required DomainEventPublisher events,
}) async {
  switch (form.diffAgainst(original)) {
    case ComicMetadataDraftInvalid(:final validation):
      return ComicMetadataApplyInvalid(validation);
    case ComicMetadataDraftUnchanged():
      return const ComicMetadataApplySucceeded();
    case ComicMetadataDraftChanges(
      :final title,
      :final description,
      :final publishedAt,
      :final clearPublishedAt,
      :final authors,
      :final contentRating,
      :final tags,
      :final languages,
      :final parodies,
      :final characters,
    ):
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
        parodies: parodies,
        characters: characters,
      );
      events.publish(
        ComicMetadataPersisted(
          tagsWritten: tags != null,
          parodiesWritten: parodies != null,
          charactersWritten: characters != null,
        ),
      );
      return ComicMetadataApplySucceeded(
        persisted: true,
        tagsWritten: tags != null,
        parodiesWritten: parodies != null,
        charactersWritten: characters != null,
      );
  }
}
