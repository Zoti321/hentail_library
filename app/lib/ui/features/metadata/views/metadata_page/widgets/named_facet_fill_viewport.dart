import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/features/metadata/view_models/named_facet_management_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Near-bottom / fill-viewport threshold shared with scroll-driven load-more.
const double kNamedFacetLoadMoreExtentThreshold = 240;

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
    final Size viewportSize = MediaQuery.sizeOf(context);

    void scheduleTryFill() {
      if (fillScheduledRef.value) {
        return;
      }
      fillScheduledRef.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fillScheduledRef.value = false;
        unawaited(
          _tryFill(ref: ref, scrollController: scrollController, kind: kind),
        );
      });
    }

    useEffect(
      () {
        scheduleTryFill();
        return null;
      },
      <Object?>[
        kind,
        scrollController,
        viewportSize.width,
        viewportSize.height,
      ],
    );

    ref.listen<NamedFacetManagementState>(
      namedFacetManagementControllerProvider(kind),
      (NamedFacetManagementState? previous, NamedFacetManagementState next) {
        if (next.hasMore &&
            !next.hasSearchQuery &&
            !next.isLoading &&
            !next.isLoadingMore &&
            next.error == null) {
          scheduleTryFill();
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
}) async {
  if (!scrollController.hasClients) {
    return;
  }
  final NamedFacetManagementState state = ref.read(
    namedFacetManagementControllerProvider(kind),
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
  await ref
      .read(namedFacetManagementControllerProvider(kind).notifier)
      .loadMore();
}
