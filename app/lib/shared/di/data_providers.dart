import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/domain/contracts/trash_comics_command.dart';

/// 跨模块共享的 Repository / Command / Query token 声明；实现由 bootstrap 经 owner `public/di` 注入。
///
/// 单归属 token 已按 ADR-0045 / ADR-0046 迁到各 owner `public/di`。

/// 回收站命令口：comic 消费、comic_trash 实现，两侧互引会成环，故 token 留 shared。
final Provider<TrashComicsCommand> trashComicsCommandProvider = injectedDi(
  'trashComicsCommandProvider',
);

/// 阅读会话漫画元数据读取口：comic 实现、reader 消费，真源留 shared（ADR-0045）。
final Provider<ComicReadQuery> comicReadQueryProvider = injectedDi(
  'comicReadQueryProvider',
);
