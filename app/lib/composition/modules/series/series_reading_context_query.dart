import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/public/providers/series_repository_providers.dart';
import 'package:hentai_library/shared/application/contracts/find_series_reading_context_query.dart';

FindSeriesReadingContextQuery createFindSeriesReadingContextQuery(Ref ref) =>
    ref.read(seriesRepoProvider).getReadingContextByComicId;
