import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/application/comic_metadata_service.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/features/comic/di/comic_repository_providers.dart';

/// 元数据保存用例的命令签名（presentation 只依赖本 typedef，不接触总线）。
typedef ComicMetadataApplyCommand = Future<ComicMetadataApplyResult> Function(
  ComicMetadataForm form,
  Comic original,
);

/// 装配 [applyComicMetadataForm]：仓储与 [`DomainEventPublisher`] 在此绑定，
/// 使 presentation 不直接读取 `domainEventBusProvider`（ADR-0039 §3 / E5）。
final Provider<ComicMetadataApplyCommand> comicMetadataApplyCommandProvider =
    Provider<ComicMetadataApplyCommand>((Ref ref) {
      return (ComicMetadataForm form, Comic original) {
        return applyComicMetadataForm(
          ref.read(comicUserMetadataRepositoryProvider),
          form,
          original,
          events: ref.read(domainEventBusProvider),
        );
      };
    });
