import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/core/metadata/metadata_auto_backup_logic.dart';
import 'package:hentai_library/core/metadata/metadata_auto_backup_service.dart';
import 'package:hentai_library/data/adapters/metadata_backup_frb_adapter.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_last_auto_backup_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/debouncer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_auto_backup_coordinator_notifier.g.dart';

@Riverpod(keepAlive: true)
class MetadataAutoBackupCoordinatorNotifier
    extends _$MetadataAutoBackupCoordinatorNotifier {
  Debouncer? _metadataSaveDebouncer;
  bool _startupScheduled = false;
  bool _backupInFlight = false;
  DateTime Function() _now = DateTime.now;

  @visibleForTesting
  set nowOverride(DateTime Function()? value) {
    _now = value ?? DateTime.now;
  }

  @override
  void build() {
    ref.onDispose(() {
      _metadataSaveDebouncer?.dispose();
    });
    _scheduleStartupBackupCheck();
  }

  void notifyMetadataSaved() {
    final bool enabled = ref.read(metadataAutoBackupProvider).asData?.value ??
        true;
    if (!enabled) {
      return;
    }
    _metadataSaveDebouncer ??=
        Debouncer(duration: metadataAutoBackupSaveDebounce);
    _metadataSaveDebouncer!.run(() {
      unawaited(_tryAutoBackup(fromStartup: false));
    });
  }

  Future<void> backupNow() async {
    await _tryAutoBackup(fromStartup: false, force: true);
  }

  void _scheduleStartupBackupCheck() {
    if (_startupScheduled) {
      return;
    }
    _startupScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      unawaited(_tryAutoBackup(fromStartup: true));
    });
  }

  Future<void> _tryAutoBackup({
    required bool fromStartup,
    bool force = false,
  }) async {
    if (_backupInFlight) {
      return;
    }

    final bool enabled = ref.read(metadataAutoBackupProvider).asData?.value ??
        true;
    if (!enabled && !force) {
      return;
    }

    if (!force && fromStartup) {
      final DateTime? lastBackup =
          ref.read(metadataLastAutoBackupProvider).asData?.value;
      if (!shouldRunStartupMetadataAutoBackup(
        now: _now(),
        lastBackupAt: lastBackup,
      )) {
        return;
      }
    }

    _backupInFlight = true;
    try {
      final MetadataAutoBackupRunResult result = await runMetadataAutoBackup(
        export: (options) =>
            const MetadataBackupFrbAdapter().export(options: options),
        now: _now,
      );
      await ref
          .read(metadataLastAutoBackupProvider.notifier)
          .recordBackup(result.completedAt);
    } catch (e, st) {
      logError(AppLog.core('metadata_backup'), '自动元数据备份失败', e, st);
    } finally {
      _backupInFlight = false;
    }
  }
}
