/// 内容分级（用户自定义为主）。
enum ContentRating { unknown, safe, r18 }

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

  /// .cbr 压缩包
  cbr,

  /// .rar 压缩包
  rar,

  /// .cb7 压缩包
  cb7,

  /// .7z 压缩包
  sevenZ,

  /// PDF 文档
  pdf,
}

enum LibraryDisplayTarget { comics, series }

/// 缩略图生成优先级（Rust 后台队列调度）。
enum ThumbnailPriority { critical, high, low }

/// 系列连载状态（用户可编辑；sync 不覆盖）。
enum SerializationStatus {
  unknown,
  ongoing,
  ended,
  hiatus;

  String get label => switch (this) {
    SerializationStatus.unknown => '未知',
    SerializationStatus.ongoing => '连载中',
    SerializationStatus.ended => '已完结',
    SerializationStatus.hiatus => '休刊',
  };

  static SerializationStatus fromRust(String raw) {
    return switch (raw) {
      'ongoing' => SerializationStatus.ongoing,
      'ended' => SerializationStatus.ended,
      'hiatus' => SerializationStatus.hiatus,
      _ => SerializationStatus.unknown,
    };
  }

  String toRust() => name;
}
