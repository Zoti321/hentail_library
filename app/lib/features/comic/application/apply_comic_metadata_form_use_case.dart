import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_user_metadata_repository.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

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

/// Applies metadata changes, persists them, then publishes the committed fact.
class ApplyComicMetadataFormUseCase {
  const ApplyComicMetadataFormUseCase({
    required this.repository,
    required this.events,
  });

  final ComicUserMetadataRepository repository;
  final DomainEventPublisher events;

  Future<ComicMetadataApplyResult> call(
    ComicMetadataForm form,
    Comic original,
  ) async {
    switch (original.metadataDiffAgainst(form)) {
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
          authors: authors?.map((AuthorRef author) => author.name).toList(),
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
}
