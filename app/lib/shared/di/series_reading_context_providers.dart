import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/contracts/find_series_reading_context_query.dart';

/// 系列连读上下文窄读口（#457）；实现由 series owner bootstrap override 注入。
final Provider<FindSeriesReadingContextQuery>
findSeriesReadingContextQueryProvider = injectedDi(
  'findSeriesReadingContextQueryProvider',
);
