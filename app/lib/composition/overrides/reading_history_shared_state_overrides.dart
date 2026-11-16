import 'package:hentai_library/composition/modules/reading_history/reading_progress_commands.dart';
import 'package:hentai_library/composition/modules/reading_history/reading_progress_stream.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/presentation/providers/reading_history_providers.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> readingHistorySharedStateOverrides() => <Override>[
  recordReadingProgressCommandProvider.overrideWith(
    createRecordReadingProgressCommand,
  ),
  readResumePageQueryProvider.overrideWith(createReadResumePageQuery),
  readingHistoryProgressProvider.overrideWith(
    createReadingHistoryProgressStream,
  ),
];
