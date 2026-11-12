import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/shared/di/author_detail_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// library_browse 壳：作者详情命令 与 catalog 年龄投影（#435 / #457）。
List<Override> libraryBrowseSharedStateOverrides() => <Override>[
  openAuthorByIdCommandProvider.overrideWith(createOpenAuthorByIdCommand),
  openAuthorByNameCommandProvider.overrideWith(createOpenAuthorByNameCommand),
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
