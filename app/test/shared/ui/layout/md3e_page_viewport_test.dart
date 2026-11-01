import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';

void main() {
  testWidgets('spec inside Md3ePageViewport uses viewport width, not window', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late Md3ePageLayoutSpec inside;
    late Md3ePageLayoutSpec outside;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1600, 900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 1600,
            height: 900,
            child: Row(
              children: <Widget>[
                // 模拟 shell 侧栏占去 256px，内容区 1344px（large 档）。
                const SizedBox(width: 256),
                SizedBox(
                  width: 1344,
                  child: Md3ePageViewport(
                    child: Builder(
                      builder: (BuildContext context) {
                        inside = Md3ePageLayoutSpec.of(context);
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                Builder(
                  builder: (BuildContext context) {
                    outside = Md3ePageLayoutSpec.of(context);
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(inside.sizeClass, Md3eWindowSizeClass.large);
    expect(outside.sizeClass, Md3eWindowSizeClass.extraLarge);
  });
}
