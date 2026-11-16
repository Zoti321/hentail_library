/// 库浏览 ↔ 详情、系列 ↔ 漫画详情的封面 Hero（对齐 Kazumi 共享封面飞入）。
abstract final class CatalogCoverHero {
  static Object comicTag(String comicId) => 'comic-cover:$comicId';

  static Object seriesTag(String seriesId) => 'series-cover:$seriesId';
}
