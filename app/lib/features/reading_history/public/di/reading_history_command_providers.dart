import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_command_port.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

/// 阅读进度写口 token（由 reading_history 生产、bootstrap 注入）。
final Provider<ReadingHistoryCommandPort> readingHistoryCommandPortProvider =
    injectedDi('readingHistoryCommandPortProvider');
