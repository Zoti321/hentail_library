import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/application/persist_series_item_sort_use_case.dart';
import 'package:hentai_library/features/series/public/providers/series_repository_providers.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/application/contracts/persist_series_item_sort_command.dart';

PersistSeriesItemSortCommand createPersistSeriesItemSortCommand(Ref ref) =>
    PersistSeriesItemSortUseCase(
      repository: ref.read(seriesRepoProvider),
      events: ref.read(domainEventBusProvider),
    ).call;
