/// 长路径中间省略，保留首尾以便识别。
String ellipsisMiddlePath(String path, {int maxLength = 56}) {
  if (path.length <= maxLength) {
    return path;
  }
  final int keep = (maxLength - 1) ~/ 2;
  return '${path.substring(0, keep)}…${path.substring(path.length - keep)}';
}
