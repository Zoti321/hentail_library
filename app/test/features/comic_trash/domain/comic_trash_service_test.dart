import 'package:hentai_library/features/comic_trash/domain/comic_trash_service.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:test/test.dart';

class _RecordingComicRepository implements ComicRepository {
  final List<String> calls = <String>[];
  List<String> trashedIds = <String>[];

  @override
  Future<void> trashByIds(List<String> comicIds) async {
    calls.add('trash:${comicIds.join(',')}');
  }

  @override
  Future<void> restoreByIds(List<String> comicIds) async {
    calls.add('restore:${comicIds.join(',')}');
  }

  @override
  Future<ComicPurgeResult> purgeByIds(List<String> comicIds) async {
    calls.add('purge:${comicIds.join(',')}');
    return (
      succeeded: comicIds.length,
      failed: 0,
      errorSamples: const <String>[],
    );
  }

  @override
  Future<List<String>> listTrashedIds() async => trashedIds;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingReaderSessionPort implements ReaderSessionPort {
  _RecordingReaderSessionPort(this.calls);

  final List<String> calls;

  @override
  Future<void> closeComic(String comicId) async {
    calls.add('close:$comicId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingComicRepository comicRepo;
  late ComicTrashService service;

  setUp(() {
    comicRepo = _RecordingComicRepository();
    service = ComicTrashService(
      comicRepository: comicRepo,
      readerSessionPort: _RecordingReaderSessionPort(comicRepo.calls),
    );
  });

  test('empty ids are no-ops for trash / restore / purge', () async {
    await service.trashComics(const <String>[]);
    await service.restoreComics(const <String>[]);
    final ComicPurgeResult result = await service.purgeComics(const <String>[]);

    expect(comicRepo.calls, isEmpty);
    expect(result.succeeded, 0);
    expect(result.failed, 0);
  });

  test('trashComics closes reader sessions before trashing', () async {
    await service.trashComics(<String>['c1', 'c2', 'c1']);

    expect(comicRepo.calls, <String>['close:c1', 'close:c2', 'trash:c1,c2']);
  });

  test('restoreComics does not touch reader sessions', () async {
    await service.restoreComics(<String>['c1']);

    expect(comicRepo.calls, <String>['restore:c1']);
  });

  test('purgeComics closes sessions then purges', () async {
    final ComicPurgeResult result = await service.purgeComics(<String>['c1']);

    expect(comicRepo.calls, <String>['close:c1', 'purge:c1']);
    expect(result.succeeded, 1);
  });
}
