import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_detail_page_size_providers.g.dart';

@Riverpod(keepAlive: true)
int seriesDetailActivePageSize(Ref ref) {
  final AsyncValue<int> pageSizeAsync = ref.watch(seriesDetailPageSizeProvider);
  return pageSizeAsync.maybeWhen(
    data: (int value) => value,
    orElse: () => kDefaultPageSize,
  );
}
