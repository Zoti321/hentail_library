import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/contracts/persist_series_item_sort_command.dart';

/// series owner 注入 PersistSeriesItemSortCommand（#457 / ADR-0039）。
final Provider<PersistSeriesItemSortCommand>
persistSeriesItemSortCommandProvider = injectedDi(
  'persistSeriesItemSortCommandProvider',
);
