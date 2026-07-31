import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_serialization_status_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_series_filter_reset_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibrarySeriesFilterResetNotifier
    extends _$LibrarySeriesFilterResetNotifier {
  @override
  void build() {}

  Future<void> resetAll() async {
    await ref
        .read(libraryAgeRestrictionFilterProvider.notifier)
        .setFilter(
          LibraryDisplayTarget.series,
          LibraryAgeRestrictionFilter.unrestricted,
        );
    await ref
        .read(librarySerializationStatusFilterProvider.notifier)
        .setFilter(LibrarySerializationStatusFilter.unrestricted);
    await ref.read(libraryTabSortProvider.notifier).resetSeriesSortToDefault();
    ref.invalidate(librarySeriesCatalogControllerProvider);
  }
}
