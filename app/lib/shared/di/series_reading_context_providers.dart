import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/series_reading_context_port.dart';

Never _unimplemented(String name) =>
    throw UnimplementedError('$name 未注入，请在 bootstrap 中 override');

/// 系列连读上下文窄读口（#457）；实现由 series owner bootstrap override 注入。
final Provider<SeriesReadingContextPort> seriesReadingContextPortProvider =
    Provider<SeriesReadingContextPort>(
      (Ref ref) => _unimplemented('seriesReadingContextPortProvider'),
    );
