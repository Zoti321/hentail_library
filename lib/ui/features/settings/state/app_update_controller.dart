import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/constants/app_update_constants.dart';
import 'package:hentai_library/core/util/app_root_navigator.dart';
import 'package:hentai_library/core/util/semver_utils.dart';
import 'package:hentai_library/domain/models/app_release_info.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/app_update_dialog.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_controller.g.dart';

enum AppUpdateCheckOutcome { upToDate, updateAvailable, failed }

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();

@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  bool _sessionStartupChecked = false;

  @override
  void build() {}

  Future<AppUpdateCheckOutcome> checkForUpdate({
    required bool respectDismissedVersion,
    required bool showDialogOnUpdate,
    required bool showFeedbackToasts,
    BuildContext? dialogContext,
  }) async {
    try {
      final PackageInfo info = await ref.read(packageInfoProvider.future);
      final String currentVersion = SemverUtils.normalizeVersion(info.version);
      final AppReleaseInfo? latestRelease = await ref
          .read(appUpdateServiceProvider)
          .fetchLatestStableRelease();
      if (latestRelease == null) {
        if (showFeedbackToasts) {
          _showInfoToast('检查更新失败，请稍后重试', dialogContext);
        }
        return AppUpdateCheckOutcome.failed;
      }
      if (!SemverUtils.isGreaterThan(latestRelease.version, currentVersion)) {
        if (showFeedbackToasts) {
          _showInfoToast('当前已是最新版本', dialogContext);
        }
        return AppUpdateCheckOutcome.upToDate;
      }
      if (respectDismissedVersion) {
        final AppSetting? settings = ref.read(settingsProvider).asData?.value;
        if (settings != null &&
            settings.dismissedUpdateVersion == latestRelease.version) {
          return AppUpdateCheckOutcome.upToDate;
        }
      }
      if (showDialogOnUpdate) {
        await _showUpdateDialog(latestRelease, dialogContext);
      }
      return AppUpdateCheckOutcome.updateAvailable;
    } catch (_) {
      if (showFeedbackToasts) {
        _showInfoToast('检查更新失败，请稍后重试', dialogContext);
      }
      return AppUpdateCheckOutcome.failed;
    }
  }

  Future<void> runManualCheck({BuildContext? context}) {
    return checkForUpdate(
      respectDismissedVersion: false,
      showDialogOnUpdate: true,
      showFeedbackToasts: true,
      dialogContext: context,
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
    );
    return completer.future;
  }

  Future<void> _showUpdateDialog(
    AppReleaseInfo release,
    BuildContext? preferredContext,
  ) async {
    final BuildContext? context = _resolveDialogContext(preferredContext);
    if (context == null) {
      return;
    }
    await showAppUpdateDialog(context: context, release: release);
  }

  void _showInfoToast(String message, BuildContext? preferredContext) {
    final BuildContext? context = _resolveDialogContext(preferredContext);
    if (context == null) {
      return;
    }
    showInfoToast(context, message);
  }

  BuildContext? _resolveDialogContext(BuildContext? preferredContext) {
    if (preferredContext != null && preferredContext.mounted) {
      return preferredContext;
    }
    final BuildContext? rootContext = appRootNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      return rootContext;
    }
    return null;
  }
}
