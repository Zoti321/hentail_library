import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/application/read_session_coordinator.dart';
import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/reading_history_providers.dart';
import 'package:hentai_library/shared/di/reading_stats_providers.dart';

final Provider<OpenReadSessionService> openReadSessionServiceProvider =
    Provider<OpenReadSessionService>((Ref ref) {
      return OpenReadSessionService(
        comicRepo: ref.read(comicLookupRepositoryProvider),
        pageSource: ref.read(comicPageSourcePortProvider),
        readingHistoryCommands: ref.read(readingHistoryCommandPortProvider),
        sessionPort: ref.read(nativeReaderPortProvider),
      );
    });

final Provider<ReadSessionCoordinator> readSessionCoordinatorProvider =
    Provider<ReadSessionCoordinator>((Ref ref) {
      return ReadSessionCoordinator(
        sessionService: ref.read(openReadSessionServiceProvider),
        readingHistoryCommands: ref.read(readingHistoryCommandPortProvider),
        activityCommands: ref.read(recordReadSessionActivityPortProvider),
      );
    });
