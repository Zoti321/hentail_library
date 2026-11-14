import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hentai_library/features/app_settings/application/app_update_constants.dart';
import 'package:hentai_library/features/app_settings/application/check_app_update_use_case.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/logging/app_log.dart';
import 'package:hentai_library/shared/ui/navigation/app_root_navigator_key.dart';
import 'package:hentai_library/features/app_settings/domain/app_release_info.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/app_settings/presentation/views/dialogs/app_update_dialog.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/installed_app_version_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_controller.g.dart';

enum AppUpdateCheckOutcome { upToDate, updateAvailable, failed }

@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  bool _sessionStartupChecked = false;

  @override
  void build() {}

  Future<AppUpdateCheckOutcome> checkForUpdate({
    required bool respectDismissedVersion,
    required bool showDialogOnUpdate,
    required bool showFeedbackToasts,
    AppUpdateFeedback? feedback,
  }) async {
    final ui = feedback ?? appUpdateFeedback(null);
    try {
      final String currentVersion = await ref.read(
        installedAppVersionProvider.future,
      );
      final result = await ref.read(checkAppUpdateUseCaseProvider)(
        currentVersion: currentVersion,
        respectDismissedVersion: respectDismissedVersion,
      );
      switch (result) {
        case AppUpdateUnavailable():
          if (showFeedbackToasts) {
            ui.showToast(
              (AppLocalizations l10n) => l10n.settingsUpdateCheckFailed,
            );
          }
          return AppUpdateCheckOutcome.failed;
        case AppUpdateCurrent():
          if (showFeedbackToasts) {
            ui.showToast(
              (AppLocalizations l10n) => l10n.settingsUpdateUpToDate,
            );
          }
          return AppUpdateCheckOutcome.upToDate;
        case AppUpdateDismissed():
          return AppUpdateCheckOutcome.upToDate;
        case AppUpdateAvailable(:final release):
          if (showDialogOnUpdate) {
            await ui.showUpdate(release);
          }
          return AppUpdateCheckOutcome.updateAvailable;
      }
    } catch (error, stackTrace) {
      if (showFeedbackToasts) {
        logError(AppLog.ui('appUpdate'), '检查更新失败', error, stackTrace);
        ui.showToast((AppLocalizations l10n) => l10n.settingsUpdateCheckFailed);
      }
      return AppUpdateCheckOutcome.failed;
    }
  }

  Future<void> runManualCheck({AppUpdateFeedback? feedback}) {
    return checkForUpdate(
      respectDismissedVersion: false,
      showDialogOnUpdate: true,
      showFeedbackToasts: true,
      feedback: feedback,
    );
  }

  Future<void> scheduleStartupCheckIfNeeded() async {
    if (_sessionStartupChecked) {
      return;
    }
    final AppSetting? settings = ref.read(settingsProvider).asData?.value;
    if (settings == null || !settings.autoUpdate) {
      return;
    }
    _sessionStartupChecked = true;
    await Future<void>.delayed(AppUpdateConstants.startupCheckDelay);
    await SchedulerBinding.instance.endOfFrame;
    final Completer<void> completer = Completer<void>();
    unawaited(
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          unawaited(
            checkForUpdate(
              respectDismissedVersion: true,
              showDialogOnUpdate: true,
              showFeedbackToasts: false,
            ).whenComplete(completer.complete),
          );
        },
        Priority.idle,
        debugLabel: 'startup_update_check_idle',
      ),
    );
    return completer.future;
  }
}

Future<void> _showUpdateDialogForContext(
  AppReleaseInfo release,
  BuildContext? uiContext,
) async {
  if (uiContext != null && uiContext.mounted) {
    await showAppUpdateDialog(context: uiContext, release: release);
    return;
  }
  final BuildContext? rootContext = appRootNavigatorKey.currentContext;
  if (rootContext != null && rootContext.mounted) {
    await showAppUpdateDialog(context: rootContext, release: release);
  }
}

void _showFeedbackToast(
  BuildContext? uiContext,
  String Function(AppLocalizations l10n) message,
) {
  final BuildContext? ctx = uiContext != null && uiContext.mounted
      ? uiContext
      : appRootNavigatorKey.currentContext;
  if (ctx != null && ctx.mounted) {
    showInfoSnackbar(ctx, message(AppLocalizations.of(ctx)));
  }
}

typedef AppUpdateFeedback = ({
  Future<void> Function(AppReleaseInfo) showUpdate,
  void Function(String Function(AppLocalizations)) showToast,
});

AppUpdateFeedback appUpdateFeedback(BuildContext? context) => (
  showUpdate: (release) => _showUpdateDialogForContext(release, context),
  showToast: (message) => _showFeedbackToast(context, message),
);
