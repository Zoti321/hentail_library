/// 跨 feature 只读类型（真源仍在 owner `domain/`，此处 re-export，ADR-0034）。
library;

export 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_types.dart';
export 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
export 'package:hentai_library/features/library_admin/domain/library_revision_state.dart';
export 'package:hentai_library/features/library_admin/domain/library_scan_activity_state.dart';
export 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';
export 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
export 'package:hentai_library/features/library_admin/domain/scan_interval.dart';
export 'package:hentai_library/features/library_admin/domain/library_scan_domain_service.dart';
export 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
