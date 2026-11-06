import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// 资源大小（字节）转为可读文本，如 `12.3 MB`。
String formatComicResourceSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// 发行日期（仅日期）。
String? formatComicPublishedDate(BuildContext context, DateTime? date) {
  if (date == null) {
    return null;
  }
  final String locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(date.toLocal());
}

/// 日期加时间（添加时间、更新时间）。
String? formatComicDetailDateTime(BuildContext context, DateTime? date) {
  if (date == null) {
    return null;
  }
  final String locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}
