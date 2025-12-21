import 'dart:io';

import 'package:hentai_library/core/util/utils.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

/// 打开已下载的更新包；Linux tar.gz 在文件管理器中显示。
Future<void> openDownloadedUpdateFile(String filePath) async {
  if (Platform.isLinux && filePath.endsWith('.tar.gz')) {
    await showInFileExplorer(filePath);
    return;
  }
  final OpenResult result = await OpenFilex.open(filePath);
  if (result.type == ResultType.done) {
    return;
  }
  final Uri fileUri = Uri.file(filePath);
  if (await canLaunchUrl(fileUri)) {
    await launchUrl(fileUri);
    return;
  }
  throw StateError('无法打开更新文件：${result.message}');
}

/// 打开 GitHub Release 页面。
Future<void> openReleasePage(String htmlUrl) async {
  final Uri uri = Uri.parse(htmlUrl);
  if (!await canLaunchUrl(uri)) {
    throw StateError('无法打开 Release 页面');
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
