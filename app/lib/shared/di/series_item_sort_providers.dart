import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/series_item_sort_port.dart';

/// series owner 注入 SeriesItemSortPort（#457 / ADR-0039）。
final Provider<SeriesItemSortPort> seriesItemSortPortProvider = injectedDi(
  'seriesItemSortPortProvider',
);
