import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

/// Widgetbook / 预览用示例漫画详情。
abstract final class ComicDetailPagePreviewData {
  static ComicDetailViewObject sample() {
    return const ComicDetailViewObject(
      title: '葬送的芙莉莲',
      description:
          '这是一段用于 Lab 预览的简介文案。最多显示四行，超出部分以省略号截断。'
          '实际生产环境由漫画元数据填充，并可后续扩展「展开全文」交互。',
      pageCount: 128,
      publishedLabel: '2019-04-17',
      parodies: <String>['迷宫饭'],
      authors: <AuthorRef>[
        AuthorRef(id: 101, name: '示例作者甲'),
        AuthorRef(id: 102, name: '示例作者乙'),
      ],
      characters: <String>['芙莉莲', '费伦', '修塔尔克'],
      tags: <String>['奇幻', '冒险', '长篇', '连载中', '图书馆'],
      resourceFormat: 'ZIP',
      resourceSizeLabel: '42.5 MB',
      resourcePath: r'D:\library\examples\frieren.zip',
      addedAtLabel: '2024-06-12 18:30',
      updatedAtLabel: '2026-03-01 09:15',
      showSeriesNav: true,
      seriesCatalog: <String>[
        '葬送的芙莉莲 第 1 卷',
        '葬送的芙莉莲 第 2 卷',
        '葬送的芙莉莲 第 3 卷',
        '葬送的芙莉莲 番外篇',
      ],
      seriesCurrentIndex: 0,
    );
  }
}
