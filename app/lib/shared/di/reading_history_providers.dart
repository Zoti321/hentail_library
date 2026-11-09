import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_progress_port.dart';

final Provider<ReadingHistoryCommandPort> readingHistoryCommandPortProvider =
    injectedDi('readingHistoryCommandPortProvider');

final Provider<ReadingHistoryProgressPort> readingHistoryProgressPortProvider =
    injectedDi('readingHistoryProgressPortProvider');
