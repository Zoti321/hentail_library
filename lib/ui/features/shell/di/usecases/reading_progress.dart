import 'package:hentai_library/domain/use_cases/record_reading_progress_usecase.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_progress.g.dart';

@Riverpod(keepAlive: true)
RecordReadingProgressUseCase recordReadingProgressUseCase(Ref ref) {
  return RecordReadingProgressUseCase(ref.read(readingHistoryRepoProvider));
}
