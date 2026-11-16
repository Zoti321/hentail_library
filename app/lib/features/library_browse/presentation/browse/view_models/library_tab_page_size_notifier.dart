import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/library_browse_preferences_provider.dart';

part 'library_tab_page_size_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryTabPageSizeNotifier extends _$LibraryTabPageSizeNotifier {
  LibraryBrowsePreferencesRepository get _preferences =>
      ref.read(libraryBrowsePreferencesRepositoryProvider);

  @override
  Future<LibraryTabPageSizeSettings> build() => _preferences.loadPageSizes();

  Future<void> setPageSize(LibraryDisplayTarget target, int pageSize) async {
    final int normalized = normalizeLibraryPageSize(pageSize);
    final LibraryTabPageSizeSettings current = await future;
    final LibraryTabPageSizeSettings updated = copyPageSizeForTarget(
      current,
      target,
      normalized,
    );
    state = AsyncData<LibraryTabPageSizeSettings>(updated);
    await _preferences.savePageSize(target, normalized);
  }
}
