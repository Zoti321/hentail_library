import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_progress_port.dart';

final Provider<ReadingHistoryCommandPort> readingHistoryCommandPortProvider =
    Provider<ReadingHistoryCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'readingHistoryCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<ReadingHistoryProgressPort> readingHistoryProgressPortProvider =
    Provider<ReadingHistoryProgressPort>(
      (Ref ref) => throw UnimplementedError(
        'readingHistoryProgressPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
