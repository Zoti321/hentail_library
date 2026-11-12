import 'package:hentai_library/shared/presentation/providers/comic_read_query_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/application/read_session_application_service.dart';
import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
import 'package:hentai_library/features/reader/public/providers/reader_dependencies.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/features/reading_stats/public.dart';

final Provider<OpenReadSessionService> openReadSessionServiceProvider =
    Provider<OpenReadSessionService>((Ref ref) {
      return OpenReadSessionService(
        comicLookup: ref.read(comicReadQueryProvider),
        pageSource: ref.read(comicPageSourcePortProvider),
        readResumePage: ref.read(readResumePageQueryProvider),
        sessionPort: ref.read(nativeReaderPortProvider),
      );
    });

final Provider<ReadSessionApplicationService>
readSessionApplicationServiceProvider = Provider<ReadSessionApplicationService>(
  (Ref ref) {
    return ReadSessionApplicationService(
      sessionService: ref.read(openReadSessionServiceProvider),
      recordProgress: ref.read(recordReadingProgressCommandProvider),
      recordActivity: ref.read(recordReadSessionActivityCommandProvider),
    );
  },
);
