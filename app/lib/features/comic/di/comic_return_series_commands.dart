import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/shared/domain/contracts/comic_return_series_commands.dart';

RememberComicReturnSeriesCommand createRememberComicReturnSeriesCommand(
  Ref ref,
) =>
    (id) => ref.read(comicDetailReturnSeriesProvider.notifier).remember(id);
ClearComicReturnSeriesCommand createClearComicReturnSeriesCommand(Ref ref) =>
    () => ref.read(comicDetailReturnSeriesProvider.notifier).clear();
