import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画库页右下角「回到顶部」（Lab；行为对齐生产 [LibraryScrollToTopButton]）。
class ExpressiveLibraryScrollToTopButton extends StatefulWidget {
  const ExpressiveLibraryScrollToTopButton({
    super.key,
    required this.scrollController,
    required this.horizontalPadding,
    this.hidden = false,
  });

  final ScrollController scrollController;
  final double horizontalPadding;
  final bool hidden;

  @override
  State<ExpressiveLibraryScrollToTopButton> createState() =>
      _ExpressiveLibraryScrollToTopButtonState();
}

class _ExpressiveLibraryScrollToTopButtonState
    extends State<ExpressiveLibraryScrollToTopButton> {
  bool _scrollPastShowThreshold = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScrollOffset());
  }

  @override
  void didUpdateWidget(covariant ExpressiveLibraryScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScrollOffset);
      widget.scrollController.addListener(_onScrollOffset);
      _onScrollOffset();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScrollOffset);
    super.dispose();
  }

  void _onScrollOffset() {
    if (!mounted || !widget.scrollController.hasClients) {
      return;
    }
    // hasClients 为真时 position 可能尚未完成布局（pixels / viewportDimension 未就绪），
    // 直接读取会触发 Null check；此时等待下一次滚动或布局回调再判定。
    final ScrollPosition position = widget.scrollController.position;
    if (!position.hasPixels || !position.hasViewportDimension) {
      return;
    }
    final double offset = position.pixels;
    final double viewport = position.viewportDimension;
    final double showThreshold =
        viewport * LibraryBrowsePageMetrics.scrollToTopShowViewportRatio;
    final double hideThreshold =
        viewport * LibraryBrowsePageMetrics.scrollToTopHideViewportRatio;

    final bool nextPastThreshold = _scrollPastShowThreshold
        ? offset >= hideThreshold
        : offset > showThreshold;

    if (nextPastThreshold != _scrollPastShowThreshold) {
      setState(() => _scrollPastShowThreshold = nextPastThreshold);
    }
  }

  void _scrollToTop() {
    if (!widget.scrollController.hasClients) {
      return;
    }
    widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final double width = MediaQuery.sizeOf(context).width;
    final WindowSizeClass sizeClass = WindowSizeClass.fromWidth(width);
    final M3EFabSize fabSize = FabSizing.responsive(sizeClass);
    final M3EFabMetrics metrics = theme.fabTheme.resolve(
      size: fabSize,
      color: M3EFabColor.primary,
      scheme: theme.colorScheme,
      enabled: true,
    );

    // 显隐（位移 + 透明度）由外层 M3E 空间弹簧驱动，不再使用 FAB 内置的滚动显隐。
    return Positioned(
      right: widget.horizontalPadding,
      bottom: LibraryBrowsePageMetrics.scrollToTopBottomInset,
      child: SpringReveal(
        visible: _scrollPastShowThreshold && !widget.hidden,
        hiddenOffset: const Offset(0, 24),
        child: Semantics(
          button: true,
          label: '回到顶部',
          child: M3EFab(
            size: fabSize,
            color: M3EFabColor.primary,
            cornerRadius: LibraryBrowsePageMetrics.scrollToTopCornerRadius,
            icon: Icon(LucideIcons.arrowUp, size: metrics.iconSize),
            onPressed: _scrollToTop,
          ),
        ),
      ),
    );
  }
}
