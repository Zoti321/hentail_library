import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/data/recent_metadata_backup_at.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/features/metadata_backup/presentation/metadata_export_flow.dart';
import 'package:hentai_library/features/metadata_backup/presentation/views/metadata_backup_settings_sections.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/author_management_notifier.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// metadata_backup 与 named_metadata 字典/设置槽注入（#435）。
List<Override> metadataAndDictionarySharedStateOverrides() => <Override>[
  metadataBackupSettingsSectionBuilderProvider.overrideWithValue(
    (BuildContext context) => const MetadataBackupSettingsSections(),
  ),
  libraryMetadataExportActionProvider.overrideWithValue(
    (BuildContext context, String libraryId) => runMetadataExportFlow(
      context,
      initialOptions: MetadataExportOptions(
        currentLibraryOnly: true,
        libraryId: libraryId,
      ),
    ),
  ),
  recentMetadataBackupAtReaderProvider.overrideWithValue(
    readRecentMetadataBackupAt,
  ),
  libraryTagDictionaryStateProvider.overrideWith(
    (Ref ref) => ref.watch(allTagsProvider),
  ),
  libraryAuthorDictionaryStateProvider.overrideWith(
    (Ref ref) => ref.watch(allAuthorsProvider),
  ),
];
