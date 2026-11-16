import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:hentai_library/shared/application/contracts/persist_series_item_sort_command.dart';

/// series owner 注入 PersistSeriesItemSortCommand（#457 / ADR-0039）。
final Provider<PersistSeriesItemSortCommand>
persistSeriesItemSortCommandProvider = requiredProvider(
  'persistSeriesItemSortCommandProvider',
);
