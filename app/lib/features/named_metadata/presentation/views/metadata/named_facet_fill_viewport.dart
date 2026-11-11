import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Near-bottom / fill-viewport threshold shared with scroll-driven load-more.
const double kNamedFacetLoadMoreExtentThreshold = 240;

/// Cap automatic fill-viewport [loadMore] chains per facet enter / viewport resize.
const int kNamedFacetFillViewportMaxAutoPages = 3;

/// Whether Named facet management should auto-call [loadMore] after layout.
///
/// True when more pages remain, the list is not searching/loading, the last
/// page did not error, and the viewport is already near the bottom or not
/// meaningfully scrollable.
bool namedFacetShouldAutoLoadMore({
  required bool hasMore,
  required bool hasSearchQuery,
  required bool isLoading,
  required bool isLoadingMore,
  required bool hasError,
  required double maxScrollExtent,
  required double pixels,
  double threshold = kNamedFacetLoadMoreExtentThreshold,
}) {
  if (hasSearchQuery || !hasMore || isLoading || isLoadingMore || hasError) {
    return false;
  }
  if (maxScrollExtent <= 0) {
    return true;
  }
  return maxScrollExtent - pixels <= threshold;
}

/// Schedules fill-viewport [loadMore] when the active Named facet list is short.
class NamedFacetFillViewportBinder extends HookConsumerWidget {
  const NamedFacetFillViewportBinder({
    required this.scrollController,
    required this.kind,
    super.key,
  });

  final ScrollController scrollController;
  final ManagedNamedFacetKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ObjectRef<bool> fillScheduledRef = useRef(false);
    final ObjectRef<int> autoFillDepthRef = useRef(0);
    final Size viewportSize = MediaQuery.sizeOf(context);

    void scheduleTryFill({required bool resetDepth}) {
      if (fillScheduledRef.value) {
        return;
      }
      fillScheduledRef.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fillScheduledRef.value = false;
        if (resetDepth) {
          autoFillDepthRef.value = 0;
        }
        unawaited(
          _tryFill(
            ref: ref,
            scrollController: scrollController,
            kind: kind,
            autoFillDepthRef: autoFillDepthRef,
          ),
        );
      });
    }

    // 维度切换时等 PeerContentTransition 结束后再补页，避免过渡中撑高列表。
    useEffect(() {
      autoFillDepthRef.value = 0;
      final Timer timer = Timer(
        PeerContentTransition.transitionDuration,
        () => scheduleTryFill(resetDepth: true),
      );
      return timer.cancel;
    }, <Object?>[kind]);

    useEffect(() {
      scheduleTryFill(resetDepth: true);
      return null;
    }, <Object?>[scrollController, viewportSize.width, viewportSize.height]);

    ref.listen(
      namedFacetManagementViewModelProvider(kind).select(
        (NamedFacetManagementState s) => (
          s.hasMore,
          s.hasSearchQuery,
          s.isLoading,
          s.isLoadingMore,
          s.error == null,
          s.items.length,
        ),
      ),
      (previous, next) {
        final (
          bool hasMore,
          bool hasSearchQuery,
          bool isLoading,
          bool isLoadingMore,
          bool noError,
          _,
        ) = next;
        if (hasMore &&
            !hasSearchQuery &&
            !isLoading &&
            !isLoadingMore &&
            noError) {
          scheduleTryFill(resetDepth: false);
        }
      },
    );

    return const SizedBox.shrink();
  }
}

Future<void> _tryFill({
  required WidgetRef ref,
  required ScrollController scrollController,
  required ManagedNamedFacetKind kind,
  required ObjectRef<int> autoFillDepthRef,
}) async {
  if (!scrollController.hasClients) {
    return;
  }
  if (autoFillDepthRef.value >= kNamedFacetFillViewportMaxAutoPages) {
    return;
  }
  final NamedFacetManagementState state = ref.read(
    namedFacetManagementViewModelProvider(kind),
  );
  final ScrollPosition position = scrollController.position;
  if (!namedFacetShouldAutoLoadMore(
    hasMore: state.hasMore,
    hasSearchQuery: state.hasSearchQuery,
    isLoading: state.isLoading,
    isLoadingMore: state.isLoadingMore,
    hasError: state.error != null,
    maxScrollExtent: position.maxScrollExtent,
    pixels: position.pixels,
  )) {
    return;
  }
  autoFillDepthRef.value += 1;
  await ref
      .read(namedFacetManagementViewModelProvider(kind).notifier)
      .loadMore();
}
