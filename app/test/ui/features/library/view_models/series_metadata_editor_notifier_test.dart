import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/series_metadata_editor_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _RecordingSeriesRepository implements SeriesRepository {
  final List<({String seriesId, bool? name})> lockCalls =
      <({String seriesId, bool? name})>[];

  @override
  Future<void> setMetaLocks({
    required String seriesId,
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) async {
    lockCalls.add((seriesId: seriesId, name: name));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingSeriesRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _RecordingSeriesRepository();
    container = ProviderContainer(
      overrides: <Override>[seriesRepoProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  SeriesMetadataEditorNotifier editor() =>
      container.read(seriesMetadataEditorProvider.notifier);

  test('setLocks forwards the lock patch to the repository', () async {
    await editor().setLocks('series-1', name: true);

    expect(repo.lockCalls, <({String seriesId, bool? name})>[
      (seriesId: 'series-1', name: true),
    ]);
  });

  test(
    'apply without changes succeeds without touching the repository',
    () async {
      final Series series = Series(
        id: 'series-1',
        name: '系列',
        folderPath: '/library/series-1',
      );

      final SeriesMetadataApplyResult result = await editor().apply(
        SeriesMetadataForm.fromSeries(series),
        series,
      );

      expect(result, isA<SeriesMetadataApplySucceeded>());
      expect(repo.lockCalls, isEmpty);
    },
  );
}
