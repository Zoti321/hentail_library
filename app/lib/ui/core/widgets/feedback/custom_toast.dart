import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kToastStandardMaxWidth = 380;
const double _kToastExpandedMaxWidth = 480;
const double _kToastScreenInset = 24;
const double _kCompactToastBottomBarGap = 56;

/// Max toast width for [viewportWidth], following [AppLayoutBreakpoints].
double toastMaxWidth(double viewportWidth) {
  if (AppLayoutBreakpoints.isExpanded(viewportWidth)) {
    return _kToastExpandedMaxWidth;
  }
  if (AppLayoutBreakpoints.isCompact(viewportWidth)) {
    return math.min(
      viewportWidth - _kToastScreenInset * 2,
      _kToastStandardMaxWidth,
    );
  }
  return _kToastStandardMaxWidth;
}

/// Inner padding: expanded gets a taller bar; compact/medium stay denser.
EdgeInsets toastContentPadding(
  double viewportWidth, {
  AppThemeTokens tokens = AppThemeTokens.shared,
}) {
  if (AppLayoutBreakpoints.isExpanded(viewportWidth)) {
    return EdgeInsets.symmetric(
      horizontal: tokens.spacing.xl,
      vertical: tokens.spacing.lg,
    );
  }
  return EdgeInsets.symmetric(
    horizontal: tokens.spacing.lg,
    vertical: tokens.spacing.md,
  );
}

/// Positions a toast: compact screens sit bottom-center above chrome;
/// medium/expanded screens keep the desktop bottom-right corner.
EdgeInsets toastOuterMargin(Size size, {double bottomInset = 0}) {
  const double inset = _kToastScreenInset;
  if (AppLayoutBreakpoints.isCompact(size.width)) {
    return EdgeInsets.fromLTRB(inset, 0, inset, inset + bottomInset);
  }
  final double maxWidth = toastMaxWidth(size.width);
  return EdgeInsets.only(
    left: size.width > maxWidth + inset * 2
        ? size.width - maxWidth - inset
        : inset,
    bottom: inset + bottomInset,
    right: inset,
  );
}

enum AppToastType { success, error, info }

OverlayEntry? _activeToastEntry;

void _removeActiveToastImmediately() {
  final OverlayEntry? entry = _activeToastEntry;
  _activeToastEntry = null;
  entry?.remove();
}

/// 自定义 Toast：按断点限宽；同时只显示一条。
void showCustomToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 3),
  bool showIcon = true,
}) {
  if (!context.mounted) {
    return;
  }
  _removeActiveToastImmediately();
  OverlayState? overlay = Navigator.maybeOf(context)?.overlay;
  overlay ??= Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      return _ToastOverlayManager(
        message: message,
        type: type,
        showIcon: showIcon,
        displayDuration: duration,
        onDismissed: () {
          if (_activeToastEntry == entry) {
            _activeToastEntry = null;
          }
          entry.remove();
        },
      );
    },
  );
  _activeToastEntry = entry;
  overlay.insert(entry);
}

void showSuccessToast(BuildContext context, String message) {
  showCustomToast(context, message: message, type: AppToastType.success);
}

void showErrorToast(BuildContext context, Object error) {
  final String message = error is AppException
      ? error.message
      : error.toString();
  showCustomToast(context, message: message, type: AppToastType.error);
}

void showInfoToast(BuildContext context, String message) {
  showCustomToast(context, message: message, type: AppToastType.info);
}

/// 单条 Toast 的视觉内容（不含 Overlay 与动画）。
class CustomToast extends StatelessWidget {
  const CustomToast({
    super.key,
    required this.message,
    required this.type,
    this.showIcon = true,
  });

  final String message;
  final AppToastType type;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppThemeTokens.shared;
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final IconData iconData = switch (type) {
      AppToastType.success => LucideIcons.circleCheckBig,
      AppToastType.error => LucideIcons.circleAlert,
      AppToastType.info => LucideIcons.info,
    };
    final bool isDark = theme.brightness == Brightness.dark;
    final Color toastBackground = isDark ? cs.surfaceContainerHigh : cs.surface;
    final Color accentColor = switch (type) {
      AppToastType.success => cs.primary,
      AppToastType.error => cs.error,
      AppToastType.info => cs.primary,
    };
    final Color foregroundColor = cs.hentai.textPrimary;
    final Color ambient = isDark
        ? Colors.black.withAlpha(52)
        : Colors.black.withAlpha(14);
    final Color contact = isDark
        ? Colors.black.withAlpha(72)
        : Colors.black.withAlpha(22);
    final List<BoxShadow> elevationShadows = <BoxShadow>[
      BoxShadow(color: ambient, blurRadius: 32, offset: const Offset(0, 14)),
      BoxShadow(
        color: cs.hentai.cardShadowHover,
        blurRadius: 24,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: cs.hentai.cardShadow,
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: contact,
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: toastBackground,
          borderRadius: BorderRadius.circular(tokens.radius.md),
          boxShadow: elevationShadows,
        ),
        child: Padding(
          padding: toastContentPadding(viewportWidth, tokens: tokens),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showIcon) ...<Widget>[
                Icon(iconData, size: 20, color: accentColor),
                SizedBox(width: tokens.spacing.sm),
              ],
              Expanded(
                child: Text(
                  message,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ) ??
                      TextStyle(
                        color: foregroundColor,
                        fontSize: tokens.text.bodyMd,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastOverlayManager extends StatefulWidget {
  const _ToastOverlayManager({
    required this.message,
    required this.type,
    required this.showIcon,
    required this.displayDuration,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final bool showIcon;
  final Duration displayDuration;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlayManager> createState() => _ToastOverlayManagerState();
}

class _ToastOverlayManagerState extends State<_ToastOverlayManager>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _controller.forward();
    _dismissTimer = Timer(widget.displayDuration, _executeDismiss);
  }

  Future<void> _executeDismiss() async {
    _dismissTimer = null;
    if (!mounted) {
      return;
    }
    await _controller.reverse();
    if (!mounted) {
      return;
    }
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final Size size = MediaQuery.sizeOf(context);
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final bool compact = AppLayoutBreakpoints.isCompact(size.width);
    final double bottomBar = compact ? _kCompactToastBottomBarGap : 0;
    final EdgeInsets margin = toastOuterMargin(
      size,
      bottomInset: safeBottom + bottomBar,
    );
    return Stack(
      children: <Widget>[
        const Positioned.fill(child: IgnorePointer(child: SizedBox.expand())),
        Align(
          alignment: compact ? Alignment.bottomCenter : Alignment.bottomRight,
          child: Padding(
            padding: margin,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: toastMaxWidth(size.width)),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(curved),
                child: FadeTransition(
                  opacity: curved,
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: widget.message,
                    child: CustomToast(
                      message: widget.message,
                      type: widget.type,
                      showIcon: widget.showIcon,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
