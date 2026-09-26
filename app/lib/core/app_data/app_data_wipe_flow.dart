import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/metadata/metadata_auto_backup_logic.dart';
import 'package:hentai_library/core/metadata/metadata_backup_paths.dart';
import 'package:hentai_library/src/rust/api/shutdown.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/clear_application_data_confirm_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppDataWipeResult { success, deleteFailed }

typedef AppDataShutdown = void Function();
typedef AppDataDirectoryResolver = Future<String> Function();
typedef AppDataDirectoryDeleter = Future<void> Function(String appDataPath);
typedef SharedPreferencesClear = Future<bool> Function();

/// 设置 → 诊断与支持 →「清除全部应用数据」编排入口。
Future<void> runAppDataWipeFlow(
  BuildContext context, {
  AppDataShutdown? shutdownAppData,
  AppDataDirectoryResolver? resolveAppDataDirectory,
  SharedPreferencesClear? clearPreferences,
}) async {
  final DateTime? recentBackupAt = await _readRecentMetadataBackupAt();
  final bool confirmed =
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) =>
            ClearApplicationDataConfirmDialog(recentBackupAt: recentBackupAt),
      ) ??
      false;
  if (!confirmed || !context.mounted) {
    return;
  }

  final String appDataPath =
      await (resolveAppDataDirectory ?? _defaultAppDataDirectory)();
  final AppDataWipeResult result = await wipeApplicationData(
    appDataPath: appDataPath,
    shutdownAppData: shutdownAppData,
    clearPreferences: clearPreferences,
  );

  if (!context.mounted) {
    await _exitApp();
    return;
  }

  final l10n = context.l10n;
  if (result == AppDataWipeResult.success) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => HentaiDialog(
        title: l10n.confirmClearApplicationDataTitle,
        content: Text(l10n.wipeCompleteRestartMessage),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => HentaiDialog(
        title: l10n.confirmClearApplicationDataTitle,
        content: Text(l10n.wipeFailedManualDeleteMessage(appDataPath)),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  await _exitApp();
}

Future<DateTime?> _readRecentMetadataBackupAt() async {
  try {
    final String backupsDir = await metadataBackupsDirectory();
    final List<File> files = listMetadataBackupFiles(backupsDir);
    if (files.isEmpty) {
      return null;
    }
    return files.first.lastModifiedSync();
  } on Object {
    return null;
  }
}

Future<String> _defaultAppDataDirectory() async {
  final Directory directory = await getApplicationSupportDirectory();
  return directory.path;
}

Future<AppDataWipeResult> wipeApplicationData({
  required String appDataPath,
  AppDataShutdown? shutdownAppData,
  AppDataDirectoryDeleter? deleteAppDataDirectory,
  SharedPreferencesClear? clearPreferences,
}) async {
  (shutdownAppData ?? shutdownAppDataFrb)();
  try {
    await (deleteAppDataDirectory ?? _defaultDeleteAppDataDirectory)(
      appDataPath,
    );
    final bool cleared = await (clearPreferences ?? _defaultClearPreferences)();
    if (!cleared) {
      return AppDataWipeResult.deleteFailed;
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    return AppDataWipeResult.success;
  } on FileSystemException {
    return AppDataWipeResult.deleteFailed;
  }
}

Future<void> _defaultDeleteAppDataDirectory(String appDataPath) async {
  final Directory directory = Directory(appDataPath);
  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}

Future<bool> _defaultClearPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.clear();
}

Future<void> _exitApp() async {
  if (Platform.isAndroid || Platform.isIOS) {
    await SystemNavigator.pop();
    return;
  }
  exit(0);
}

String formatRecentMetadataBackupAt(DateTime timestamp) {
  return DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
}
