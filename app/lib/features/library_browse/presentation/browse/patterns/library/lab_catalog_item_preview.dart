import 'package:hentai_library/shared/domain/models/enums.dart';

/// Lab 目录卡片占位文案（浏览页与详情 preview 共用）。
class LabCatalogItemPreview {
  const LabCatalogItemPreview({
    required this.title,
    required this.subtitle,
    this.listAuthor,
  });

  final String title;
  final String subtitle;
  final String? listAuthor;

  static LabCatalogItemPreview forIndex({
    required LibraryDisplayTarget displayTarget,
    required int index,
  }) {
    return switch (displayTarget) {
      LibraryDisplayTarget.comics => LabCatalogItemPreview(
        title: '示例本子 ${index + 1}',
        subtitle: '${64 + index * 8} 页',
        listAuthor: '作者 ${index % 5 + 1}',
      ),
      LibraryDisplayTarget.series => LabCatalogItemPreview(
        title: '示例系列 ${index + 1}',
        subtitle: '${3 + index % 8} 本漫画',
        listAuthor: '连载中',
      ),
    };
  }
}
