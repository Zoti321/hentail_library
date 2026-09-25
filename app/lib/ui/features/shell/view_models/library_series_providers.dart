import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_series_providers.g.dart';

/// 系列详情页入口：按 id 单条查询，依赖 [libraryRevisionProvider] 在 sync/编辑后刷新。
@Riverpod(keepAlive: true)
Future<Series?> seriesById(Ref ref, String seriesId) {
  ref.watch(
    libraryRevisionProvider.select((LibraryRevisionState s) => s.revision),
  );
  final String normalizedId = seriesId.trim();
  if (normalizedId.isEmpty) {
    return Future<Series?>.value(null);
  }
  return ref.read(seriesRepoProvider).findById(normalizedId);
}
