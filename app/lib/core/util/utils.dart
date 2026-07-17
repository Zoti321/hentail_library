import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hentai_library/core/errors/app_exception.dart';

// 判断是否为桌面平台
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ].contains(defaultTargetPlatform);
}

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

Future<void> showInFileExplorer(String path) async {
  final String normalizedPath = path.trim();
  if (normalizedPath.isEmpty) {
    throw ValidationException('无法在文件资源管理器中显示该项目：路径为空');
  }
  if (Platform.isWindows) {
    await Process.run('explorer.exe', <String>['/select,', normalizedPath]);
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

// 文件大小格式化
extension FileSizeExtension on int {
  String toReadableSize() {
    if (this <= 0) return "0 B";

    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB"];
    // 计算对数确定单位索引：i = floor(log1024(bytes))
    var i = (log(this) / log(1024)).floor();

    // 确保索引不越界
    i = i.clamp(0, suffixes.length - 1);

    // 计算数值：bytes / 1024^i
    var num = this / pow(1024, i);

    // 格式化输出：如果是字节 B 则不留小数，否则保留两位
    return "${num.toStringAsFixed(i == 0 ? 0 : 2)} ${suffixes[i]}";
  }
}
