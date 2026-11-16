import 'package:hentai_library/shared/domain/models/enums.dart';

import 'dart:typed_data';

import 'package:hentai_library/features/comic/application/set_comic_cover.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_thumbnail_repository.dart';
import 'package:test/test.dart';

class _FakeThumbnailRepository implements ComicThumbnailRepository {
  final List<String> calls = <String>[];
  Uint8List? stored;

  @override
  Future<void> setComicCoverFromPage({
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int pageIndex,
  }) async {
    calls.add('set:$comicId:$path:${resourceType.name}:$pageIndex');
  }

  @override
  Future<ComicThumbnailRecord?> findByComicId(String comicId) async {
    final Uint8List? bytes = stored;
    if (bytes == null) {
      return null;
    }
    return (
      thumbnail: bytes,
      sourceModifiedMs: 0,
      sourceSize: 0,
      isUserSet: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeThumbnailRepository repo;

  setUp(() => repo = _FakeThumbnailRepository());

  test('writes the requested page and returns the stored thumbnail', () async {
    repo.stored = Uint8List.fromList(<int>[7, 8]);

    final Uint8List? bytes = await setComicCoverFromPage(
      repo,
      comicId: 'comic-1',
      path: '/library/comic-1.zip',
      resourceType: ResourceType.zip,
      pageIndex: 4,
    );

    expect(repo.calls, <String>['set:comic-1:/library/comic-1.zip:zip:4']);
    expect(bytes, <int>[7, 8]);
  });

  test('returns null when the repository has no thumbnail', () async {
    final Uint8List? bytes = await setComicCoverFromPage(
      repo,
      comicId: 'comic-2',
      path: '/library/comic-2.zip',
      resourceType: ResourceType.zip,
      pageIndex: 0,
    );

    expect(bytes, isNull);
  });
}
