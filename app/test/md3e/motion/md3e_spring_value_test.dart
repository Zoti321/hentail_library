import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_value.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_cover_read_progress_strip.dart';

import '../../support/pump_md3e_app.dart';

/// 在同一棵树内切换目标值（pumpWidget 会重建整棵树，无法观察补间）。
class _ValueHost extends StatefulWidget {
  const _ValueHost({super.key, required this.onBuild});

  final Widget Function(double target) onBuild;

  @override
  State<_ValueHost> createState() => _ValueHostState();
}

class _ValueHostState extends State<_ValueHost> {
  double _target = 0;

  void setTarget(double target) => setState(() => _target = target);

  @override
  Widget build(BuildContext context) => widget.onBuild(_target);
}

/// 逐帧采样，返回每帧相对上一帧的增量。
Future<List<double>> _sampleIncrements(
  WidgetTester tester,
  double Function() sample, {
  int frames = 40,
}) async {
  final List<double> increments = <double>[];
  double previous = sample();
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 8));
    final double current = sample();
    increments.add(current - previous);
    previous = current;
  }
  return increments;
}

void main() {
  testWidgets('spring value transitions non-linearly and settles on target', (
    WidgetTester tester,
  ) async {
    double shown = -1;
    final GlobalKey<_ValueHostState> key = GlobalKey<_ValueHostState>();
    await pumpMd3eApp(
      tester,
      home: _ValueHost(
        key: key,
        onBuild: (double target) => Md3eSpringValue(
          value: target,
          builder: (BuildContext context, double value, Widget? child) {
            shown = value;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(shown, 0);

    key.currentState!.setTarget(1);
    await tester.pump();
    final List<double> increments = await _sampleIncrements(
      tester,
      () => shown,
    );
    // 非线性：增量不是常数（弹簧先快后慢）。
    final double maxInc = increments.reduce(
      (double a, double b) => a > b ? a : b,
    );
    final double minInc = increments.reduce(
      (double a, double b) => a < b ? a : b,
    );
    expect(maxInc - minInc, greaterThan(0.02), reason: '补间应为非线性过渡');

    await tester.pumpAndSettle();
    expect(shown, closeTo(1, 0.001));
  });

  testWidgets('cover read progress strip animates its fill to the target', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_ValueHostState> key = GlobalKey<_ValueHostState>();
    await pumpMd3eApp(
      tester,
      home: SizedBox(
        width: 200,
        height: 40,
        child: _ValueHost(
          key: key,
          onBuild: (double target) => Md3eCoverReadProgressStrip(
            progress: target,
            activeColor: Colors.blue,
            trackColor: Colors.grey,
          ),
        ),
      ),
    );

    // 激活条是 Align 下唯一的 SizedBox（宽度 = 最大宽度 × 进度）。
    double fillWidth() => tester
        .getSize(
          find
              .descendant(
                of: find.byType(Align),
                matching: find.byType(SizedBox),
              )
              .first,
        )
        .width;
    final double full = tester
        .getSize(find.byType(Md3eCoverReadProgressStrip))
        .width;
    expect(fillWidth(), closeTo(0, 0.5));

    key.currentState!.setTarget(0.6);
    await tester.pump();
    final List<double> widths = <double>[];
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 8));
      widths.add(fillWidth());
    }
    // 中间帧：宽度处于起止之间。
    expect(widths.any((double w) => w > 1 && w < full * 0.6 - 1), isTrue);

    await tester.pumpAndSettle();
    expect(fillWidth(), closeTo(full * 0.6, 0.5));
  });
}
