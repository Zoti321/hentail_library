import 'dart:math';

/// 将字节数格式化为可读字符串（1024 进制）。
String formatByteSizeBin1024(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const List<String> suffixes = <String>['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  final int unitIndex = (log(bytes) / log(1024)).floor().clamp(
    0,
    suffixes.length - 1,
  );
  final double value = bytes / pow(1024, unitIndex);
  final int decimals = unitIndex == 0 ? 0 : 2;
  return '${value.toStringAsFixed(decimals)} ${suffixes[unitIndex]}';
}

extension FileSizeExtension on int {
  String toReadableSize() => formatByteSizeBin1024(this);
}
