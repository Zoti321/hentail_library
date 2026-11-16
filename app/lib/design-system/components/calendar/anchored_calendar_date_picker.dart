import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../motion/motion.dart';
import '../overlays/overlay_route_scope.dart';
import 'calendar_date_picker_surface.dart';

/// Opens a docked picker or compact modal. Only confirmation commits the draft.
Future<void> showAnchoredCalendarDatePicker({
  required BuildContext context,
  required LayerLink layerLink,
  required DateTime firstDate,
  required DateTime lastDate,
  required ValueChanged<DateTime> onDateChanged,
  DateTime? initialDate,
  M3EDatePickerMode initialCalendarMode = M3EDatePickerMode.day,
  BuildContext? placementContext,
}) async {
  final scope = OverlayRouteScopeSnapshot.capture(context);
  final anchorContext = placementContext ?? context;
  if (MediaQuery.sizeOf(context).width >= 600) {
    final completed = Completer<void>();
    final previousFocus = FocusManager.instance.primaryFocus;
    late final OverlayEntry entry;
    void dismiss() {
      if (completed.isCompleted) return;
      entry.remove();
      entry.dispose();
      previousFocus?.requestFocus();
      completed.complete();
    }

    entry = OverlayEntry(
      builder: (overlayContext) => OverlayRouteScope(
        scope: scope,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final object = anchorContext.mounted
                  ? anchorContext.findRenderObject()
                  : null;
              final anchor =
                  object is RenderBox && object.attached && object.hasSize
                  ? object.localToGlobal(Offset.zero) & object.size
                  : Rect.zero;
              return CustomSingleChildLayout(
                delegate: _DockedCalendarLayout(
                  anchor: anchor,
                  padding: MediaQuery.paddingOf(context),
                  rtl: Directionality.of(context) == TextDirection.rtl,
                ),
                child: TapRegion(
                  onTapOutside: (_) => dismiss(),
                  child: FocusScope(
                    autofocus: true,
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.escape):
                            dismiss,
                      },
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: LabMotion.motionDurationOf(
                          context,
                          LabMotion.durationShort,
                        ),
                        builder: (context, opacity, child) =>
                            Opacity(opacity: opacity, child: child),
                        child: CalendarDatePickerSurface(
                          firstDate: firstDate,
                          lastDate: lastDate,
                          initialDate: initialDate,
                          initialCalendarMode: initialCalendarMode,
                          onCancel: dismiss,
                          onConfirmed: (date) {
                            onDateChanged(date);
                            dismiss();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return completed.future;
  }
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // The responsive scrim is painted inside the route, so resize can switch variants.
    barrierColor: Colors.transparent,
    transitionDuration: LabMotion.motionDurationOf(
      context,
      LabMotion.durationShort,
    ),
    transitionBuilder: (context, animation, secondary, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: LabMotion.curveEmphasizedDecelerate,
          ),
        ),
        child: child,
      ),
    ),
    pageBuilder: (routeContext, animation, secondary) => OverlayRouteScope(
      scope: scope,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(routeContext).pop(),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final compact = constraints.maxWidth < 600;
            final fullscreen =
                compact &&
                (constraints.maxWidth < 392 || constraints.maxHeight < 600);
            final object = anchorContext.mounted
                ? anchorContext.findRenderObject()
                : null;
            final anchor =
                object is RenderBox && object.hasSize && object.attached
                ? object.localToGlobal(Offset.zero) & object.size
                : Rect.zero;
            final surface = CalendarDatePickerSurface(
              key: const ValueKey('date-picker-session'),
              firstDate: firstDate,
              lastDate: lastDate,
              initialDate: initialDate,
              initialCalendarMode: initialCalendarMode,
              modal: compact,
              fullscreen: fullscreen,
              onCancel: () => Navigator.of(routeContext).pop(),
              onConfirmed: (date) {
                onDateChanged(date);
                Navigator.of(routeContext).pop();
              },
            );
            return Stack(
              children: [
                if (compact)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(color: Colors.black54),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                    child: compact
                        ? fullscreen
                              ? SizedBox.expand(child: surface)
                              : Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: 360,
                                      maxHeight: math.max(
                                        0,
                                        constraints.maxHeight - 32,
                                      ),
                                    ),
                                    child: surface,
                                  ),
                                )
                        : CustomSingleChildLayout(
                            delegate: _DockedCalendarLayout(
                              anchor: anchor,
                              padding: media.padding,
                              rtl:
                                  Directionality.of(context) ==
                                  TextDirection.rtl,
                            ),
                            child: surface,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Uses the actual child height, including dynamic month rows and menu views.
class _DockedCalendarLayout extends SingleChildLayoutDelegate {
  const _DockedCalendarLayout({
    required this.anchor,
    required this.padding,
    required this.rtl,
  });
  final Rect anchor;
  final EdgeInsets padding;
  final bool rtl;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: math.min(360, math.max(0, constraints.maxWidth - 24)),
        maxWidth: math.min(360, math.max(0, constraints.maxWidth - 24)),
        maxHeight: math.max(0, constraints.maxHeight - 24),
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = anchor.bottom - padding.top + 4;
    final top = below + childSize.height <= size.height - 12
        ? below
        : anchor.top - padding.top - childSize.height - 4;
    final left =
        (rtl ? anchor.right - childSize.width : anchor.left) - padding.left;
    return Offset(
      left.clamp(12.0, math.max(12, size.width - childSize.width - 12)),
      top.clamp(12.0, math.max(12, size.height - childSize.height - 12)),
    );
  }

  @override
  bool shouldRelayout(_DockedCalendarLayout oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.padding != padding ||
      oldDelegate.rtl != rtl;
}
