import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设置页「元数据备份」板块的组装槽位（#264）。
///
/// app_settings 不直接依赖 metadata_backup；实现由 bootstrap 通过 `overrideWithValue` 注入。
typedef MetadataBackupSettingsSectionBuilder = Widget Function(
  BuildContext context,
);

final Provider<MetadataBackupSettingsSectionBuilder>
metadataBackupSettingsSectionBuilderProvider =
    Provider<MetadataBackupSettingsSectionBuilder>(
      (Ref ref) => throw UnimplementedError(
        'metadataBackupSettingsSectionBuilderProvider 未注入，请在 bootstrap 中 override',
      ),
    );
