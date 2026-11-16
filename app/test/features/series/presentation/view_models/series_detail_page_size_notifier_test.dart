import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/series/presentation/providers/series_page_size_storage_providers.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_detail_page_size_notifier.dart';

void main() {
  test(
    'loads injected preferences and normalizes before publishing and saving',
    () async {
      final saved = <int>[];
      final container = ProviderContainer(
        overrides: [
          seriesDetailPageSizeQueryProvider.overrideWithValue(() async => 50),
          setSeriesDetailPageSizeCommandProvider.overrideWithValue((
            value,
          ) async {
            saved.add(value);
          }),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(seriesDetailPageSizeProvider.future), 50);
      await container
          .read(seriesDetailPageSizeProvider.notifier)
          .setPageSize(500);
      expect(container.read(seriesDetailPageSizeProvider).requireValue, 200);
      expect(saved, [200]);
    },
  );

  test('keeps optimistic selection and exposes persistence failures', () async {
    final container = ProviderContainer(
      overrides: [
        seriesDetailPageSizeQueryProvider.overrideWithValue(() async => 50),
        setSeriesDetailPageSizeCommandProvider.overrideWithValue((_) async {
          throw StateError('write');
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(seriesDetailPageSizeProvider.future);
    await expectLater(
      container.read(seriesDetailPageSizeProvider.notifier).setPageSize(100),
      throwsStateError,
    );
    expect(container.read(seriesDetailPageSizeProvider).requireValue, 100);
  });
}
