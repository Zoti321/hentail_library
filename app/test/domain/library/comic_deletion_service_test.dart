import 'package:hentai_library/domain/library/comic_deletion_service.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
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

class _RecordingReadingHistoryRepository implements ReadingHistoryRepository {
  final List<String> deletedIds = <String>[];

  @override
  Future<void> deleteByComicIds(Iterable<String> comicIds) async {
    deletedIds.addAll(comicIds);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingReaderSessionPort implements ReaderSessionPort {
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingComicRepository comicRepo;
  late _RecordingReadingHistoryRepository historyRepo;
  late _RecordingReaderSessionPort sessionPort;
  late ComicDeletionService service;

  setUp(() {
    comicRepo = _RecordingComicRepository();
    historyRepo = _RecordingReadingHistoryRepository();
    sessionPort = _RecordingReaderSessionPort();
    service = ComicDeletionService(
      comicRepository: comicRepo,
      readingHistoryRepository: historyRepo,
      readerSessionPort: sessionPort,
    );
  });

  test('deleteComics is no-op for empty ids', () async {
    await service.deleteComics(const <String>[]);

    expect(historyRepo.deletedIds, isEmpty);
    expect(comicRepo.deletedIds, isEmpty);
    expect(sessionPort.clearCount, 0);
  });

  test('deleteComics clears history, comics, and reader sessions', () async {
    await service.deleteComics(<String>['c1', 'c2']);

    expect(historyRepo.deletedIds, <String>['c1', 'c2']);
    expect(comicRepo.deletedIds, <String>['c1', 'c2']);
    expect(sessionPort.clearCount, 1);
  });
}
