import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/series_detail_route_page.dart';

class _FakeGoRouterState extends Fake implements GoRouterState {
  _FakeGoRouterState({required this.extra});

  @override
  final Object? extra;

  @override
  ValueKey<String> get pageKey => const ValueKey<String>('series-test');

  @override
  String? get name => '系列详情';
}

void main() {
  test('seriesDetailUsesFromReaderTransition detects marker only', () {
    expect(
      seriesDetailUsesFromReaderTransition(const SeriesDetailEnterFromReader()),
      isTrue,
    );
    expect(seriesDetailUsesFromReaderTransition(null), isFalse);
    expect(seriesDetailUsesFromReaderTransition('fromReader'), isFalse);
  });

  test('buildSeriesDetailRoutePage uses custom page when exiting reader', () {
    final Page<void> page = buildSeriesDetailRoutePage(
      state: _FakeGoRouterState(extra: const SeriesDetailEnterFromReader()),
      child: const SizedBox(),
    );

    expect(page, isA<CustomTransitionPage<void>>());
    final CustomTransitionPage<void> custom =
        page as CustomTransitionPage<void>;
    expect(
      custom.transitionDuration,
      kSeriesDetailFromReaderTransitionDuration,
    );
  });

  test('buildSeriesDetailRoutePage uses MaterialPage for normal entry', () {
    final Page<void> page = buildSeriesDetailRoutePage(
      state: _FakeGoRouterState(extra: null),
      child: const SizedBox(),
    );

    expect(page, isA<MaterialPage<void>>());
  });
}
