import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/comic_read_lookup_port.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';
import 'package:hentai_library/shared/domain/ports/remote_library_credentials_port.dart';

/// 跨模块共享的 Repository / Port token 声明；实现由 bootstrap 经 owner `public/di` 注入。
///
/// 单归属 token 已按 ADR-0045 / ADR-0046 迁到各 owner `public/di`。

final Provider<RemoteLibraryCredentialsPort>
remoteLibraryCredentialsPortProvider = injectedDi(
  'remoteLibraryCredentialsPortProvider',
);

/// 回收站命令口：comic 消费、comic_trash 实现，两侧互引会成环，故 token 留 shared。
final Provider<ComicTrashCommandPort> comicTrashCommandPortProvider =
    injectedDi('comicTrashCommandPortProvider');

/// 阅读会话漫画元数据读取口：comic 实现、reader 消费，真源留 shared（ADR-0045）。
final Provider<ComicReadLookupPort> comicReadLookupPortProvider = injectedDi(
  'comicReadLookupPortProvider',
);
