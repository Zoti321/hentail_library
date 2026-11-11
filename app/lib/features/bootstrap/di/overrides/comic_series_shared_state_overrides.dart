import 'package:hentai_library/features/comic/di/series_slot_impls.dart';
import 'package:hentai_library/features/comic/di/thumbnail_activity_port.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/series_item_membership_providers.dart';
import 'package:hentai_library/shared/di/series_item_sort_providers.dart';
import 'package:hentai_library/shared/di/series_reading_context_providers.dart';
import 'package:hentai_library/shared/di/series_slot_providers.dart';
import 'package:hentai_library/shared/di/thumbnail_activity_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// comic / series owner：跨壳层 Port、UI 槽位与 return-series 栈（#457 / #493 / ADR-0042）。
List<Override> comicSeriesSharedStateOverrides() => <Override>[
  comicDetailReturnSeriesPortProvider.overrideWith(
    createComicDetailReturnSeriesPort,
  ),
  thumbnailActivityPortProvider.overrideWith(createThumbnailActivityPort),
  seriesReadingContextPortProvider.overrideWith(createSeriesReadingContextPort),
  seriesItemSortPortProvider.overrideWith(createSeriesItemSortPort),
  seriesItemMembershipPortProvider.overrideWith(createSeriesItemMembershipPort),
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
