import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_author_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_media_type_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tag_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_comics_filter_reset_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryComicsFilterResetNotifier
    extends _$LibraryComicsFilterResetNotifier {
  @override
  void build() {}

  Future<void> resetAll() async {
    await ref
        .read(libraryAgeRestrictionFilterProvider.notifier)
        .setFilter(
          LibraryDisplayTarget.comics,
          LibraryAgeRestrictionFilter.unrestricted,
        );
    await ref.read(libraryMediaTypeFilterProvider.notifier).clearAll();
    await ref.read(libraryTagFilterProvider.notifier).clear();
    await ref.read(libraryAuthorFilterProvider.notifier).clear();
    await ref.read(libraryLanguageFilterProvider.notifier).clear();
    await ref.read(libraryParodyFilterProvider.notifier).clear();
    await ref.read(libraryCharacterFilterProvider.notifier).clear();
    await ref.read(libraryTabSortProvider.notifier).resetComicsSortToDefault();
    ref.invalidate(libraryComicsCatalogControllerProvider);
  }
}
