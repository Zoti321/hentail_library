import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_page_notifier.g.dart';

@Riverpod(keepAlive: true)
Stream<List<entity.ReadingHistory>> readingHistoryStream(Ref ref) {
  return ref.watch(readingHistoryRepoProvider).watchAllHistory();
}
