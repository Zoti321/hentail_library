import 'package:hentai_library/composition/modules/reading_history/reading_progress_stream.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/test.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/presentation/providers/reading_history_providers.dart';

class _Repository implements ReadingHistoryRepository {
  int reads = 0;
  int watches = 0;
  bool fail = false;
  final changes = StreamController<void>();
  @override
  Future<Map<String, int>> listReadPageIndexes() async {
    reads++;
    if (fail) throw StateError('read');
    return {'c': reads};
  }

  @override
  Stream<void> watchHistoryChanges() {
    watches++;
    return changes.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('two consumers share initial read and updates, forward errors and cancel on dispose', () async {
    final repo = _Repository();
    final cancelled = Completer<void>();
    repo.changes.onCancel = cancelled.complete;
    final container = ProviderContainer(
      overrides: [
        readingHistoryRepoProvider.overrideWithValue(repo),
        readingHistoryProgressProvider.overrideWith(
          createReadingHistoryProgressStream,
        ),
      ],
    );
    final updated = Completer<void>();
    final failed = Completer<void>();
    final first = container.listen(readingHistoryProgressProvider, (_, next) {
      if (next.asData?.value['c'] == 2 && !updated.isCompleted) {
        updated.complete();
      }
      if (next.hasError && !failed.isCompleted) failed.complete();
    });
    final second = container.listen(
      readingHistoryProgressProvider,
      (_, next) {},
    );
    expect(await container.read(readingHistoryProgressProvider.future), {
      'c': 1,
    });
    await Future<void>.delayed(Duration.zero);
    expect(repo.watches, 1);
    repo.changes.add(null);
    await updated.future;
    expect(repo.reads, 2);
    repo.fail = true;
    repo.changes.add(null);
    await failed.future;
    first.close();
    second.close();
    container.dispose();
    await cancelled.future;
    await repo.changes.close();
  });
}
