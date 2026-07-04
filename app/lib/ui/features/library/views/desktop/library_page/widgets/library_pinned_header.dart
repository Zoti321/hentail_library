import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/widgets.dart';

/// 库页可粘连 header：标题、数量 chip、Tab 切换与操作按钮（单行三栏）。
class LibraryPageHeaderSection extends StatelessWidget {
  const LibraryPageHeaderSection({super.key, this.onOpenFilterSort});

  final VoidCallback? onOpenFilterSort;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: tokens.layout.contentAreaPadding.copyWith(
        top: kLibraryHeaderVerticalPadding,
        bottom: kLibraryHeaderVerticalPadding,
      ),
      child: LibraryPageHeaderToolbar(onOpenFilterSort: onOpenFilterSort),
    );
  }
}

/// Header 底部阴影渐变高度。须画在 delegate 边界内——[SliverPersistentHeader] 会裁掉
/// 落在 extent 外的 [BoxDecoration.boxShadow]。
const double kLibraryHeaderShadowGradientHeight = 6;

class LibraryPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  LibraryPinnedHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(alignment: Alignment.topCenter, child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: kLibraryHeaderShadowGradientHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      cs.hentai.cardShadow.withValues(alpha: 0),
                      cs.hentai.cardShadow.withValues(alpha: 0.025),
                      cs.hentai.cardShadow.withValues(alpha: 0.05),
                    ],
                    stops: const <double>[0, 0.75, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant LibraryPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
