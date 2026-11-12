import 'package:hentai_library/shared/presentation/providers/comic_return_series_providers.dart';
import 'package:hentai_library/composition/modules/comic/comic_return_series_commands.dart';
import 'package:hentai_library/composition/modules/series/persist_series_item_sort_command.dart';
import 'package:hentai_library/composition/modules/series/series_cover_invalidation_slot.dart';
import 'package:hentai_library/composition/modules/series/series_item_membership_query.dart';
import 'package:hentai_library/composition/modules/series/series_reading_context_query.dart';
import 'package:hentai_library/features/comic/presentation/widgets/series_slot_builders.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/shared/presentation/providers/series_item_membership_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_item_sort_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_reading_context_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_slot_providers.dart';
import 'package:hentai_library/shared/presentation/providers/thumbnail_activity_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// comic / series owner：跨壳层命令/查询、UI 槽位与 return-series 栈（#457 / #493 / ADR-0042）。
List<Override> comicSeriesSharedStateOverrides() => <Override>[
  rememberComicReturnSeriesCommandProvider.overrideWith(
    createRememberComicReturnSeriesCommand,
  ),
  clearComicReturnSeriesCommandProvider.overrideWith(
    createClearComicReturnSeriesCommand,
  ),
  thumbnailBackgroundActiveStateProvider.overrideWith(
    (ref) => ref.watch(thumbnailEventCoordinatorProvider).isActive,
  ),
  findSeriesReadingContextQueryProvider.overrideWith(
    createFindSeriesReadingContextQuery,
  ),
  persistSeriesItemSortCommandProvider.overrideWith(
    createPersistSeriesItemSortCommand,
  ),
  findSeriesItemMembershipQueryProvider.overrideWith(
    createFindSeriesItemMembershipQuery,
  ),
  seriesCoverSlotProvider.overrideWithValue(buildSeriesCoverSlot),
  seriesMemberCoverSlotProvider.overrideWithValue(buildSeriesMemberCoverSlot),
  seriesMemberCardSlotProvider.overrideWithValue(buildSeriesMemberCardSlot),
  seriesMemberSelectionActionsSlotProvider.overrideWithValue(
    runSeriesMemberSelectionActions,
  ),
  seriesCoverInvalidationSlotProvider.overrideWith(
    createSeriesCoverInvalidationSlot,
  ),
];
