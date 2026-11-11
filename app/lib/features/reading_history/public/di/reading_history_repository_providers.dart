import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

/// reading_history owner 的 Repository token（#515；实现由 bootstrap 注入）。

final Provider<ReadingHistoryRepository> readingHistoryRepoProvider =
    injectedDi('readingHistoryRepoProvider');
