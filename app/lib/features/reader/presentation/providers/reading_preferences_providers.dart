import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/app_settings/public/reading_preferences_schema.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/application/reading_preferences_acl.dart';

/// 阅读偏好（L2 领域值对象）的唯一读入口。
///
/// 内部 watch L1 记录；尚未加载时给出全默认值，经 ACL 解码后对外。
/// `unknownIds` 非空时在**本层**上报一次 warn（ACL 保持纯函数）。
final Provider<ReadingPreferences> readingPreferencesProvider =
    Provider<ReadingPreferences>((Ref ref) {
      final ReadingPreferencesRecord? record = ref.watch(
        readingPreferencesRecordProvider,
      );
      if (record == null) {
        return const ReadingPreferences.defaults();
      }
      final DecodedReadingPreferences decoded = ReadingPreferencesAcl.decode(
        record,
      );
      _reportedUnknownIds.report(decoded.unknownIds);
      return decoded.value;
    });

/// 只上报「首次出现」的未知 id，避免每次 rebuild 刷屏。
final _UnknownIdReporter _reportedUnknownIds = _UnknownIdReporter();

final class _UnknownIdReporter {
  final Set<String> _seen = <String>{};

  void report(List<String> unknownIds) {
    final List<String> fresh = <String>[
      for (final String id in unknownIds)
        if (_seen.add(id)) id,
    ];
    if (fresh.isEmpty) {
      return;
    }
    AppLog.core('reading_preferences')
        .warning('未知阅读偏好 id 已回退默认值: ${fresh.join(', ')}');
  }
}
