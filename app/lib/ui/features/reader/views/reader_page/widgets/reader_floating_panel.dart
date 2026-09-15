import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// Unified visual size for reader top-bar action [GhostButton]s (including back).
const double kReaderTopBarActionSize = 32;

/// Extra gap beyond [MediaQueryData.padding] for floating reader chrome.
///
/// System safe-area (notch / home indicator) stays intact; this only adds a
/// small float margin so bars are not flush against the viewport edge.
const double kReaderChromeEdgeGap = 8;

/// Slide distance when reader chrome hides (top/bottom [AnimatedPositioned]).
const double kReaderChromeHideSlide = 16;

/// Shared vertical margin for reader overflow + series popup menus.
///
/// Matches library toolbar / detail precedents (`verticalMargin: -32`) so the
/// menu sits close to its trigger across breakpoints.
const double kReaderPopupMenuVerticalMargin = -32;

/// Per-side inset used when clamping popup menu width to the viewport.
const double kReaderPopupMenuHorizontalInset = 16;

/// Design width for the reader overflow menu before viewport clamping.
const double kReaderOverflowMenuDesignWidth = 240;

/// Target width for reader top/bottom chrome bars.
///
/// Compact (`viewportWidth < [AppLayoutBreakpoints.compact]`): full width of
/// the available content area after [horizontalSafePadding].
/// Wider viewports: floating island `(viewport × 0.8).clamp(560, 1120)`.
double readerTargetBarWidth(
  double viewportWidth, {
  double horizontalSafePadding = 0,
}) {
  if (AppLayoutBreakpoints.isCompact(viewportWidth)) {
    return math.max(0, viewportWidth - horizontalSafePadding);
  }
  return (viewportWidth * 0.8).clamp(560.0, 1120.0);
}

/// Clamps a popup menu design width to the available viewport.
double readerClampedPopupMenuWidth({
  required double designWidth,
  required double viewportWidth,
  double horizontalInset = kReaderPopupMenuHorizontalInset,
}) {
  final double maxWidth = viewportWidth - horizontalInset * 2;
  if (maxWidth <= 0) {
    return 0;
  }
  return math.min(designWidth, maxWidth);
}

/// 阅读器顶/底栏与弹出层的磨砂容器。
class ReaderFloatingPanel extends StatelessWidget {
  const ReaderFloatingPanel({
    super.key,
    required this.child,
    this.width,
    this.constraints,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Widget child;
  final double? width;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry padding;

  static double targetBarWidth(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    return readerTargetBarWidth(
      media.size.width,
      horizontalSafePadding: media.padding.horizontal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double radius = context.tokens.radius.xs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: cs.hentai.readerPanelBackground,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 阅读器弹出菜单磨砂面板（无阴影、无边框）。
class ReaderFloatingMenuPanel extends StatelessWidget {
  const ReaderFloatingMenuPanel({
    super.key,
    required this.width,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final double width;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ReaderFloatingPanel(width: width, padding: padding, child: child);
  }
}
