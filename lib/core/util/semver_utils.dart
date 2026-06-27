/// 语义化版本比较（仅比较 major.minor.patch，忽略 build 与 v 前缀）。
abstract final class SemverUtils {
  static String normalizeVersion(String raw) {
    final String trimmed = raw.trim();
    final String withoutPrefix = trimmed.startsWith('v') || trimmed.startsWith('V')
        ? trimmed.substring(1)
        : trimmed;
    return withoutPrefix.split('+').first;
  }

  static List<int> parseParts(String raw) {
    final String normalized = normalizeVersion(raw);
    return normalized
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList();
  }

  static bool isGreaterThan(String left, String right) {
    final List<int> leftParts = parseParts(left);
    final List<int> rightParts = parseParts(right);
    final int length = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;
    for (int index = 0; index < length; index++) {
      final int leftValue = index < leftParts.length ? leftParts[index] : 0;
      final int rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue > rightValue) {
        return true;
      }
      if (leftValue < rightValue) {
        return false;
      }
    }
    return false;
  }
}
