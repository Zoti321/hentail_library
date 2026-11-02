/// Komga 风格三态筛选：未选 → 包含 → 排除 → 未选。
///
/// 与 Material [Checkbox]（`tristate: true`）的映射：
/// - [neutral] → `false`（未选中）
/// - [include] → `true`（勾选）
/// - [exclude] → `null`（第三态 / indeterminate）
enum LibraryTriStatePick {
  neutral,
  include,
  exclude;

  LibraryTriStatePick get next => switch (this) {
    LibraryTriStatePick.neutral => LibraryTriStatePick.include,
    LibraryTriStatePick.include => LibraryTriStatePick.exclude,
    LibraryTriStatePick.exclude => LibraryTriStatePick.neutral,
  };

  /// Material [Checkbox.value]（需 `tristate: true`）。
  bool? get checkboxValue => switch (this) {
    LibraryTriStatePick.neutral => false,
    LibraryTriStatePick.include => true,
    LibraryTriStatePick.exclude => null,
  };
}

/// 多个包含项之间的组合方式。
enum LibraryMetadataIncludeMode {
  all,
  any;

  static LibraryMetadataIncludeMode fromStorage(String? raw) {
    return LibraryMetadataIncludeMode.values.asNameMap()[raw] ??
        LibraryMetadataIncludeMode.any;
  }
}
