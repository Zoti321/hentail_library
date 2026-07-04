import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kLibraryScrollToTopBottomPadding = 24;
const double kLibraryScrollToTopShowViewportRatio = 1;
const double kLibraryScrollToTopHideViewportRatio = 0.85;
const Duration kLibraryScrollToTopFadeDuration = Duration(milliseconds: 180);
const Duration kLibraryScrollToTopScrollDuration = Duration(milliseconds: 300);

/// 库页右下角「回到顶部」浮动按钮。
class LibraryScrollToTopButton extends StatefulWidget {
  const LibraryScrollToTopButton({
    super.key,
    required this.scrollController,
    required this.isDrawerOpen,
  });

  final ScrollController scrollController;
  final bool isDrawerOpen;

  @override
  State<LibraryScrollToTopButton> createState() =>
      _LibraryScrollToTopButtonState();
}

class _LibraryScrollToTopButtonState extends State<LibraryScrollToTopButton> {
  bool _scrollPastShowThreshold = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant LibraryScrollToTopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
      _onScroll();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) {
      return;
    }
    final double offset = widget.scrollController.offset;
    final double viewport =
        widget.scrollController.position.viewportDimension;
    final double showThreshold =
        viewport * kLibraryScrollToTopShowViewportRatio;
    final double hideThreshold =
        viewport * kLibraryScrollToTopHideViewportRatio;

    final bool nextVisible = _scrollPastShowThreshold
        ? offset >= hideThreshold
        : offset > showThreshold;

    if (nextVisible != _scrollPastShowThreshold) {
      setState(() => _scrollPastShowThreshold = nextVisible);
    }
  }

  void _scrollToTop() {
    if (!widget.scrollController.hasClients) {
      return;
    }
    widget.scrollController.animateTo(
      0,
      duration: kLibraryScrollToTopScrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final bool visible = _scrollPastShowThreshold && !widget.isDrawerOpen;

    return Positioned(
      right: tokens.layout.contentHorizontalPadding,
      bottom: kLibraryScrollToTopBottomPadding,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: kLibraryScrollToTopFadeDuration,
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !visible,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(tokens.radius.md),
              border: Border.all(color: cs.hentai.borderSubtle),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: cs.hentai.cardShadowHover,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GhostButton.icon(
              icon: LucideIcons.arrowUp,
              tooltip: '回到顶部',
              semanticLabel: '回到顶部',
              size: 40,
              iconSize: 18,
              borderRadius: tokens.radius.md,
              foregroundColor: cs.hentai.iconDefault,
              hoverColor: cs.surfaceContainerHighest,
              overlayColor: cs.primary.withAlpha(32),
              onPressed: _scrollToTop,
            ),
          ),
        ),
      ),
    );
  }
}
