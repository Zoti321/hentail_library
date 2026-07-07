import 'package:hentai_library/data/services/app_update/app_update_service.dart';
import 'package:hentai_library/domain/reading/read_session_coordinator.dart';
import 'package:hentai_library/domain/reading/reader_session_service.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'services.g.dart';

@Riverpod(keepAlive: true)
AppUpdateService appUpdateService(Ref ref) => AppUpdateService();

@Riverpod(keepAlive: true)
ReaderSessionService readerSessionService(Ref ref) => ReaderSessionService(
  comicRepo: ref.read(comicRepoProvider),
  pageSource: ref.read(comicPageSourcePortProvider),
  readingHistoryRepo: ref.read(readingHistoryRepoProvider),
  sessionPort: ref.read(readerSessionPortProvider),
);

@Riverpod(keepAlive: true)
ReadSessionCoordinator readSessionCoordinator(Ref ref) =>
    ReadSessionCoordinator(
      sessionService: ref.read(readerSessionServiceProvider),
      readingHistoryRepo: ref.read(readingHistoryRepoProvider),
      seriesReadingHistoryRepo: ref.read(seriesReadingHistoryRepoProvider),
    );
