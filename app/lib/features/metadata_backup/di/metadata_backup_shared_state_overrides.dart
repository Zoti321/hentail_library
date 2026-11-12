import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/metadata_backup/public.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// metadata_backup 库页导出入口（#264 / #435）。
///
/// 设置页「元数据备份」分区不再走 `shared/di` 槽位：组合根在
/// `app_router.dart` 直接注入 [MetadataBackupSettingsSections]（ADR-0046 §6）。
List<Override> metadataBackupSharedStateOverrides() => <Override>[
  libraryMetadataExportActionProvider.overrideWithValue(
    (BuildContext context, String libraryId) => runMetadataExportFlow(
      context,
      initialOptions: MetadataExportOptions(libraryId: libraryId),
    ),
  ),
];
