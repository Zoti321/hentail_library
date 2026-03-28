import 'package:hentai_library/domain/entity/comic/library_series.dart';

import 'package:hentai_library/presentation/providers/v2/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<LibrarySeries>> librarySeriesStream(Ref ref) {
  return ref.watch(librarySeriesRepoProvider).watchAll();
}

@Riverpod(keepAlive: true)
class LibrarySeriesActions extends _$LibrarySeriesActions {
  @override
  void build() {}

  Future<void> create(String name) =>
      ref.read(librarySeriesRepoProvider).create(name);

  Future<void> rename(String id, String name) =>
      ref.read(librarySeriesRepoProvider).rename(id, name);

  Future<void> delete(String id) =>
      ref.read(librarySeriesRepoProvider).delete(id);

  Future<void> assignComic({
    required String comicId,
    required String targetSeriesId,
    required int order,
  }) {
    return ref
        .read(librarySeriesRepoProvider)
        .assignComicExclusive(
          comicId: comicId,
          targetSeriesId: targetSeriesId,
          order: order,
        );
  }

  Future<void> removeComic(String comicId) =>
      ref.read(librarySeriesRepoProvider).removeComic(comicId);
}
