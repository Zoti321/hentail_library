import 'package:hentai_library/shared/presentation/providers/comic_read_query_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/application/manage_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:hentai_library/features/reader/public/providers/reader_dependencies.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/features/reading_stats/public.dart';

final Provider<OpenReadSessionUseCase> openReadSessionUseCaseProvider =
    Provider<OpenReadSessionUseCase>((Ref ref) {
      return OpenReadSessionUseCase(
        comicLookup: ref.read(comicReadQueryProvider),
        pageSource: ref.read(comicPageSourcePortProvider),
        readResumePage: ref.read(readResumePageQueryProvider),
        sessionPort: ref.read(nativeReaderPortProvider),
        imageSetReadPort: ref.read(imageSetReadPortProvider),
      );
    });

final Provider<ManageReadSessionUseCase>
manageReadSessionUseCaseProvider = Provider<ManageReadSessionUseCase>(
  (Ref ref) {
    return ManageReadSessionUseCase(
      openReadSession: ref.read(openReadSessionUseCaseProvider),
      recordProgress: ref.read(recordReadingProgressCommandProvider),
      recordActivity: ref.read(recordReadSessionActivityCommandProvider),
    );
  },
);
