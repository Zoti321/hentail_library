import 'package:path/path.dart' as p;

/// 通过规则校验后确定的资源类型（用于后续 diff/入库重构）。
enum ResourceType {
  /// 纯图片目录
  dir,

  /// .zip 压缩包
  /// 内容为纯图片
  zip,

  /// .cbz 压缩包
  cbz,

  /// .epub 电子书
  /// 确认内容是否为漫画
  epub,

  /// .cbr 占位（暂不解析）
  cbr,

  /// .rar 占位（暂不解析）
  rar,
}

/// 扫描阶段的候选基础单元。
typedef ResourceCandidate = ({String path, ResourceType type});

/// 从资源中提取的元数据。
typedef ComicMeta = ({String title, List<String> authors});

/// 解析阶段输出的基础单元。
typedef ParsedResource = ({String path, ResourceType type, ComicMeta meta});

ResourceType? resourceTypeFromFilePath(String path) {
  final ext = p.extension(path).toLowerCase();
  return switch (ext) {
    '.zip' => ResourceType.zip,
    '.cbz' => ResourceType.cbz,
    '.epub' => ResourceType.epub,
    '.cbr' => ResourceType.cbr,
    '.rar' => ResourceType.rar,
    _ => null,
  };
}
