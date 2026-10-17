import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_layout_constants.dart';

/// 设置页「元数据备份」板块的组装槽位（#264）。
///
/// app_settings 不直接依赖 metadata_backup；实现由 bootstrap 通过 `overrideWithValue` 注入。
typedef MetadataBackupSettingsSectionBuilder =
    Widget Function(SettingsLayoutTier layoutTier, bool showTitle);

/// 读取最近一次元数据备份时间（清除应用数据确认框展示用）。
typedef RecentMetadataBackupAtReader = Future<DateTime?> Function();

final Provider<MetadataBackupSettingsSectionBuilder>
metadataBackupSettingsSectionBuilderProvider =
    Provider<MetadataBackupSettingsSectionBuilder>(
      (Ref ref) => throw UnimplementedError(
        'metadataBackupSettingsSectionBuilderProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<RecentMetadataBackupAtReader>
recentMetadataBackupAtReaderProvider = Provider<RecentMetadataBackupAtReader>(
  (Ref ref) => throw UnimplementedError(
    'recentMetadataBackupAtReaderProvider 未注入，请在 bootstrap 中 override',
  ),
);
