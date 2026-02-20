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

  /// .cbr 占位（暂不解析）
  cbr,

  /// .rar 占位（暂不解析）
  rar,
}
