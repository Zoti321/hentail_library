import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读页系列边界提示：与 [M3ESnackbarHost] 同一套动效（自下方滑入 emphasized、
/// 自动消失时反向滑出）与安全区 / 边距，但挂在阅读画布自身的 Stack 内，不走根 Overlay。
class Md3eReaderBoundarySnackbar extends StatefulWidget {
  const Md3eReaderBoundarySnackbar({
    super.key,
    required this.message,
    required this.onClosed,
    this.duration = const Duration(seconds: 4),
  });

  final String message;

  /// 退场动画结束后回调，由宿主移除本组件。
  final VoidCallback onClosed;

  /// 自动消失时长（与 [M3EThemeData.snackBarTheme.defaultDuration] 对齐）。
  final Duration duration;

  @override
  State<Md3eReaderBoundarySnackbar> createState() =>
      _Md3eReaderBoundarySnackbarState();
}

class _Md3eReaderBoundarySnackbarState extends State<Md3eReaderBoundarySnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Md3eMotion.durationMedium,
      reverseDuration: Md3eMotion.durationShort,
    );
    _offset = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Md3eMotion.curveEmphasized,
          ),
        );
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing) {
      return;
    }
    _dismissing = true;
    _timer?.cancel();
    try {
      await _controller.reverse();
    } on TickerCanceled {
      // 宿主已直接移除本组件（如跨卷），动画被取消属正常结束。
      return;
    }
    if (mounted) {
      widget.onClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snackTheme = M3ETheme.of(context).snackBarTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        snackTheme.overlayHorizontalInset + M3ESafeArea.leftOf(context),
        0,
        snackTheme.overlayHorizontalInset + M3ESafeArea.rightOf(context),
        snackTheme.overlayBottomInset + M3ESafeArea.overlayBottomOf(context),
      ),
      child: Align(
        alignment: snackTheme.overlayAlignment,
        child: SlideTransition(
          position: _offset,
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: kMd3eAppFontFamily),
            child: M3EComponentTheme(
              builder: (BuildContext context) =>
                  M3ESnackbar(message: widget.message),
            ),
          ),
        ),
      ),
    );
  }
}
