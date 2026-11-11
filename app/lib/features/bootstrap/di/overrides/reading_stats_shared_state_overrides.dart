import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> readingStatsSharedStateOverrides() => <Override>[
  homePageCountsPortProvider.overrideWith(createHomePageCountsPort),
  readingActivityStatsPortProvider.overrideWithValue(
    createReadingActivityStatsPort(),
  ),
  recordReadSessionActivityPortProvider.overrideWithValue(
    createRecordReadSessionActivityPort(),
  ),
];
