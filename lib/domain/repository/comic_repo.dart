import "../entity/entities.dart";

abstract class ComicRepository {
  // 监听并聚合漫画实体及其关联的卷、章、标签数据。将扁平记录组装为树状响应式流
  Stream<List<Comic>> watchComicAggregate();

  // 获取漫画及其关联数据的聚合视图
  Future<List<Comic>> getComicAggregate();

  // 根据 id 获取单本漫画聚合，不存在时返回 null
  Future<Comic?> findById(String comicId);

  // 扫描指定目录并将漫画资源与本地数据库进行同步。返回扫描报告，取消时返回带 cancelled 的报告。
  Future<SyncReport?> ingestComicResources(
    List<String> dirs, {
    bool Function()? isCancelled,
    void Function(SyncProgress)? onProgress,
  });

  // 更新漫画的元数据及分类标签等信息
  Future<void> updateComicMetaData(String comicId, ComicMetadataForm data);

  // 章节、卷归档到目标漫画（使用表单封装目标 comicId 与待归档的 chapterIds）
  Future<void> archiveChaptersToComic(ComicArchiveForm form);

  // 增加漫画的阅读次数
  Future<void> incrementReadCount(String comicId);
}
