/// Bootstrap 组装 library_admin shared 注入（#435）。
///
/// 实现位于 owner [`di/library_admin_shared_state_overrides.dart`]；
/// public 层仅 re-export，以满足 R12（public 不 import presentation）。
library;

export 'package:hentai_library/features/library_admin/di/library_admin_shared_state_overrides.dart'
    show libraryAdminSharedStateOverrides;
