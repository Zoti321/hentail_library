/// 应用内常用文案常量，便于后续接入 l10n 或统一修改。
abstract class AppStrings {
  AppStrings._();

  static const String libraryTitle = '漫画库';
  static const String libraryEmptyTitle = '暂无漫画';
  static const String libraryEmptyHint = '请先在「选中路径」中添加路径并扫描';
  static const String librarySeriesEmptyTitle = '暂无系列';
  static const String librarySeriesEmptyHint = '系列由扫描结果自动生成，添加路径并扫描后即可出现';
  static const String libraryNoMatchTitle = '没有匹配结果';
  static const String libraryNoMatchFilterHintComics = '当前筛选条件下没有漫画';
  static const String libraryNoMatchFilterHintSeries = '当前筛选条件下没有系列';
  static String comicCount(int n) => '$n 本';
}
