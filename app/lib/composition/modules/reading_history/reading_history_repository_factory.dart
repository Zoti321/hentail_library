import 'package:hentai_library/features/reading_history/infrastructure/repositories/reading_history_repository_impl.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';

/// Bootstrap 注入用；consumer 仍 [readingHistoryRepoProvider]（shared/di）。
ReadingHistoryRepository createReadingHistoryRepository() =>
    const ReadingHistoryRepositoryImpl();
