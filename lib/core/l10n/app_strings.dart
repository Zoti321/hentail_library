/// 应用内常用文案常量，便于后续接入 l10n 或统一修改。
abstract class AppStrings {
  AppStrings._();

  static const String libraryTitle = '漫画库';
  static const String libraryEmptyTitle = '暂无漫画';
  static const String libraryEmptyHint = '请先在「本地目录」中添加文件夹并扫描';
  static String comicCount(int n) => '$n 本';
}
