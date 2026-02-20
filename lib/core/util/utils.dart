import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:url_launcher/url_launcher.dart';

// 判断是否为桌面平台
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ].contains(defaultTargetPlatform);
}

// 生成漫画哈希id
String generateComicId(String title, {String? coverUrl, String? description}) {
  final input = [title, coverUrl, description].whereType<String>().join();
  final bytes = utf8.encode(input);
  final digest = sha1.convert(bytes);
  return digest.toString();
}

// 生成章节哈希id
String generateChapterId(
  String comicTitle,
  String imageDir,
  int pageCount,
  int number,
) {
  final input =
      comicTitle + imageDir + pageCount.toString() + number.toString();
  final bytes = utf8.encode(input);
  final digest = sha1.convert(bytes);
  return digest.toString();
}

// 在资源管理器打开对应文件夹
Future<void> openFolder(String path) async {
  final Uri uri = Uri.file(path);

  // 检查系统是否支持打开该路径
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    // 也可以尝试直接调用命令行（兜底方案）
    throw '无法打开文件夹：$path';
  }
}

Future<void> showInFileExplorer(String path) async {
  final String normalizedPath = path.trim();
  if (normalizedPath.isEmpty) {
    throw ValidationException('无法在文件资源管理器中显示该项目：路径为空');
  }
  if (Platform.isWindows) {
    final ProcessResult result = await Process.run('explorer.exe', <String>[
      '/select,',
      normalizedPath,
    ]);
    if (result.exitCode == 0) {
      return;
    }
    throw AppException(
      '无法在文件资源管理器中显示该项目',
      cause: 'windows exitCode=${result.exitCode}, stderr=${result.stderr}',
    );
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
