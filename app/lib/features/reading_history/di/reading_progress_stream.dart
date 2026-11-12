import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/public/di/reading_history_repository_providers.dart';

Stream<Map<String, int>> createReadingHistoryProgressStream(Ref ref) async* {
  final repo = ref.read(readingHistoryRepoProvider);
  yield await repo.listReadPageIndexes();
  await for (final _ in repo.watchHistoryChanges()) {
    yield await repo.listReadPageIndexes();
  }
}
