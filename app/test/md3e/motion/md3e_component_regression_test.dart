import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_size.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_value.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_age_restriction_chip_slot.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_catalog_card_shell.dart';

import '../../support/pump_md3e_app.dart';

/// 切换 [visible] / [overlay] 的宿主，便于在同一棵树内驱动动效。
class _Host extends StatefulWidget {
  const _Host({super.key, required this.builder});

  final Widget Function(_HostState state) builder;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool visible = false;
  double overlay = 0;

  void setVisible(bool value) => setState(() => visible = value);

  void setOverlay(double value) => setState(() => overlay = value);

  @override
  Widget build(BuildContext context) => widget.builder(this);
}

void main() {
  testWidgets('age restriction chip expands with spring overshoot', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_HostState> key = GlobalKey<_HostState>();
    await pumpMd3eApp(
      tester,
      home: _Host(
        key: key,
        builder: (_HostState state) =>
            Md3eComicDetailAgeRestrictionChipSlot(visible: state.visible),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Md3eSpringSize), findsOneWidget);
    // 收起时不渲染子树（没有 Align）。
    expect(
      find.descendant(
        of: find.byType(Md3eSpringSize),
        matching: find.byType(Align),
      ),
      findsNothing,
    );

    key.currentState!.setVisible(true);
    await tester.pump();

    // 直接读取 Md3eSpringSize 的高度因子（芯片本身只有约 18px，像素过冲不稳定）。
    double heightFactor() {
      final Align align = tester.widget<Align>(
        find.byWidgetPredicate(
          (Widget w) => w is Align && w.heightFactor != null,
        ),
      );
      return align.heightFactor!;
    }

    final List<double> factors = <double>[];
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      factors.add(heightFactor());
    }
    await tester.pumpAndSettle();
    expect(heightFactor(), closeTo(1, 0.001));

    final double peak = factors.reduce((double a, double b) => a > b ? a : b);
    expect(peak, greaterThan(1.002), reason: '年龄限制标签展开应有回弹过冲');
  });

  testWidgets('card pinned overlay fades with a non-linear spring value', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_HostState> key = GlobalKey<_HostState>();
    await pumpMd3eApp(
      tester,
      home: _Host(
        key: key,
        builder: (_HostState state) => SizedBox(
          width: 160,
          height: 200,
          child: Md3eComicCatalogCardShell(
            enabled: true,
            trackHover: false,
            pinnedOverlayAlpha: state.overlay,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Md3eSpringValue), findsOneWidget);

    key.currentState!.setOverlay(0.5);
    await tester.pump();

    double overlayAlpha() {
      final ColoredBox box = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(Md3eSpringValue),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      return box.color.a;
    }

    final List<double> alphas = <double>[];
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      alphas.add(overlayAlpha());
    }
    final List<double> increments = <double>[
      for (int i = 1; i < alphas.length; i++) alphas[i] - alphas[i - 1],
    ];
    final double maxInc = increments.reduce(
      (double a, double b) => a > b ? a : b,
    );
    final double minInc = increments.reduce(
      (double a, double b) => a < b ? a : b,
    );
    expect(maxInc - minInc, greaterThan(0.001), reason: '遮罩渐变应为非线性');

    await tester.pumpAndSettle();
    expect(overlayAlpha(), closeTo(0.5, 0.01));
  });
}
