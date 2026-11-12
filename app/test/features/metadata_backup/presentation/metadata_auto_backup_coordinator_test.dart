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
  @override
  Future<void> call({
    required bool enabled,
    required bool fromStartup,
    bool force = false,
    DateTime? lastBackupAt,
    DateTime Function()? now,
  }) async {
    calls.add((startup: fromStartup, force: force));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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
