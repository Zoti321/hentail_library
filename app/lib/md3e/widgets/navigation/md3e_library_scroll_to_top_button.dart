import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_reveal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画库页右下角「回到顶部」（Lab；行为对齐生产 [LibraryScrollToTopButton]）。
class Md3eLibraryScrollToTopButton extends StatefulWidget {
  const Md3eLibraryScrollToTopButton({
    super.key,
    required this.scrollController,
    required this.horizontalPadding,
    this.hidden = false,
  });

  final ScrollController scrollController;
  final double horizontalPadding;
  final bool hidden;

  @override
  State<Md3eLibraryScrollToTopButton> createState() =>
      _Md3eLibraryScrollToTopButtonState();
}

class _Md3eLibraryScrollToTopButtonState
    extends State<Md3eLibraryScrollToTopButton> {
  bool _scrollPastShowThreshold = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScrollOffset());
  }

  @override
  void didUpdateWidget(covariant Md3eLibraryScrollToTopButton oldWidget) {
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
    if (!widget.scrollController.hasClients) {
      return;
    }
    final double offset = widget.scrollController.offset;
    final double viewport = widget.scrollController.position.viewportDimension;
    final double showThreshold =
        viewport * Md3eLibraryBrowsePageMetrics.scrollToTopShowViewportRatio;
    final double hideThreshold =
        viewport * Md3eLibraryBrowsePageMetrics.scrollToTopHideViewportRatio;

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
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(width);
    final M3EFabSize fabSize = Md3eLibraryBrowsePageMetrics.scrollToTopFabSize(
      sizeClass,
    );
    final M3EFabMetrics metrics = theme.fabTheme.resolve(
      size: fabSize,
      color: M3EFabColor.primary,
      scheme: theme.colorScheme,
      enabled: true,
    );

    // 显隐（位移 + 透明度）由外层 M3E 空间弹簧驱动，不再使用 FAB 内置的滚动显隐。
    return Positioned(
      right: widget.horizontalPadding,
      bottom: Md3eLibraryBrowsePageMetrics.scrollToTopBottomInset,
      child: Md3eSpringReveal(
        visible: _scrollPastShowThreshold && !widget.hidden,
        hiddenOffset: const Offset(0, 24),
        child: Semantics(
          button: true,
          label: '回到顶部',
          child: M3EFab(
            size: fabSize,
            color: M3EFabColor.primary,
            cornerRadius: Md3eLibraryBrowsePageMetrics.scrollToTopCornerRadius,
            icon: Icon(LucideIcons.arrowUp, size: metrics.iconSize),
            onPressed: _scrollToTop,
          ),
        ),
      ),
    );
  }
}
