import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// [GoRouter.go] `extra` when leaving Series read for series detail.
///
/// Triggers a short fade + slight rise enter transition on `/series/:id`.
class SeriesDetailEnterFromReader {
  const SeriesDetailEnterFromReader();
}

bool seriesDetailUsesFromReaderTransition(Object? extra) =>
    extra is SeriesDetailEnterFromReader;

const Duration kSeriesDetailFromReaderTransitionDuration = Duration(
  milliseconds: 200,
);

/// Slight upward settle (~2% of page height) paired with fade-in.
const Offset kSeriesDetailFromReaderSlideBegin = Offset(0, 0.02);

/// Builds the GoRouter [Page] for `/series/:id`.
///
/// With [SeriesDetailEnterFromReader] extra → custom fade/rise enter.
/// Otherwise → platform [MaterialPage] transitions (unchanged for library entry).
Page<void> buildSeriesDetailRoutePage({
  required GoRouterState state,
  required Widget child,
}) {
  if (seriesDetailUsesFromReaderTransition(state.extra)) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: kSeriesDetailFromReaderTransitionDuration,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: kSeriesDetailFromReaderSlideBegin,
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
    );
  }
  return MaterialPage<void>(key: state.pageKey, name: state.name, child: child);
}
