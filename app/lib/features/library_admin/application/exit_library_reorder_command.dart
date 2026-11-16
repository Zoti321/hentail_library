/// ADR-0045：退出重排命令 的真源在 `shared/application/contracts/`（shared 消费方豁免）。
///
/// 本文件仅作单向 re-export（feature → shared）；新代码请直接 import shared 路径。
library;

export 'package:hentai_library/shared/application/contracts/exit_library_reorder_command.dart';
