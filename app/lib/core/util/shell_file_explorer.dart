import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hentai_library/core/errors/app_exception.dart';

/// Whether a `explorer.exe /select` [ProcessResult] should be treated as failure.
///
/// On Windows, `explorer.exe` returns exit code 1 even when the folder opens
/// successfully, so exit code alone is not a reliable signal.
@visibleForTesting
bool shouldTreatExplorerSelectAsFailure({
  required bool isWindows,
  required int exitCode,
}) {
  if (isWindows) {
    return false;
  }
  return exitCode != 0;
}

/// Convert app-stored POSIX paths to native Windows separators for `explorer.exe`.
///
/// `explorer.exe` treats each `/segment` in an argument as a command-line switch.
/// Paths stored with forward slashes therefore lose every path token and fall
/// back to the user's Documents folder.
@visibleForTesting
String toWindowsExplorerPath(String path) => path.replaceAll('/', r'\');

Future<void> openDirectoryInFileExplorer(String directoryPath) async {
  final String normalizedPath = directoryPath.trim();
  if (normalizedPath.isEmpty) {
    throw ValidationException('无法打开文件夹：路径为空');
  }
  if (Platform.isWindows) {
    await Process.run('explorer.exe', <String>[
      toWindowsExplorerPath(normalizedPath),
    ]);
    return;
  }
  if (Platform.isMacOS) {
    final ProcessResult result = await Process.run('open', <String>[
      normalizedPath,
    ]);
    if (result.exitCode == 0) {
      return;
    }
    throw AppException(
      '无法打开文件夹',
      cause: 'macos exitCode=${result.exitCode}, stderr=${result.stderr}',
    );
  }
  if (Platform.isLinux) {
    final ProcessResult result = await Process.run('xdg-open', <String>[
      normalizedPath,
    ]);
    if (result.exitCode == 0) {
      return;
    }
    throw AppException(
      '无法打开文件夹',
      cause: 'linux exitCode=${result.exitCode}, stderr=${result.stderr}',
    );
  }
  throw AppException(
    '无法打开文件夹',
    cause: 'unsupported platform: $defaultTargetPlatform',
  );
}

Future<void> showInFileExplorer(String path) async {
  final String normalizedPath = path.trim();
  if (normalizedPath.isEmpty) {
    throw ValidationException('无法在文件资源管理器中显示该项目：路径为空');
  }
  if (Platform.isWindows) {
    await Process.run('explorer.exe', <String>[
      '/select,',
      toWindowsExplorerPath(normalizedPath),
    ]);
    return;
  }
  if (Platform.isMacOS) {
    final ProcessResult result = await Process.run('open', <String>[
      '-R',
      normalizedPath,
    ]);
    if (result.exitCode == 0) {
      return;
    }
    throw AppException(
      '无法在文件资源管理器中显示该项目',
      cause: 'macos exitCode=${result.exitCode}, stderr=${result.stderr}',
    );
  }
  if (Platform.isLinux) {
    final ProcessResult result = await Process.run('xdg-open', <String>[
      normalizedPath,
    ]);
    if (result.exitCode == 0) {
      return;
    }
    throw AppException(
      '无法在文件资源管理器中显示该项目',
      cause: 'linux exitCode=${result.exitCode}, stderr=${result.stderr}',
    );
  }
  throw AppException(
    '无法在文件资源管理器中显示该项目',
    cause: 'unsupported platform: $defaultTargetPlatform',
  );
}
