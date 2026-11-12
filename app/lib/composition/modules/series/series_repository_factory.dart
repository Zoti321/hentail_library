import 'package:hentai_library/features/series/infrastructure/series_repository_impl.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
SeriesRepository createSeriesRepository() => const SeriesRepositoryImpl();
