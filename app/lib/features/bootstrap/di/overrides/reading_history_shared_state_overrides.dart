import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/di/reading_history_providers.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> readingHistorySharedStateOverrides() => <Override>[
  readingHistoryCommandPortProvider.overrideWith(
    createReadingHistoryCommandPort,
  ),
  readingHistoryProgressPortProvider.overrideWith(
    createReadingHistoryProgressPort,
  ),
];
