import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';

/// Series 仓储 token：owner 在 `features/series/public/di/` 声明（ADR-0042）。
///
/// 实现由 bootstrap 组合根注入（`createSeriesRepository`）；
/// `shared/di` 不再持有模块私有 token。
final Provider<SeriesRepository> seriesRepoProvider =
    Provider<SeriesRepository>(
      (Ref ref) => throw UnimplementedError(
        'seriesRepoProvider 未注入，请在 bootstrap 中 override',
      ),
    );
