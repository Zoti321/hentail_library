import 'package:flutter/widgets.dart';
import 'package:hentai_library/features/metadata_backup/public.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// metadata_backup 设置槽与库页导出入口（#264 / #435）。
List<Override> metadataBackupSharedStateOverrides() => <Override>[
  metadataBackupSettingsSectionBuilderProvider.overrideWithValue(
    (BuildContext context) => const MetadataBackupSettingsSections(),
  ),
  libraryMetadataExportActionProvider.overrideWithValue(
    (BuildContext context, String libraryId) => runMetadataExportFlow(
      context,
      initialOptions: MetadataExportOptions(libraryId: libraryId),
    ),
  ),
  recentMetadataBackupAtReaderProvider.overrideWithValue(
    readRecentMetadataBackupAt,
  ),
];
