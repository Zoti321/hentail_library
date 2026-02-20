import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/enums/enums.dart';

part 'sync_progress.freezed.dart';

/// 同步进度，用于 UI 展示。
@freezed
abstract class SyncProgress with _$SyncProgress {
  const factory SyncProgress({
    required SyncPhase phase,
    String? currentPath,
    @Default(0) int current,
    @Default(0) int total,
    required String message,
  }) = _SyncProgress;
}
