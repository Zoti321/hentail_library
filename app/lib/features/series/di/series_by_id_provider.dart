import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/public/di/series_repository_providers.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/series/domain/series.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_by_id_provider.g.dart';

/// 系列详情页入口：按 id 单条查询（owner @ series，ADR-0042）。
///
/// 只依赖 `library_admin` public 的库 revision 信号。
@Riverpod(keepAlive: true)
Future<Series?> seriesById(Ref ref, String seriesId) {
  ref.watch(
    libraryRevisionStateProvider.select((LibraryRevisionState s) => s.revision),
  );
  final String normalizedId = seriesId.trim();
  if (normalizedId.isEmpty) {
    return Future<Series?>.value(null);
  }
  return ref.read(seriesRepoProvider).findById(normalizedId);
}
