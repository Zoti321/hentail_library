import 'package:hentai_library/features/series/domain/value_objects/series_folder_info.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata.dart';

import 'dart:async';

import 'package:hentai_library/features/series/domain/series.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';
import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_edit_session_notifier.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_edit_ui_state.dart';
import 'package:hentai_library/features/series/public/providers/series_repository_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class _Repository implements SeriesRepository {
  final write = Completer<void>();
  final lock = Completer<void>();
  final writes = <({String id, String? name})>[];
  final locks = <({String id, bool? name})>[];

  @override
  Future<void> updateUserMeta({
    required String seriesId,
    String? name,
    SerializationStatus? serializationStatus,
    int? totalCount,
    bool clearTotalCount = false,
  }) {
    writes.add((id: seriesId, name: name));
    return write.future;
  }

  @override
  Future<void> setMetaLocks({
    required String seriesId,
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) {
    locks.add((id: seriesId, name: name));
    return lock.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Series _series() => Series(
  id: 'series-1',
  folderInfo: SeriesFolderInfo(folderPath: '/library/series'),
  metadata: SeriesMetadata(name: 'Original series'),
);

void main() {
  test('mounted session updates lock, validation and save state', () async {
    final repository = _Repository();
    final series = _series();
    final container = ProviderContainer(
      overrides: [seriesRepoProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final provider = seriesMetadataEditSessionProvider(series);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final session = container.read(provider.notifier);
    final locking = session.setLock(name: true);
    expect(container.read(provider).locks.name, isFalse);
    repository.lock.complete();
    await locking;
    expect(container.read(provider).locks.name, isTrue);
    session.updateDraft(container.read(provider).draft.copyWith(name: ''));
    expect(await session.save(), SeriesMetadataEditSaveResult.validationFailed);
    expect(container.read(provider).nameError, isNotNull);
    expect(container.read(provider).saving, isFalse);
    session.updateDraft(
      container.read(provider).draft.copyWith(name: 'Saved series'),
    );
    expect(container.read(provider).nameError, isNull);
    final saving = session.save();
    expect(container.read(provider).saving, isTrue);
    repository.write.complete();
    expect(await saving, SeriesMetadataEditSaveResult.succeeded);
    expect(container.read(provider).saving, isFalse);
    expect(repository.writes, [(id: series.id, name: 'Saved series')]);
    expect(repository.locks, [(id: series.id, name: true)]);
  });

  for (final disposal in ['container', 'listener']) {
    for (final fails in [false, true]) {
      test(
        'pending save ${fails ? 'failure' : 'success'} survives $disposal disposal',
        () async {
          final repository = _Repository();
          final failure = StateError('original write failure');
          final series = _series();
          final container = ProviderContainer(
            overrides: [seriesRepoProvider.overrideWithValue(repository)],
          );
          var disposed = false;
          addTearDown(() {
            if (!disposed) container.dispose();
          });
          final provider = seriesMetadataEditSessionProvider(series);
          final subscription = container.listen(provider, (_, _) {});
          final session = container.read(provider.notifier);
          session.updateDraft(
            container.read(provider).draft.copyWith(name: 'Saved series'),
          );
          final saving = session.save();
          expect(container.read(provider).saving, isTrue);
          expect(await session.save(), SeriesMetadataEditSaveResult.busy);
          final observed = expectLater(
            saving,
            fails
                ? throwsA(same(failure))
                : completion(SeriesMetadataEditSaveResult.succeeded),
          );
          if (disposal == 'container') {
            container.dispose();
            disposed = true;
          } else {
            subscription.close();
            await container.pump();
          }
          if (fails) {
            repository.write.completeError(failure);
          } else {
            repository.write.complete();
          }
          await observed;
          expect(repository.writes, [(id: series.id, name: 'Saved series')]);
          expect(repository.locks, isEmpty);
        },
      );

      test(
        'pending lock ${fails ? 'failure' : 'success'} survives $disposal disposal',
        () async {
          final repository = _Repository();
          final failure = StateError('original lock failure');
          final series = _series();
          final container = ProviderContainer(
            overrides: [seriesRepoProvider.overrideWithValue(repository)],
          );
          var disposed = false;
          addTearDown(() {
            if (!disposed) container.dispose();
          });
          final provider = seriesMetadataEditSessionProvider(series);
          final subscription = container.listen(provider, (_, _) {});
          final session = container.read(provider.notifier);
          final locking = session.setLock(name: true);
          final observed = expectLater(
            locking,
            fails ? throwsA(same(failure)) : completes,
          );
          if (disposal == 'container') {
            container.dispose();
            disposed = true;
          } else {
            subscription.close();
            await container.pump();
          }
          if (fails) {
            repository.lock.completeError(failure);
          } else {
            repository.lock.complete();
          }
          await observed;
          expect(repository.locks, [(id: series.id, name: true)]);
          expect(repository.writes, isEmpty);
        },
      );
    }
  }

  test(
    'validation result survives disposal without writing metadata',
    () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [seriesRepoProvider.overrideWithValue(repository)],
      );
      final series = _series();
      final provider = seriesMetadataEditSessionProvider(series);
      container.listen(provider, (_, _) {});
      final session = container.read(provider.notifier);
      session.updateDraft(container.read(provider).draft.copyWith(name: ''));
      final saving = session.save();
      container.dispose();
      await expectLater(
        saving,
        completion(SeriesMetadataEditSaveResult.validationFailed),
      );
      expect(repository.writes, isEmpty);
      expect(repository.locks, isEmpty);
    },
  );
}
