import 'package:hentai_library/domain/library/comic_deletion_service.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:test/test.dart';

class _RecordingComicRepository implements ComicRepository {
  final List<String> deletedIds = <String>[];

  @override
  Future<void> deleteByIds(List<String> comicIds) async {
    deletedIds.addAll(comicIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingReaderSessionPort implements ReaderSessionPort {
  final List<String> closedComicIds = <String>[];

  @override
  Future<void> closeComic(String comicId) async {
    closedComicIds.add(comicId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingComicRepository comicRepo;
  late _RecordingReaderSessionPort sessionPort;
  late ComicDeletionService service;

  setUp(() {
    comicRepo = _RecordingComicRepository();
    sessionPort = _RecordingReaderSessionPort();
    service = ComicDeletionService(
      comicRepository: comicRepo,
      readerSessionPort: sessionPort,
    );
  });

  test('deleteComics is no-op for empty ids', () async {
    await service.deleteComics(const <String>[]);

    expect(comicRepo.deletedIds, isEmpty);
    expect(sessionPort.closedComicIds, isEmpty);
  });

  test('deleteComics closes reader sessions before deleting comics', () async {
    await service.deleteComics(<String>['c1', 'c2']);

    expect(sessionPort.closedComicIds, <String>['c1', 'c2']);
    expect(comicRepo.deletedIds, <String>['c1', 'c2']);
  });
}
