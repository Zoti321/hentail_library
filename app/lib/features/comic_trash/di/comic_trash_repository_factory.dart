import 'package:hentai_library/features/comic_trash/data/adapters/comic_trash_frb_adapter.dart';
import 'package:hentai_library/features/comic_trash/data/repositories/comic_trash_repository_impl.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
ComicTrashRepository createComicTrashRepository() =>
    const ComicTrashRepositoryImpl();

/// 供单测替换 [ComicTrashFrbAdapter] 时使用。
ComicTrashRepository createComicTrashRepositoryWithAdapter(
  ComicTrashFrbAdapter adapter,
) => ComicTrashRepositoryImpl(adapter: adapter);
