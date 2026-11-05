import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/series_reading_context_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// comic / series owner：跨壳层 Port 与 return-series 栈（#457）。
List<Override> comicSeriesSharedStateOverrides() => <Override>[
  comicDetailReturnSeriesPortProvider.overrideWith(
    createComicDetailReturnSeriesPort,
  ),
  seriesReadingContextPortProvider.overrideWith(
    createSeriesReadingContextPort,
  ),
];
