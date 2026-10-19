import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/shared/domain/library/comic_detail_return_series_port.dart';

/// library_browse 对 [ComicDetailReturnSeriesPort] 的实现（#261d）。
///
/// 由 bootstrap 通过 [comicDetailReturnSeriesPortProvider] 的 `overrideWith` 注入。
class _ComicDetailReturnSeriesAdapter implements ComicDetailReturnSeriesPort {
  _ComicDetailReturnSeriesAdapter(this._ref);

  final Ref _ref;

  @override
  void clear() => _ref.read(comicDetailReturnSeriesProvider.notifier).clear();
}

ComicDetailReturnSeriesPort createComicDetailReturnSeriesPort(Ref ref) =>
    _ComicDetailReturnSeriesAdapter(ref);
