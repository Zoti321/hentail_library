import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<LibraryBrowsePreferencesRepository>
libraryBrowsePreferencesRepositoryProvider = requiredProvider(
  'libraryBrowsePreferencesRepositoryProvider',
);
