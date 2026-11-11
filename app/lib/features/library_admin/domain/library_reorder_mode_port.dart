/// ADR-0045：`LibraryReorderModePort` 的真源在 `shared/domain/ports/`（shared 消费方豁免）。
///
/// 本文件仅作单向 re-export（feature → shared）；新代码请直接 import shared 路径。
library;

export 'package:hentai_library/shared/domain/ports/library_reorder_mode_port.dart';
