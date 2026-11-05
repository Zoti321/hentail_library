import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/data/comic_thumbnail_repository_impl.dart';
import 'package:hentai_library/features/comic/domain/comic_thumbnail_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
ComicThumbnailRepository createComicThumbnailRepository(Ref ref) =>
    ComicThumbnailRepositoryImpl(
      remoteCredentials: ref.read(remoteLibraryCredentialsPortProvider),
    );
