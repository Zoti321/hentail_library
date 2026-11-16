import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';
import 'package:hentai_library/features/metadata_backup/application/run_metadata_auto_backup_use_case.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_auto_backup_logic.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_coordinator_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_last_auto_backup_notifier.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_preferences_repository.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_preferences_provider.dart';
import 'package:logging/logging.dart';

class _Preferences implements MetadataBackupPreferencesRepository {
  final enabled = Completer<bool>();
  final lastBackup = Completer<DateTime?>();

  @override
  Future<bool> loadEnabled() => enabled.future;

  @override
  Future<void> saveEnabled(bool enabled) async {}

  @override
  Future<DateTime?> loadLastBackupAt() => lastBackup.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Enabled extends MetadataAutoBackupNotifier {
  @override
  Future<bool> build() async => true;
}

class _LastBackup extends MetadataLastAutoBackupNotifier {
  @override
  Future<DateTime?> build() async => null;
}

class _Run implements RunMetadataAutoBackupUseCase {
  final calls = <({bool startup, bool force})>[];
  final preferences = <({bool enabled, DateTime? lastBackupAt})>[];
  @override
  Future<void> call({
    required bool enabled,
    required bool fromStartup,
    bool force = false,
    DateTime? lastBackupAt,
    DateTime Function()? now,
  }) async {
    calls.add((startup: fromStartup, force: force));
    preferences.add((enabled: enabled, lastBackupAt: lastBackupAt));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('uses disabled preference changed while last backup loads', (
    tester,
  ) async {
    final prefs = _Preferences();
    prefs.enabled.complete(true);
    final run = _Run();
    final container = ProviderContainer(
      overrides: [
        ...domainEventBusOverrides(),
        metadataBackupPreferencesRepositoryProvider.overrideWithValue(prefs),
        runMetadataAutoBackupUseCaseProvider.overrideWithValue(run),
      ],
    );
    addTearDown(container.dispose);
    await container.read(metadataAutoBackupProvider.future);
    container.read(metadataAutoBackupCoordinatorProvider);
    await tester.pumpWidget(const SizedBox());
    expect(run.calls, isEmpty);
    await container.read(metadataAutoBackupProvider.notifier).setEnabled(false);
    prefs.lastBackup.complete(null);
    await tester.pump();
    expect(run.preferences, [(enabled: false, lastBackupAt: null)]);
  });

  testWidgets(
    'preference failure reports original error without starting backup',
    (tester) async {
      final prefs = _Preferences();
      final run = _Run();
      final errors = <LogRecord>[];
      final logs = Logger.root.onRecord.listen((record) {
        if (record.level >= Level.SEVERE) errors.add(record);
      });
      addTearDown(logs.cancel);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          ...domainEventBusOverrides(),
          metadataBackupPreferencesRepositoryProvider.overrideWithValue(prefs),
          runMetadataAutoBackupUseCaseProvider.overrideWithValue(run),
        ],
      );
      addTearDown(container.dispose);
      container.read(metadataAutoBackupCoordinatorProvider);
      await tester.pumpWidget(const SizedBox());
      prefs.lastBackup.complete(null);
      await tester.pump();
      final error = StateError('preferences unavailable');
      prefs.enabled.completeError(error);
      await tester.pump();
      expect(run.calls, isEmpty);
      expect(errors, hasLength(1));
      expect(errors.single.error, same(error));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('startup waits for persisted scheduling preferences', (
    tester,
  ) async {
    final prefs = _Preferences();
    final run = _Run();
    final container = ProviderContainer(
      overrides: [
        ...domainEventBusOverrides(),
        metadataBackupPreferencesRepositoryProvider.overrideWithValue(prefs),
        runMetadataAutoBackupUseCaseProvider.overrideWithValue(run),
      ],
    );
    addTearDown(container.dispose);
    container.read(metadataAutoBackupCoordinatorProvider);
    await tester.pumpWidget(const SizedBox());
    expect(run.calls, isEmpty);
    prefs.enabled.complete(false);
    await tester.pump();
    expect(run.calls, isEmpty);
    final at = DateTime(2026, 11, 13);
    prefs.lastBackup.complete(at);
    await tester.pump();
    expect(run.preferences, [(enabled: false, lastBackupAt: at)]);
    await container
        .read(metadataAutoBackupCoordinatorProvider.notifier)
        .backupNow();
    expect(run.calls.last, (startup: false, force: true));
    expect(run.preferences.last.enabled, isFalse);
  });

  for (final disposeDuringLoad in [false, true]) {
    testWidgets(
      'dispose cancels pending startup (loading: $disposeDuringLoad)',
      (tester) async {
        final prefs = _Preferences();
        final run = _Run();
        final errors = <LogRecord>[];
        final logs = Logger.root.onRecord.listen((record) {
          if (record.level >= Level.SEVERE) errors.add(record);
        });
        addTearDown(logs.cancel);
        final container = ProviderContainer(
          overrides: [
            ...domainEventBusOverrides(),
            metadataBackupPreferencesRepositoryProvider.overrideWithValue(
              prefs,
            ),
            runMetadataAutoBackupUseCaseProvider.overrideWithValue(run),
          ],
        );
        container.read(metadataAutoBackupCoordinatorProvider);
        if (disposeDuringLoad) await tester.pumpWidget(const SizedBox());
        container.dispose();
        prefs.enabled.complete(true);
        prefs.lastBackup.complete(null);
        await tester.pumpWidget(const SizedBox());
        expect(run.calls, isEmpty);
        expect(errors, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'startup, save debounce, force and dispose preserve integration timing',
    (tester) async {
      final run = _Run();
      final container = ProviderContainer(
        overrides: [
          ...domainEventBusOverrides(),
          metadataAutoBackupProvider.overrideWith(_Enabled.new),
          metadataLastAutoBackupProvider.overrideWith(_LastBackup.new),
          runMetadataAutoBackupUseCaseProvider.overrideWithValue(run),
        ],
      );
      await container.read(metadataAutoBackupProvider.future);
      await container.read(metadataLastAutoBackupProvider.future);
      container.read(metadataAutoBackupCoordinatorProvider);
      expect(run.calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
      expect(run.calls, [(startup: true, force: false)]);
      final events = container.read(domainEventBusProvider);
      events.publish(const ComicMetadataPersisted());
      await tester.pump(const Duration(minutes: 4));
      events.publish(const ComicMetadataPersisted());
      await tester.pump(const Duration(minutes: 4));
      expect(run.calls, hasLength(1));
      await tester.pump(const Duration(minutes: 1));
      expect(run.calls.last, (startup: false, force: false));
      expect(run.calls, hasLength(2));
      await container
          .read(metadataAutoBackupCoordinatorProvider.notifier)
          .backupNow();
      expect(run.calls.last, (startup: false, force: true));
      events.publish(const ComicMetadataPersisted());
      container.dispose();
      await tester.pump(metadataAutoBackupSaveDebounce);
      expect(run.calls, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );
}
