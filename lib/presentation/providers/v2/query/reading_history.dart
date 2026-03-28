import 'package:hentai_library/domain/entity/reading_history.dart' as entity;

import 'package:hentai_library/presentation/providers/v2/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_history.g.dart';

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
