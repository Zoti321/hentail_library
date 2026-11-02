import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';

final Provider<ReadingHistoryCommandPort> readingHistoryCommandPortProvider =
    Provider<ReadingHistoryCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'readingHistoryCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
