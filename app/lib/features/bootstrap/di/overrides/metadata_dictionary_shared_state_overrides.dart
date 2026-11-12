import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/public.dart';
import 'package:hentai_library/features/comic_metadata/public.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// metadata_backup 与 comic_metadata 字典/设置槽注入（#435）。
List<Override> metadataAndDictionarySharedStateOverrides() => <Override>[
  ...metadataBackupSharedStateOverrides(),
  libraryTagDictionaryStateProvider.overrideWith(
    (Ref ref) => ref.watch(allTagsProvider),
  ),
  libraryAuthorDictionaryStateProvider.overrideWith(
    (Ref ref) => ref.watch(allAuthorsProvider),
  ),
];
