import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/presentation/providers/core/core_providers.dart';
import 'package:hentai_library/data/repository/reading_history_repo.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_history_providers.g.dart';

@Riverpod(keepAlive: true)
ReadingHistoryRepository readingHistoryRepo(Ref ref) =>
    ReadingHistoryRepositoryImpl(ReadingHistoryDao(ref.read(databaseProvider)));

@Riverpod()
Stream<List<entity.ReadingHistory>> readingHistoryStream(Ref ref) {
  return ref.watch(readingHistoryRepoProvider).watchAllHistory();
}

@Riverpod()
Future<entity.ReadingHistory?> readingProgress(
  Ref ref, {
  required String comicId,
}) async {
  final repo = ref.watch(readingHistoryRepoProvider);
  return repo.getByComicId(comicId);
}
