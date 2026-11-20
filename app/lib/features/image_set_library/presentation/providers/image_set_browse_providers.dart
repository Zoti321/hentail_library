import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_browse_preferences_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

typedef ImageSetCatalogPageQuery =
    Future<PagedImageSetCatalog> Function({
      required String libraryId,
      required PageRequest request,
      required ImageSetBrowsePreferences preferences,
    });

final Provider<ImageSetBrowsePreferencesRepository>
imageSetBrowsePreferencesRepositoryProvider = requiredProvider(
  'imageSetBrowsePreferencesRepositoryProvider',
);

final Provider<ImageSetCatalogPageQuery> imageSetCatalogPageQueryProvider =
    requiredProvider('imageSetCatalogPageQueryProvider');

final imageSetBrowsePreferencesProvider =
    AsyncNotifierProvider<
      ImageSetBrowsePreferencesNotifier,
      ImageSetBrowsePreferences
    >(ImageSetBrowsePreferencesNotifier.new);

class ImageSetBrowsePreferencesNotifier
    extends AsyncNotifier<ImageSetBrowsePreferences> {
  @override
  Future<ImageSetBrowsePreferences> build() =>
      ref.read(imageSetBrowsePreferencesRepositoryProvider).load();

  Future<void> replace(ImageSetBrowsePreferences next) async {
    state = AsyncData<ImageSetBrowsePreferences>(next);
    await ref.read(imageSetBrowsePreferencesRepositoryProvider).save(next);
  }

  Future<void> reset() async {
    await ref.read(imageSetBrowsePreferencesRepositoryProvider).reset();
    state = const AsyncData<ImageSetBrowsePreferences>(
      ImageSetBrowsePreferences.defaults,
    );
  }
}

final imageSetCatalogPageIndexProvider =
    NotifierProvider<ImageSetCatalogPageIndexNotifier, Map<String, int>>(
      ImageSetCatalogPageIndexNotifier.new,
    );

class ImageSetCatalogPageIndexNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const <String, int>{};

  int pageFor(String libraryId) => state[libraryId] ?? 1;

  void setPage(String libraryId, int page) {
    final int next = page < 1 ? 1 : page;
    state = <String, int>{...state, libraryId: next};
  }
}

final imageSetCatalogPageProvider = FutureProvider.autoDispose
    .family<PagedImageSetCatalog, String>((Ref ref, String libraryId) async {
      ref.watch(libraryRevisionStateProvider.select((s) => s.revision));
      final ImageSetBrowsePreferences preferences = await ref.watch(
        imageSetBrowsePreferencesProvider.future,
      );
      final int page = ref.watch(
        imageSetCatalogPageIndexProvider.select(
          (Map<String, int> pages) => pages[libraryId] ?? 1,
        ),
      );
      return ref.watch(imageSetCatalogPageQueryProvider)(
        libraryId: libraryId,
        request: pageRequest(page: page, pageSize: preferences.pageSize),
        preferences: preferences,
      );
    });
