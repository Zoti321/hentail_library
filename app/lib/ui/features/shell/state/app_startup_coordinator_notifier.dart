import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_startup_coordinator_notifier.g.dart';

@Riverpod(keepAlive: true)
class AppStartupCoordinatorNotifier extends _$AppStartupCoordinatorNotifier {
  bool _didHandleStartupAutoScanPreference = false;
  int _autoScanScheduleToken = 0;
  bool _autoScanScheduled = false;

  @override
  bool build() {
    ref.watch(libraryRevisionProvider);
    ref.watch(thumbnailEventCoordinatorProvider);
    ref.onDispose(() {
      _autoScanScheduleToken++;
    });
    ref.listen<AsyncValue<AppSetting>>(settingsProvider, (
      AsyncValue<AppSetting>? previous,
      AsyncValue<AppSetting> next,
    ) {
      if (_didHandleStartupAutoScanPreference) return;
      next.whenData((AppSetting setting) {
        _didHandleStartupAutoScanPreference = true;
        if (!setting.autoScan) return;
        _scheduleStartupAutoScanAtIdle();
      });
    });
    return true;
  }

  void _scheduleStartupAutoScanAtIdle() {
    if (_autoScanScheduled) {
      return;
    }
    _autoScanScheduled = true;
    _autoScanScheduleToken++;
    final int token = _autoScanScheduleToken;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) async {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!_isValidScheduleToken(token)) {
        return;
      }
      await SchedulerBinding.instance.endOfFrame;
      if (!_isValidScheduleToken(token)) {
        return;
      }
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          if (!_isValidScheduleToken(token)) {
            return;
          }
          final ScanLibraryState scanState = ref.read(
            scanLibraryControllerProvider,
          );
          if (scanState.running) {
            return;
          }
          unawaited(ref.read(scanLibraryControllerProvider.notifier).start());
        },
        Priority.idle,
        debugLabel: 'startup_auto_scan_idle',
      );
    });
  }

  bool _isValidScheduleToken(int token) {
    return token == _autoScanScheduleToken;
  }
}