import 'package:hentai_library/features/library_admin/public/providers/remote_library_credentials_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/infrastructure/comic_thumbnail_repository_impl.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_thumbnail_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
ComicThumbnailRepository createComicThumbnailRepository(Ref ref) =>
    ComicThumbnailRepositoryImpl(
      remoteCredentials: ref.read(remoteLibraryCredentialsPortProvider),
    );
