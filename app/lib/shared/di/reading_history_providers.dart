import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_progress_port.dart';

/// 库浏览封面进度 token。
///
/// ADR-0045 可达性豁免：消费方 `comic` 与 `reading_history` 已有
/// `reading_history → comic/public` 边，若 token 迁入 reading_history public
/// 会形成 public 环，因此 Port 与 token 留在 shared。
final Provider<ReadingHistoryProgressPort> readingHistoryProgressPortProvider =
    injectedDi('readingHistoryProgressPortProvider');
