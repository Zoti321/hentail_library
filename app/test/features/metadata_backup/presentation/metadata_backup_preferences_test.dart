import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_preferences_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_preferences_provider.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_repository_provider.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_last_auto_backup_notifier.dart';

void main() {
  late _Preferences preferences;
  late _Files files;
  late ProviderContainer container;
  var disposed = false;

  setUp(() {
    preferences = _Preferences();
    disposed = false;
    files = _Files();
    container = ProviderContainer(
      overrides: [
        metadataBackupPreferencesRepositoryProvider.overrideWithValue(
          preferences,
        ),
        metadataBackupRepositoryProvider.overrideWithValue(_Repository()),
        metadataBackupFileGatewayProvider.overrideWithValue(files),
      ],
    );
    addTearDown(() {
      if (!disposed) container.dispose();
    });
  });

  test('enabled preference preserves optimistic updates and propagates write errors', () async {
    expect(await container.read(metadataAutoBackupProvider.future), isTrue);
    preferences.fail = true;
    await expectLater(
      container.read(metadataAutoBackupProvider.notifier).setEnabled(false),
      throwsStateError,
    );
    expect(container.read(metadataAutoBackupProvider).requireValue, isFalse);
    expect(preferences.enabled, isTrue);
  });

  test(
    'completion writes without constructing a last-backup notifier',
    () async {
      expect(container.exists(metadataLastAutoBackupProvider), isFalse);
      final at = DateTime(2026, 11, 13, 10);
      await container.read(runMetadataAutoBackupUseCaseProvider)(
        enabled: true,
        fromStartup: false,
        now: () => at,
      );
      expect(preferences.last, at);
      expect(preferences.loads, 0);
      expect(files.calls, ['write', 'prune']);
      expect(await container.read(metadataLastAutoBackupProvider.future), at);
    },
  );

  for (final disposeContainer in [false, true]) {
    for (final holdCompletion in [false, true]) {
      test(
        'accepted backup completes after ${disposeContainer ? 'container disposal' : 'provider invalidation'} during ${holdCompletion ? 'completion persistence' : 'file write'}',
        () async {
          final at = DateTime(2026, 11, 13, 10);
          final release = Completer<void>();
          final entered = Completer<void>();
          if (holdCompletion) {
            preferences.pending = release.future;
            preferences.recording = entered;
          } else {
            files.pendingWrite = release.future;
            files.writing = entered;
          }
          final useCase = container.read(runMetadataAutoBackupUseCaseProvider);
          final run = useCase(enabled: true, fromStartup: false, now: () => at);
          await entered.future;
          if (disposeContainer) {
            container.dispose();
            disposed = true;
          } else {
            container.invalidate(runMetadataAutoBackupUseCaseProvider);
            await container.pump();
            expect(
              container.read(runMetadataAutoBackupUseCaseProvider),
              isNot(same(useCase)),
            );
          }
          release.complete();
          await run;
          expect(preferences.last, at);
          expect(files.calls, ['write', 'prune']);
          expect(preferences.records, 1);
        },
      );
    }
  }

  test('completion becomes visible only after persistence and failures preserve previous success', () async {
    final previous = await container.read(
      metadataLastAutoBackupProvider.future,
    );
    final at = DateTime(2026, 11, 13, 10);
    final pending = Completer<void>();
    preferences.pending = pending.future;
    final run = container.read(runMetadataAutoBackupUseCaseProvider);
    final write = run(enabled: true, fromStartup: false, now: () => at);
    await Future<void>.delayed(Duration.zero);
    expect(files.calls, ['write', 'prune']);
    expect(
      container.read(metadataLastAutoBackupProvider).requireValue,
      previous,
    );
    pending.complete();
    await write;
    expect(await container.read(metadataLastAutoBackupProvider.future), at);

    preferences.fail = true;
    final next = at.add(const Duration(hours: 1));
    await expectLater(
      run(enabled: true, fromStartup: false, now: () => next),
      throwsStateError,
    );
    expect(container.read(metadataLastAutoBackupProvider).requireValue, at);
    expect(preferences.last, at);
    preferences.fail = false;
    await run(enabled: true, fromStartup: false, now: () => next);
    expect(await container.read(metadataLastAutoBackupProvider.future), next);
  });
}

class _Preferences implements MetadataBackupPreferencesRepository {
  var enabled = true;
  DateTime? last = DateTime(2026, 11, 12);
  var loads = 0;
  var fail = false;
  Future<void>? pending;
  Completer<void>? recording;
  var records = 0;

  @override
  Future<bool> loadEnabled() async => enabled;

  @override
  Future<void> saveEnabled(bool value) async {
    if (fail) throw StateError('preferences unavailable');
    enabled = value;
  }

  @override
  Future<DateTime?> loadLastBackupAt() async {
    loads++;
    return last;
  }

  @override
  Future<void> recordBackup(DateTime at) async {
    records++;
    recording?.complete();
    await pending;
    if (fail) throw StateError('preferences unavailable');
    last = at;
  }
}

class _Repository implements MetadataBackupRepository {
  @override
  Uint8List exportComicMetadata({
    String? libraryId,
    required bool includeOrphanFacets,
  }) => Uint8List(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Files implements MetadataBackupFileGateway {
  final calls = <String>[];
  Future<void>? pendingWrite;
  Completer<void>? writing;

  @override
  Future<String> prepareBackupDirectory() async => 'isolated';
  @override
  String backupPath(String directory, String fileName) => fileName;
  @override
  Future<List<int>> compress(Uint8List bytes) async => bytes;
  @override
  Future<void> write(String path, List<int> bytes) async {
    calls.add('write');
    writing?.complete();
    await pendingWrite;
  }

  @override
  void prune(String directory, {required int maxFiles}) {
    calls.add('prune');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
