import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/layout/page_layout_scope.dart';
import 'package:hentai_library/design-system/layout/page_layout_spec.dart';

/// 页面视口：用 [LayoutBuilder] 量出 [child] 实际可用宽度（shell 内容区，已扣除侧栏），
/// 并把解析好的 [PageLayoutSpec] 通过 [PageLayoutScope] 下发给子树。
///
/// 只需在 shell 内容区包一次；其下所有 [PageLayoutSpec.of] 自动取视口宽度。
class PageViewport extends StatelessWidget {
  const PageViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return PageLayoutScope(
          layout: PageLayoutSpec.resolve(
            LayoutContext.fromPlatform(viewportWidth: constraints.maxWidth),
          ),
          child: child,
        );
      },
    );
  }
}
