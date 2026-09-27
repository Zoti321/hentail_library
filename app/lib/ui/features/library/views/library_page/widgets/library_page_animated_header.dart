import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/interaction/app_motion.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_pinned_header.dart';
import 'package:hentai_library/ui/features/library/views/widgets/catalog_selection_header_section.dart';

/// 库页 pinned header：常规顶栏 ↔ 选择模式顶栏，带 cross-fade + 轻垂直位移。
class LibraryPageAnimatedHeader extends StatelessWidget {
  const LibraryPageAnimatedHeader({
    super.key,
    required this.selectionActive,
    required this.layoutTier,
    required this.horizontalPadding,
    required this.pageComicIds,
    this.onOpenFilterSort,
    this.onOpenNavigation,
  });

  final bool selectionActive;
  final LibraryLayoutTier layoutTier;
  final double horizontalPadding;
  final List<String> pageComicIds;
  final VoidCallback? onOpenFilterSort;
  final VoidCallback? onOpenNavigation;

  static const Offset _kEnterSlideBegin = Offset(0, -0.06);

  @override
  Widget build(BuildContext context) {
    final Duration duration = motionDurationOf(
      context,
      kLibraryHeaderModeTransitionDuration,
    );
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: _buildTransition,
      child: selectionActive
          ? CatalogSelectionHeaderSection(
              key: const ValueKey<String>('catalog-selection-header'),
              layoutTier: layoutTier,
              horizontalPadding: horizontalPadding,
              pageComicIds: pageComicIds,
              onOpenNavigation: onOpenNavigation,
            )
          : LibraryPageHeaderSection(
              key: const ValueKey<String>('library-header'),
              layoutTier: layoutTier,
              horizontalPadding: horizontalPadding,
              onOpenFilterSort: onOpenFilterSort,
              onOpenNavigation: onOpenNavigation,
            ),
    );
  }

  static Widget _buildTransition(Widget child, Animation<double> animation) {
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: _kEnterSlideBegin,
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
