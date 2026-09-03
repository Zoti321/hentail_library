/// Comic Language（文本语言）规范英文名；空列表表示未设。见 `CONTEXT.md`。
abstract final class ComicLanguageNames {
  ComicLanguageNames._();

  static const String chinese = 'Chinese';
  static const String japanese = 'Japanese';
  static const String english = 'English';
  static const String korean = 'Korean';
  static const String spanish = 'Spanish';
  static const String other = 'Other';

  /// v1 闭集；库内可另存闭集外的值并原样展示。
  static const List<String> closedSet = <String>[
    chinese,
    japanese,
    english,
    korean,
    spanish,
    other,
  ];
}

/// 规范名 → 展示文案；不在 [closedLabels] 中的值原样返回。
String comicLanguageDisplayLabel(
  String canonical, {
  required Map<String, String> closedLabels,
}) {
  return closedLabels[canonical] ?? canonical;
}

/// 多项以 [separator] 拼接（默认 `|`）。
String formatComicLanguagesDisplay(
  Iterable<String> canonical, {
  required Map<String, String> closedLabels,
  String separator = '|',
}) {
  return canonical
      .map(
        (String name) =>
            comicLanguageDisplayLabel(name, closedLabels: closedLabels),
      )
      .join(separator);
}
