import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_return_series_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('ComicDetailReturnSeries', () {
    test('remember keeps series source for later back', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(comicDetailReturnSeriesProvider.notifier)
          .remember('series-a');

      expect(container.read(comicDetailReturnSeriesProvider), 'series-a');
    });

    test('clear drops remembered series source', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(comicDetailReturnSeriesProvider.notifier)
          .remember('series-a');
      container.read(comicDetailReturnSeriesProvider.notifier).clear();

      expect(container.read(comicDetailReturnSeriesProvider), isNull);
    });

    test('remember after clear replaces prior source', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(comicDetailReturnSeriesProvider.notifier)
          .remember('series-a');
      container.read(comicDetailReturnSeriesProvider.notifier).clear();
      container
          .read(comicDetailReturnSeriesProvider.notifier)
          .remember('series-b');

      expect(container.read(comicDetailReturnSeriesProvider), 'series-b');
    });
  });
}
