import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/application/logging/app_log.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_auto_backup_logic.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_last_auto_backup_notifier.dart';
import 'package:hentai_library/core/util/debouncer.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_revisions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_auto_backup_coordinator_notifier.g.dart';

@Riverpod(keepAlive: true)
class MetadataAutoBackupCoordinatorNotifier
    extends _$MetadataAutoBackupCoordinatorNotifier {
  Debouncer? _metadataSaveDebouncer;
  bool _startupScheduled = false;
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
    ref.listen<int>(
      domainEventRevisionsProvider.select(
        (DomainEventRevisionsState s) => s.metadataSaveRevision,
      ),
      (int? previous, int next) {
        if (previous != null && previous != next) {
          _onMetadataSaved();
        }
      },
    );
    _scheduleStartupBackupCheck();
  }

  void _onMetadataSaved() {
    final bool enabled =
        ref.read(metadataAutoBackupProvider).asData?.value ?? true;
    if (!enabled) {
      return;
    }
    _metadataSaveDebouncer ??= Debouncer(
      duration: metadataAutoBackupSaveDebounce,
    );
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
    if (!ref.mounted) {
      return;
    }
    try {
      final lastBackupAt = await ref.read(
        metadataLastAutoBackupProvider.future,
      );
      if (!ref.mounted) {
        return;
      }
      final enabled = await ref.read(metadataAutoBackupProvider.future);
      if (!ref.mounted) {
        return;
      }
      await ref.read(runMetadataAutoBackupUseCaseProvider)(
        enabled: enabled,
        fromStartup: fromStartup,
        force: force,
        lastBackupAt: lastBackupAt,
        now: _now,
      );
    } catch (e, st) {
      logError(AppLog.core('metadata_backup'), '自动元数据备份失败', e, st);
    }
  }
}
