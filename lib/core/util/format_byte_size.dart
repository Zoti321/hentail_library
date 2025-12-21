/// 将字节数格式化为可读字符串（1024 进制）。
String formatByteSizeBin1024(int bytes) {
  if (bytes < 0) {
    return '0 B';
  }
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
