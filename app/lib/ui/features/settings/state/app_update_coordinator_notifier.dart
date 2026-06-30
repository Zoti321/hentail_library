import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/features/settings/state/app_update_controller.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_coordinator_notifier.g.dart';

@Riverpod(keepAlive: true)
class AppUpdateCoordinatorNotifier extends _$AppUpdateCoordinatorNotifier {
  bool _didHandleStartupPreference = false;
  bool _startupScheduled = false;

  @override
  bool build() {
    ref.listen<AsyncValue<AppSetting>>(settingsProvider, (
      AsyncValue<AppSetting>? previous,
      AsyncValue<AppSetting> next,
    ) {
      if (_didHandleStartupPreference) {
        return;
      }
      next.whenData((AppSetting setting) {
        _didHandleStartupPreference = true;
        if (!setting.autoUpdate) {
          return;
        }
        _scheduleStartupUpdateCheck();
      });
    });
    return true;
  }

  void _scheduleStartupUpdateCheck() {
    if (_startupScheduled) {
      return;
    }
    _startupScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      unawaited(
        ref
            .read(appUpdateControllerProvider.notifier)
            .scheduleStartupCheckIfNeeded(),
      );
    });
  }
}
