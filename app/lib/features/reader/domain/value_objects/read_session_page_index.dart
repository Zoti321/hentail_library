import 'package:hentai_library/features/read_session/domain/read_session_rule_exceptions.dart';

/// 阅读会话页码值对象（1-based）。
final class ReadSessionPageIndex {
  const ReadSessionPageIndex._(this.value);

  final int value;

  factory ReadSessionPageIndex.tryParse(int raw, {required int totalPages}) {
    if (raw < 1) {
      throw ReadSessionRuleException.invalidPageIndex(raw);
    }
    if (totalPages > 0 && raw > totalPages) {
      throw ReadSessionRuleException.pageIndexExceedsTotal(
        pageIndex: raw,
        totalPages: totalPages,
      );
    }
    return ReadSessionPageIndex._(raw);
  }
}
