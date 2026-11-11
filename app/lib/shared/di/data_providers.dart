import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/shared/domain/ports/remote_library_credentials_port.dart';

/// 跨模块共享的 Repository / Port token 声明；实现由 bootstrap 经 owner `public/di` 注入。
///
/// 单归属 token 已按 ADR-0045 迁到各 owner `public/di`（#515）。

final Provider<RemoteLibraryCredentialsPort>
remoteLibraryCredentialsPortProvider = injectedDi(
  'remoteLibraryCredentialsPortProvider',
);

/// 回收站命令口：comic 消费、comic_trash 实现，两侧互引会成环，故 token 留 shared。
final Provider<ComicTrashCommandPort> comicTrashCommandPortProvider =
    injectedDi('comicTrashCommandPortProvider');

/// AppSetting Repository：app_settings / library_admin / reader 三方消费，
/// 且 app_settings 已 import 二者 public，迁走会成环，故 token 留 shared（#515）。
final Provider<AppSettingRepository> appSettingRepoProvider = injectedDi(
  'appSettingRepoProvider',
);

/// comic Repository：reader / series 消费会被 ADR-0036 禁止边挡下，token 留 shared。
final Provider<ComicThumbnailRepository> comicThumbnailRepoProvider =
    injectedDi('comicThumbnailRepoProvider');

final Provider<ComicLookupRepository> comicLookupRepositoryProvider =
    injectedDi('comicLookupRepositoryProvider');
