/// 元数据管理页共享 UI patterns 的跨边界导出（ADR-0034）。
///
/// 生产 [`MetadataManagementPage`] 与 Widgetbook `ManagementBrowsePage` 共用这些
/// 组件；本 barrel 供 Lab / Widgetbook 引用，**不是**独立生产路由面。
library;

export 'package:hentai_library/shared/domain/models/managed_named_facet_kind.dart';
export 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/managed_named_facet_ui.dart';
export 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_catalog_toolbar.dart';
export 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_create_entity_dialog.dart';
export 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_create_interaction.dart';
export 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_draft_entity_chip.dart';
export 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_facet_chip_wrap.dart';
export 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_page_header.dart';
