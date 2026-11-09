import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/read_session/application/read_session_coordinator.dart';
import 'package:hentai_library/features/read_session/application/reader_session_service.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/reading_history_providers.dart';
import 'package:hentai_library/shared/di/reading_stats_providers.dart';

final Provider<ReaderSessionService> readerSessionServiceProvider =
    Provider<ReaderSessionService>((Ref ref) {
      return ReaderSessionService(
        comicRepo: ref.read(comicLookupRepositoryProvider),
        pageSource: ref.read(comicPageSourcePortProvider),
        readingHistoryCommands: ref.read(readingHistoryCommandPortProvider),
        sessionPort: ref.read(readerSessionPortProvider),
      );
    });

final Provider<ReadSessionCoordinator> readSessionCoordinatorProvider =
    Provider<ReadSessionCoordinator>((Ref ref) {
      return ReadSessionCoordinator(
        sessionService: ref.read(readerSessionServiceProvider),
        readingHistoryCommands: ref.read(readingHistoryCommandPortProvider),
        activityCommands: ref.read(recordReadSessionActivityPortProvider),
      );
    });
