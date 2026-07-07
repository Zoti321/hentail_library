import 'package:hentai_library/data/repositories/app_setting_repository_impl.dart';
import 'package:hentai_library/data/repositories/author_repository_impl.dart';
import 'package:hentai_library/data/repositories/comic_thumbnail_repository_impl.dart';
import 'package:hentai_library/data/repositories/comic_repository_impl.dart';
import 'package:hentai_library/data/repositories/path_repository_impl.dart';
import 'package:hentai_library/data/repositories/reading_history_repository_impl.dart';
import 'package:hentai_library/data/repositories/series_reading_history_repository_impl.dart';
import 'package:hentai_library/data/repositories/series_repository_impl.dart';
import 'package:hentai_library/data/repositories/home_page_repository_impl.dart';
import 'package:hentai_library/data/repositories/tag_repository_impl.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/repositories/series_reading_history_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/domain/repositories/tag_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repos.g.dart';

@Riverpod(keepAlive: true)
ComicThumbnailRepository comicThumbnailRepo(Ref ref) =>
    const ComicThumbnailRepositoryImpl();

@Riverpod(keepAlive: true)
ComicRepository comicRepo(Ref ref) => const ComicRepositoryImpl();

@Riverpod(keepAlive: true)
SeriesRepository seriesRepo(Ref ref) => const SeriesRepositoryImpl();

@Riverpod(keepAlive: true)
TagRepository tagRepo(Ref ref) => const TagRepositoryImpl();

@Riverpod(keepAlive: true)
AuthorRepository authorRepo(Ref ref) => const AuthorRepositoryImpl();

@Riverpod(keepAlive: true)
PathRepository pathRepo(Ref ref) => const PathRepositoryImpl();

@Riverpod(keepAlive: true)
ReadingHistoryRepository readingHistoryRepo(Ref ref) =>
    const ReadingHistoryRepositoryImpl();

@Riverpod(keepAlive: true)
SeriesReadingHistoryRepository seriesReadingHistoryRepo(Ref ref) =>
    const SeriesReadingHistoryRepositoryImpl();

@Riverpod(keepAlive: true)
AppSettingRepository appSettingRepo(Ref ref) => AppSettingRepositoryImpl();

@Riverpod(keepAlive: true)
HomePageRepository homePageRepo(Ref ref) => const HomePageRepositoryImpl();
