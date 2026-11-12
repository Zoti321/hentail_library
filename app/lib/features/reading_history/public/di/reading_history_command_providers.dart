import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/domain/reading_progress_commands.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

final Provider<RecordReadingProgressCommand>
recordReadingProgressCommandProvider = injectedDi(
  'recordReadingProgressCommandProvider',
);
final Provider<ReadResumePageQuery> readResumePageQueryProvider = injectedDi(
  'readResumePageQueryProvider',
);
