import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/motion/shared_axis_route.dart';

/// 库浏览 → 漫画/系列详情等带封面 Hero 的路由页。
///
/// 不用 desktop fade-through（前半段目标页 opacity=0 会让 Hero 落地闪一下）。
/// 对齐 Kazumi：普通 Material 系淡入，共享封面由 [Hero] 在 overlay 上飞行。
///
/// 系列内切卷请传 [CatalogSeriesNavExtra]，改用水平 Shared Axis（同级卷切换）。
const Duration kCatalogDetailPageTransitionDuration = Duration(
  milliseconds: 300,
);

/// 漫画/系列详情「同级切卷」路由 extra（[GoRouterState.extra]）。
@immutable
class CatalogSeriesNavExtra {
  const CatalogSeriesNavExtra({required this.reverse});

  /// `true`：切到更靠前的卷（从左侧进入）。
  final bool reverse;
}

CustomTransitionPage<void> buildCatalogDetailPage({
  required GoRouterState state,
  required Widget child,
}) {
  final Object? extra = state.extra;
  if (extra is CatalogSeriesNavExtra) {
    // reduce-motion 由 sharedAxisTransitionWrapper 处理；此处用标准时长。
    return buildSharedAxisPage(
      state: state,
      child: child,
      reverse: extra.reverse,
      transitionDuration: kSharedAxisRouteDuration,
    );
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    transitionDuration: kCatalogDetailPageTransitionDuration,
    reverseTransitionDuration: kCatalogDetailPageTransitionDuration,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          if (MediaQuery.disableAnimationsOf(context)) {
            return child;
          }
          // 从 t=0 就开始淡入，避免「半程全透明」与 Hero 交接打架。
          final Animation<double> fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(opacity: fade, child: child);
        },
    child: child,
  );
}
