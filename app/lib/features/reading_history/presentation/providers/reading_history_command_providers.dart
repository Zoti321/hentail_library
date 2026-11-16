import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/domain/reading_progress_commands.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<RecordReadingProgressCommand>
recordReadingProgressCommandProvider = requiredProvider(
  'recordReadingProgressCommandProvider',
);
final Provider<ReadResumePageQuery> readResumePageQueryProvider =
    requiredProvider('readResumePageQueryProvider');
