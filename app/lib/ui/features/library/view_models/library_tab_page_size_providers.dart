import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_tab_page_size_providers.g.dart';

@Riverpod(keepAlive: true)
int libraryActivePageSize(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  final AsyncValue<LibraryTabPageSizeSettings> settingsAsync = ref.watch(
    libraryTabPageSizeProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabPageSizeSettings settings) =>
        pageSizeForTarget(settings, target),
    orElse: () => kDefaultPageSize,
  );
}

@Riverpod(keepAlive: true)
int libraryComicsTabPageSize(Ref ref) {
  final AsyncValue<LibraryTabPageSizeSettings> settingsAsync = ref.watch(
    libraryTabPageSizeProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabPageSizeSettings settings) => settings.comics,
    orElse: () => kDefaultPageSize,
  );
}

@Riverpod(keepAlive: true)
int librarySeriesTabPageSize(Ref ref) {
  final AsyncValue<LibraryTabPageSizeSettings> settingsAsync = ref.watch(
    libraryTabPageSizeProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabPageSizeSettings settings) => settings.series,
    orElse: () => kDefaultPageSize,
  );
}
