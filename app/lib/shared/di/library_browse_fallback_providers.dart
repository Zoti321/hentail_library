import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/library_browse_fallback_port.dart';

/// 「回到默认库浏览」窄口 token（ADR-0045 shared 消费方豁免）。
///
/// 消费方是 `shared/ui`；实现与工厂见 `features/library_admin/public.dart`。
/// 全量库管理命令 token 在 `features/library_admin/public/di/`。
final Provider<LibraryBrowseFallbackPort> libraryBrowseFallbackPortProvider =
    injectedDi('libraryBrowseFallbackPortProvider');
