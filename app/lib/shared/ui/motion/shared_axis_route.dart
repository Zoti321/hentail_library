import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 页面转场：官方水平 [SharedAxisTransition]（Material shared-axis）。
///
/// 开启「减少动效」时直接切换，不播放位移。
PageRoute<T> sharedAxisRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SharedAxisTransitionType transitionType =
      SharedAxisTransitionType.horizontal,
}) {
  final Duration duration = LabMotion.motionDurationOf(
    context,
    kSharedAxisRouteDuration,
  );

  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return builder(routeContext);
        },
    transitionsBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          if (LabMotion.reduceMotionOf(routeContext)) {
            return child;
          }
          final Color fillColor = labBrowseCanvasColor(
            M3ETheme.of(routeContext).colorScheme,
          );
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            fillColor: fillColor,
            child: child,
          );
        },
  );
}

/// Material Shared Axis 默认时长（与 `animations` 包 PageTransitions 一致）。
const Duration kSharedAxisRouteDuration = Duration(milliseconds: 300);
