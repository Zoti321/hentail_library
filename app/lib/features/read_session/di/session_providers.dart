import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/read_session/domain/read_session_coordinator.dart';
import 'package:hentai_library/features/read_session/domain/reader_session_service.dart';
import 'package:hentai_library/shared/di/data_providers.dart';

final Provider<ReaderSessionService> readerSessionServiceProvider =
    Provider<ReaderSessionService>((Ref ref) {
      return ReaderSessionService(
        comicRepo: ref.read(comicLookupRepositoryProvider),
        pageSource: ref.read(comicPageSourcePortProvider),
        readingHistoryRepo: ref.read(readingHistoryRepoProvider),
        sessionPort: ref.read(readerSessionPortProvider),
      );
    });

final Provider<ReadSessionCoordinator> readSessionCoordinatorProvider =
    Provider<ReadSessionCoordinator>((Ref ref) {
      return ReadSessionCoordinator(
        sessionService: ref.read(readerSessionServiceProvider),
        readingHistoryRepo: ref.read(readingHistoryRepoProvider),
      );
    });
