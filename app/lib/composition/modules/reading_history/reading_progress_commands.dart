import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/application/record_reading_progress_use_case.dart';
import 'package:hentai_library/features/reading_history/public/providers/reading_history_repository_providers.dart';
import 'package:hentai_library/features/reading_history/domain/reading_progress_commands.dart';

RecordReadingProgressCommand createRecordReadingProgressCommand(Ref ref) =>
    RecordReadingProgressUseCase(ref.read(readingHistoryRepoProvider)).call;
ReadResumePageQuery createReadResumePageQuery(Ref ref) =>
    (id) async =>
        (await ref.read(readingHistoryRepoProvider).getByComicId(id))
            ?.pageIndex;
