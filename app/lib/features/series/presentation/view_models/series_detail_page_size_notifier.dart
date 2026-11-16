import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/series/presentation/providers/series_page_size_storage_providers.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';

part 'series_detail_page_size_notifier.g.dart';

@Riverpod(keepAlive: true)
class SeriesDetailPageSizeNotifier extends _$SeriesDetailPageSizeNotifier {
  @override
  Future<int> build() => ref.read(seriesDetailPageSizeQueryProvider)();

  Future<void> setPageSize(int pageSize) async {
    final int normalized = normalizeLibraryPageSize(pageSize);
    state = AsyncData<int>(normalized);
    await ref.read(setSeriesDetailPageSizeCommandProvider)(normalized);
  }
}
