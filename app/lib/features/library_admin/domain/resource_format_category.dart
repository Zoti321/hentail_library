/// ADR-0045：`ResourceFormatCategory` 的内核真源在 `shared/domain/models/`。
///
/// 本文件仅作单向 re-export（feature → shared），与 `sync_library_types.dart`
/// 转发 `library_scan_mode.dart` 同形；新代码请直接 import shared 路径。
library;

export 'package:hentai_library/shared/domain/models/resource_format_category.dart';
