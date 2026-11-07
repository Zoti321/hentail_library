import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';

/// 同级内容切换：水平 Shared Axis 位移 + **重叠淡化**（漫画↔系列、管理维度等）。
///
/// 官方 [SharedAxisTransition] 离开项在前 30% 已全透明、进入项从 30% 才淡入，
/// 中间会露出画布底色造成闪白。这里拉长交叉淡化区间，且不加 opaque fill。
///
/// 布局：顶对齐，过渡期间高度取进出子树较大值，结束后用 [AnimatedSize] 收回，
/// 避免居中跳动，也避免「只按进入项定高」时裁切离开页。
class PeerContentTransition extends StatelessWidget {
  const PeerContentTransition({
    super.key,
    required this.switchKey,
    required this.child,
    this.reverse = false,
  });

  final Object switchKey;
  final Widget child;

  /// 为 true 时表示退回（例如系列 → 漫画、标签 → 作者）。
  final bool reverse;

  static const Duration transitionDuration = kDesktopPageTransitionDuration;

  /// 与官方 Shared Axis 水平位移一致（逻辑像素）。
  static const double slidePixels = 30;

  @override
  Widget build(BuildContext context) {
    if (LabMotion.reduceMotionOf(context)) {
      return child;
    }

    final Duration duration = LabMotion.motionDurationOf(
      context,
      transitionDuration,
    );

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: PageTransitionSwitcher(
        duration: duration,
        reverse: reverse,
        layoutBuilder: (List<Widget> entries) {
          if (entries.isEmpty) {
            return const SizedBox.shrink();
          }
          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            children: entries,
          );
        },
        transitionBuilder:
            (
              Widget child,
              Animation<double> primary,
              Animation<double> secondary,
            ) {
              return _PeerSharedAxis(
                animation: primary,
                secondaryAnimation: secondary,
                child: child,
              );
            },
        child: KeyedSubtree(key: ValueKey<Object>(switchKey), child: child),
      ),
    );
  }
}

/// 结构对齐 [SharedAxisTransition]，但淡入/淡出区间重叠，且无 fill [ColoredBox]。
class _PeerSharedAxis extends StatelessWidget {
  const _PeerSharedAxis({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder:
          (BuildContext context, Animation<double> animation, Widget? child) {
            return _PeerEnterTransition(animation: animation, child: child);
          },
      reverseBuilder:
          (BuildContext context, Animation<double> animation, Widget? child) {
            return _PeerExitTransition(
              animation: animation,
              reverse: true,
              child: child,
            );
          },
      child: DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder:
            (BuildContext context, Animation<double> animation, Widget? child) {
              return _PeerEnterTransition(
                animation: animation,
                reverse: true,
                child: child,
              );
            },
        reverseBuilder:
            (BuildContext context, Animation<double> animation, Widget? child) {
              return _PeerExitTransition(animation: animation, child: child);
            },
        child: child,
      ),
    );
  }
}

class _PeerEnterTransition extends StatelessWidget {
  const _PeerEnterTransition({
    required this.animation,
    this.reverse = false,
    this.child,
  });

  final Animation<double> animation;
  final bool reverse;
  final Widget? child;

  /// 从 12% 起淡入，与离开项重叠，避免中间全透明空窗。
  static final Animatable<double> _fadeIn = CurveTween(
    curve: Easing.legacyDecelerate,
  ).chain(CurveTween(curve: const Interval(0.12, 1.0)));

  @override
  Widget build(BuildContext context) {
    final double dx = reverse
        ? -PeerContentTransition.slidePixels
        : PeerContentTransition.slidePixels;
    final Animatable<Offset> slideIn = Tween<Offset>(
      begin: Offset(dx, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Easing.legacy));

    return FadeTransition(
      opacity: _fadeIn.animate(animation),
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: slideIn.evaluate(animation),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

class _PeerExitTransition extends StatelessWidget {
  const _PeerExitTransition({
    required this.animation,
    this.reverse = false,
    this.child,
  });

  final Animation<double> animation;
  final bool reverse;
  final Widget? child;

  /// 离开项淡出拉长到约 55%，与进入淡入交叉。
  static final Animatable<double> _fadeOut = _FlippedCurveTween(
    curve: Easing.legacyAccelerate,
  ).chain(CurveTween(curve: const Interval(0.0, 0.55)));

  @override
  Widget build(BuildContext context) {
    final Animatable<Offset> slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(
        reverse
            ? PeerContentTransition.slidePixels
            : -PeerContentTransition.slidePixels,
        0,
      ),
    ).chain(CurveTween(curve: Easing.legacy));

    return FadeTransition(
      opacity: _fadeOut.animate(animation),
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: slideOut.evaluate(animation),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

/// 与 animations 包 Shared Axis 一致：把 progress 曲线翻成离开淡出。
class _FlippedCurveTween extends CurveTween {
  _FlippedCurveTween({required super.curve});

  @override
  double transform(double t) => 1.0 - super.transform(t);
}
