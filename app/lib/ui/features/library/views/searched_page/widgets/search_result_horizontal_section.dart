import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SearchResultHorizontalSection extends StatefulWidget {
  const SearchResultHorizontalSection({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemHeight,
    required this.itemBuilder,
    this.itemSpacing,
  });

  final String title;
  final int itemCount;
  final double itemHeight;
  final IndexedWidgetBuilder itemBuilder;
  final double? itemSpacing;

  @override
  State<SearchResultHorizontalSection> createState() =>
      _SearchResultHorizontalSectionState();
}

class _SearchResultHorizontalSectionState
    extends State<SearchResultHorizontalSection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void didUpdateWidget(covariant SearchResultHorizontalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateScrollButtons(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) {
      return;
    }
    final double offset = _scrollController.offset;
    final double maxExtent = _scrollController.position.maxScrollExtent;
    final bool canBack = offset > 0.5;
    final bool canForward = offset < maxExtent - 0.5;
    if (canBack != _canScrollBack || canForward != _canScrollForward) {
      setState(() {
        _canScrollBack = canBack;
        _canScrollForward = canForward;
      });
    }
  }

  void _scrollByViewport({required bool forward}) {
    if (!_scrollController.hasClients) {
      return;
    }
    final double viewport = _scrollController.position.viewportDimension;
    final double target = forward
        ? (_scrollController.offset + viewport).clamp(
            0,
            _scrollController.position.maxScrollExtent,
          )
        : (_scrollController.offset - viewport).clamp(
            0,
            _scrollController.position.maxScrollExtent,
          );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double spacing = widget.itemSpacing ?? tokens.spacing.md;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sm,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: tokens.text.titleSm,
                  fontWeight: FontWeight.w600,
                  color: cs.hentai.textPrimary,
                ),
              ),
            ),
            GhostButton.icon(
              icon: LucideIcons.chevronLeft,
              tooltip: '向左滚动',
              semanticLabel: '向左滚动',
              iconSize: 16,
              size: 28,
              onPressed: _canScrollBack
                  ? () => _scrollByViewport(forward: false)
                  : null,
            ),
            GhostButton.icon(
              icon: LucideIcons.chevronRight,
              tooltip: '向右滚动',
              semanticLabel: '向右滚动',
              iconSize: 16,
              size: 28,
              onPressed: _canScrollForward
                  ? () => _scrollByViewport(forward: true)
                  : null,
            ),
          ],
        ),
        SizedBox(
          height: widget.itemHeight,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.itemCount,
            separatorBuilder: (BuildContext context, int index) =>
                SizedBox(width: spacing),
            itemBuilder: widget.itemBuilder,
          ),
        ),
      ],
    );
  }
}
