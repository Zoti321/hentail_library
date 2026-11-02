import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/shared/di/author_detail_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:riverpod/misc.dart' show Override;

/// library_browse owner：Port 工厂与 catalog 投影（#435）。
List<Override> libraryBrowseSharedStateOverrides() => <Override>[
  comicDetailReturnSeriesPortProvider.overrideWith(
    createComicDetailReturnSeriesPort,
  ),
  authorDetailPortProvider.overrideWith(createAuthorDetailPort),
  libraryComicAgeRestrictionStateProvider.overrideWith(
    (Ref ref) => ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.ageRestriction ??
            LibraryAgeRestrictionFilter.unrestricted,
      ),
    ),
  ),
];
