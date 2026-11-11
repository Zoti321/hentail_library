import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/application/series_item_sort_service.dart';
import 'package:hentai_library/features/series/public/di/series_repository_providers.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/domain/ports/series_item_sort_port.dart';

SeriesItemSortPort createSeriesItemSortPort(Ref ref) => SeriesItemSortService(
  repository: ref.read(seriesRepoProvider),
  events: ref.read(domainEventBusProvider),
);
