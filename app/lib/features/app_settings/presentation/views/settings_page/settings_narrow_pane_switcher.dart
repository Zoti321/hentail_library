import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// Narrow master ↔ detail transition (slide + fade).
class SettingsNarrowPaneSwitcher extends StatelessWidget {
  const SettingsNarrowPaneSwitcher({
    super.key,
    required this.showingDetail,
    required this.masterList,
    required this.detailPane,
  });

  final bool showingDetail;
  final Widget masterList;
  final Widget detailPane;

  Widget _layoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[...previousChildren, ?currentChild],
    );
  }

  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    final bool isIncoming = child.key == ValueKey<bool>(showingDetail);
    final Offset begin = isIncoming
        ? (showingDetail ? const Offset(0.12, 0) : const Offset(-0.08, 0))
        : (showingDetail ? const Offset(-0.08, 0) : const Offset(0.12, 0));
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return showingDetail ? detailPane : masterList;
    }

    final Duration duration = LabMotion.motionDurationOf(
      context,
      LabMotion.routeTransitionDuration,
    );
    // 与 Lab 页面转场同款 M3E expressive spatial 弹簧：进场允许轻微过冲，退场沿反向曲线收回。
    final Curve springCurve = SpringCurve(
      motion: LabMotion.routeSpring,
      duration: LabMotion.routeTransitionDuration,
    );

    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: duration,
        switchInCurve: springCurve,
        switchOutCurve: springCurve.flipped,
        layoutBuilder: _layoutBuilder,
        transitionBuilder: _transitionBuilder,
        child: KeyedSubtree(
          key: ValueKey<bool>(showingDetail),
          child: showingDetail ? detailPane : masterList,
        ),
      ),
    );
  }
}
