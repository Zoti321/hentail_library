import 'package:hentai_library/features/comic_metadata/public/providers/comic_metadata_repository_providers.dart';
import 'package:hentai_library/features/library_browse/infrastructure/library_browse_preferences_repository_impl.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/library_browse_preferences_provider.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> libraryBrowsePreferencesOverrides() => <Override>[
  libraryBrowsePreferencesRepositoryProvider.overrideWith(
    (ref) => LibraryBrowsePreferencesRepositoryImpl(
      authors: ref.read(authorRepoProvider),
    ),
  ),
];
