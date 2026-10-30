import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_positioned.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';

import '../../support/pump_md3e_app.dart';

/// 指示器（Md3eSpringPositioned 内的 DecoratedBox）的左边缘。
double _indicatorLeft(WidgetTester tester) => tester
    .getTopLeft(
      find
          .descendant(
            of: find.byType(Md3eSpringPositioned),
            matching: find.byType(DecoratedBox),
          )
          .first,
    )
    .dx;

/// 逐帧采样左边缘，返回全部采样值。
Future<List<double>> _sampleLeft(WidgetTester tester, {int frames = 60}) async {
  final List<double> values = <double>[];
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 8));
    values.add(_indicatorLeft(tester));
  }
  return values;
}

class _SegmentHost extends StatefulWidget {
  const _SegmentHost({super.key});

  @override
  State<_SegmentHost> createState() => _SegmentHostState();
}

class _SegmentHostState extends State<_SegmentHost> {
  int _selected = 0;

  void select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) {
    return Md3eSegmentedCapsuleBar(
      segments: const <Md3eSegmentedCapsuleSegment>[
        Md3eSegmentedCapsuleSegment(label: 'Alpha'),
        Md3eSegmentedCapsuleSegment(label: 'Beta'),
        Md3eSegmentedCapsuleSegment(label: 'Gamma'),
      ],
      selectedIndex: _selected,
      onSelected: select,
    );
  }
}

class _PageHost extends StatefulWidget {
  const _PageHost({super.key});

  @override
  State<_PageHost> createState() => _PageHostState();
}

class _PageHostState extends State<_PageHost> {
  int page = 1;

  @override
  Widget build(BuildContext context) {
    return Md3ePagination(
      page: page,
      totalPages: 10,
      onPageChanged: (int value) => setState(() => page = value),
    );
  }
}

void main() {
  testWidgets('segmented capsule indicator springs past its target', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(tester, home: const _SegmentHost());
    // 指示器在首帧测量后才挂载，先让布局稳定。
    await tester.pumpAndSettle();
    final double start = _indicatorLeft(tester);

    await tester.tap(find.text('Gamma'));
    await tester.pump();
    final List<double> samples = await _sampleLeft(tester);
    await tester.pumpAndSettle();
    final double target = _indicatorLeft(tester);

    expect(target, greaterThan(start), reason: '指示器应移动到 Gamma');
    // 弹簧回弹：中间帧越过终点。
    expect(
      samples.reduce((double a, double b) => a > b ? a : b),
      greaterThan(target + 0.2),
      reason: '分段胶囊指示器应有回弹过冲',
    );
  });

  testWidgets('pagination indicator springs past its target', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = Size(Md3eBreakpoints.previewWidthExpanded, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpMd3eApp(tester, home: const _PageHost());
    await tester.pumpAndSettle();
    final double start = _indicatorLeft(tester);

    await tester.tap(find.text('3').first);
    await tester.pump();
    final List<double> samples = await _sampleLeft(tester);
    await tester.pumpAndSettle();
    final double target = _indicatorLeft(tester);

    expect(target, greaterThan(start), reason: '指示器应移动到第 3 页');
    expect(
      samples.reduce((double a, double b) => a > b ? a : b),
      greaterThan(target + 0.2),
      reason: '分页指示器应有回弹过冲',
    );
  });
}
