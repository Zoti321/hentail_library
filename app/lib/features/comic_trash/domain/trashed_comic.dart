import 'package:hentai_library/features/comic/public/comic.dart';

/// 处于 Comic trash 的漫画（回收站页列表项）。
typedef TrashedComic = ({
  Comic comic,
  DateTime deletedAt,
  String libraryName,

  /// 所属 Library 为 Remote（Comic purge 仅移出库，不删远程 Resource）。
  bool isRemote,
});

/// 回收站中的漫画总数及 Local / Remote 拆分。
typedef TrashedComicCounts = ({int total, int local, int remote});

/// Comic purge 逐本处理的汇总结果。
typedef ComicPurgeResult = ({
  int succeeded,
  int failed,
  List<String> errorSamples,
});
