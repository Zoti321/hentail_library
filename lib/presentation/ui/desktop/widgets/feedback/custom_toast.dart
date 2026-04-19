import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kToastMaxWidth = 380;
const double _kToastScreenInset = 24;

/// 右下角与屏幕边缘的间距（与历史 SnackBar 定位一致）。
EdgeInsets _desktopToastOuterMargin(BuildContext context) {
  final double w = MediaQuery.sizeOf(context).width;
  return EdgeInsets.only(
    left: w > _kToastMaxWidth + _kToastScreenInset * 2
        ? w - _kToastMaxWidth - _kToastScreenInset
        : _kToastScreenInset,
    bottom: _kToastScreenInset,
    right: _kToastScreenInset,
  );
}

enum AppToastType { success, error, info }

OverlayEntry? _activeToastEntry;

void _removeActiveToastImmediately() {
  final OverlayEntry? entry = _activeToastEntry;
  _activeToastEntry = null;
  entry?.remove();
}

/// 桌面端自定义 Toast：右下角、限宽；同时只显示一条。
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
  final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }
  final EdgeInsets margin = _desktopToastOuterMargin(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      return _ToastOverlayManager(
        margin: margin,
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
    final IconData iconData = switch (type) {
      AppToastType.success => LucideIcons.circleCheckBig,
      AppToastType.error => LucideIcons.circleAlert,
      AppToastType.info => LucideIcons.info,
    };
    final bool isLight = theme.brightness == Brightness.light;
    final Color toastBackground = isLight
        ? const Color(0xFFFFFFFF)
        : cs.surfaceContainerHigh;
    final Color accentColor = switch (type) {
      AppToastType.success => cs.primary,
      AppToastType.error => cs.error,
      AppToastType.info => cs.primary,
    };
    final Color foregroundColor = cs.textPrimary;
    final Color iconColor = accentColor;
    final List<BoxShadow> elevationShadows = isLight
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: cs.shadow.withAlpha(140),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(72),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ];
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: toastBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor, width: 0.5),
          boxShadow: elevationShadows,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showIcon) ...<Widget>[
                Icon(iconData, size: 20, color: iconColor),
                const SizedBox(width: 10),
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
                        fontSize: 14,
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
    required this.margin,
    required this.message,
    required this.type,
    required this.showIcon,
    required this.displayDuration,
    required this.onDismissed,
  });

  final EdgeInsets margin;
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
    return Stack(
      children: <Widget>[
        const Positioned.fill(child: IgnorePointer(child: SizedBox.expand())),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: widget.margin,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kToastMaxWidth),
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
