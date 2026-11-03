import 'package:hentai_library/features/library_browse/data/series/series_repository_impl.dart';
import 'package:hentai_library/features/library_browse/domain/series/series_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
SeriesRepository createSeriesRepository() => const SeriesRepositoryImpl();
