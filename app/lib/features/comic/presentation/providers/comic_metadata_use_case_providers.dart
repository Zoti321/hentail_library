import 'package:hentai_library/features/comic/application/save_comic_metadata_use_case.dart';
import 'package:hentai_library/features/comic/application/apply_comic_metadata_form_use_case.dart';
import 'package:hentai_library/shared/presentation/providers/series_item_sort_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_repository_providers.dart';

/// 元数据保存用例的命令签名（presentation 只依赖本 typedef，不接触总线）。
typedef ComicMetadataApplyCommand = Future<ComicMetadataApplyResult> Function(
  ComicMetadataForm form,
  Comic original,
);

/// 装配 [ApplyComicMetadataFormUseCase]：仓储与事件发布器在此绑定，
/// 使 presentation 不直接读取 `domainEventBusProvider`（ADR-0039 §3 / E5）。
final Provider<ComicMetadataApplyCommand> comicMetadataApplyCommandProvider =
    Provider<ComicMetadataApplyCommand>((Ref ref) {
      return (ComicMetadataForm form, Comic original) =>
          ApplyComicMetadataFormUseCase(
            repository: ref.read(comicUserMetadataRepositoryProvider),
            events: ref.read(domainEventBusProvider),
          )(form, original);
    });

final saveComicMetadataUseCaseProvider = Provider<SaveComicMetadataUseCase>(
  (ref) => SaveComicMetadataUseCase(
    apply: (form, original) =>
        ref.read(comicMetadataApplyCommandProvider)(form, original),
    persistSort: ref.read(persistSeriesItemSortCommandProvider),
  ),
);
