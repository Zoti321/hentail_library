/// 历史列表关键字查询规约：空白视为「无过滤」。
abstract final class ReadingHistorySearchSpecification {
  ReadingHistorySearchSpecification._();

  static String? normalizeKeyword(String? keyword) {
    final String? trimmed = keyword?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
