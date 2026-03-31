import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';

class HomeRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isRefreshing;

  const HomeRefreshButton({
    super.key,
    required this.onPressed,
    this.isRefreshing = false,
  });

  @override
  State<HomeRefreshButton> createState() => _HomeRefreshButtonState();
}

class _HomeRefreshButtonState extends State<HomeRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  double _scale = 1.0;
  bool _isHover = false;

  @override
  void initState() {
    super.initState();
    // 用于处理旋转动画
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.isRefreshing) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(HomeRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 监听状态变化来控制动画
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _spinController.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      // 停止动画并重置到初始角度
      _spinController.stop();
      _spinController.reset();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  // 处理按压缩放效果 (active:scale-95)
  void _onTapDown(TapDownDetails details) {
    if (!widget.isRefreshing) {
      setState(() => _scale = 0.95);
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final Color borderColor = Theme.of(context).colorScheme.borderSubtle;
    final Color iconColor = Theme.of(context).colorScheme.iconDefault;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isRefreshing ? null : widget.onPressed,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(tokens.radius.sm),
              border: Border.all(
                color: borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5), // shadow-sm
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: RotationTransition(
                turns: _spinController,
                child: Icon(
                  Icons.refresh_rounded,
                  color: widget.isRefreshing || _isHover
                      ? Theme.of(context).colorScheme.primary
                      : iconColor,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
