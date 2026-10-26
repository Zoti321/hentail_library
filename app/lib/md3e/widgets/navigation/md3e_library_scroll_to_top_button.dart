import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
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
  late final M3EFabController _fabController = M3EFabController();

  bool _scrollPastShowThreshold = false;

  @override
  void initState() {
    super.initState();
    _fabController.hide();
    _fabController.attachScroll(widget.scrollController);
    widget.scrollController.addListener(_onScrollOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScrollOffset());
  }

  @override
  void didUpdateWidget(covariant Md3eLibraryScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScrollOffset);
      _fabController.detachScroll();
      _fabController.attachScroll(widget.scrollController);
      widget.scrollController.addListener(_onScrollOffset);
      _onScrollOffset();
    }
    if (oldWidget.hidden != widget.hidden) {
      _applyThresholdVisibility(pastThreshold: _scrollPastShowThreshold);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScrollOffset);
    _fabController.dispose();
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
      _applyThresholdVisibility(pastThreshold: nextPastThreshold);
    }
  }

  void _applyThresholdVisibility({required bool pastThreshold}) {
    if (widget.hidden || !pastThreshold) {
      _fabController.hide();
    } else {
      _fabController.show();
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
    final M3EFabSize fabSize =
        Md3eLibraryBrowsePageMetrics.scrollToTopFabSize(sizeClass);
    final M3EFabMetrics metrics = theme.fabTheme.resolve(
      size: fabSize,
      color: M3EFabColor.primary,
      scheme: theme.colorScheme,
      enabled: true,
    );

    return Positioned(
      right: widget.horizontalPadding,
      bottom: Md3eLibraryBrowsePageMetrics.scrollToTopBottomInset,
      child: Semantics(
        button: true,
        label: '回到顶部',
        child: M3EFab(
          controller: _fabController,
          size: fabSize,
          color: M3EFabColor.primary,
          cornerRadius: Md3eLibraryBrowsePageMetrics.scrollToTopCornerRadius,
          icon: Icon(
            LucideIcons.arrowUp,
            size: metrics.iconSize,
          ),
          onPressed: _scrollToTop,
        ),
      ),
    );
  }
}
