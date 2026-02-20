/// 应用内常用文案常量，便于后续接入 l10n 或统一修改。
abstract class AppStrings {
  AppStrings._();

  static const String libraryTitle = '漫画库';
  static const String libraryEmptyTitle = '暂无漫画';
  static const String libraryEmptyHint = '请先在「选中路径」中添加路径并扫描';
  static const String libraryNoMatchTitle = '没有匹配结果';
  static String libraryNoMatchHint(String query) => '没有符合“$query”的漫画';
  static String comicCount(int n) => '$n 本';
}
