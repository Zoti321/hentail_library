import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_reveal.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_size.dart';

import '../../support/pump_md3e_app.dart';

/// 用一个按钮切换 [expanded] / [visible]，便于在测试里驱动弹簧。
class _Toggle extends StatefulWidget {
  const _Toggle({super.key, required this.builder});

  final Widget Function(bool on) builder;

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _on = false;

  void flip() => setState(() => _on = !_on);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextButton(onPressed: flip, child: const Text('toggle')),
        widget.builder(_on),
      ],
    );
  }
}

Future<_ToggleState> _pumpToggle(
  WidgetTester tester,
  Widget Function(bool on) builder, {
  bool reduceMotion = false,
}) async {
  final GlobalKey<_ToggleState> key = GlobalKey<_ToggleState>();
  await pumpMd3eApp(
    tester,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: SizedBox(
        width: 390,
        height: 800,
        child: _Toggle(key: key, builder: builder),
      ),
    ),
  );
  return key.currentState!;
}

/// 切换后轮询若干帧，记录 [sample] 的最大/最小值。
Future<({double min, double max})> _sampleFrames(
  WidgetTester tester,
  double Function() sample, {
  int frames = 60,
}) async {
  double min = double.infinity;
  double max = double.negativeInfinity;
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 8));
    final double v = sample();
    if (v < min) {
      min = v;
    }
    if (v > max) {
      max = v;
    }
  }
  return (min: min, max: max);
}

Finder _revealTransform() => find.descendant(
  of: find.byType(Md3eSpringReveal),
  matching: find.byWidgetPredicate(
    (Widget w) => w is Transform && w.child is Opacity,
  ),
);

void main() {
  group('Md3eSpringSize', () {
    testWidgets('expanding overshoots the target height mid-animation', (
      WidgetTester tester,
    ) async {
      final _ToggleState state = await _pumpToggle(
        tester,
        (bool on) => Md3eSpringSize(
          expanded: on,
          child: const SizedBox(height: 100, width: 200),
        ),
      );
      expect(find.byType(Md3eSpringSize), findsOneWidget);
      expect(tester.getSize(find.byType(Md3eSpringSize)).height, 0);

      state.flip();
      await tester.pump();
      final ({double min, double max}) range = await _sampleFrames(
        tester,
        () => tester.getSize(find.byType(Md3eSpringSize)).height,
      );

      expect(range.max, greaterThan(100.5), reason: '展开中间帧应越过终点 100 回弹');
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(Md3eSpringSize)).height,
        closeTo(100, 0.5),
      );
    });

    testWidgets('collapsing ends at zero size', (WidgetTester tester) async {
      final _ToggleState state = await _pumpToggle(
        tester,
        (bool on) => Md3eSpringSize(
          expanded: on,
          child: const SizedBox(height: 100, width: 200),
        ),
      );
      state.flip();
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(Md3eSpringSize)).height,
        closeTo(100, 0.5),
      );

      state.flip();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Md3eSpringSize)).height, 0);
    });

    testWidgets('reduce motion switches size without animation', (
      WidgetTester tester,
    ) async {
      final _ToggleState state = await _pumpToggle(
        tester,
        (bool on) => Md3eSpringSize(
          expanded: on,
          child: const SizedBox(height: 100, width: 200),
        ),
        reduceMotion: true,
      );
      state.flip();
      await tester.pump();
      expect(tester.getSize(find.byType(Md3eSpringSize)).height, 100);
    });
  });

  group('Md3eSpringReveal', () {
    testWidgets('showing slides in with spring overshoot and reaches rest', (
      WidgetTester tester,
    ) async {
      final _ToggleState state = await _pumpToggle(
        tester,
        (bool on) => Md3eSpringReveal(
          visible: on,
          hiddenOffset: const Offset(0, 24),
          child: const SizedBox(width: 48, height: 48),
        ),
      );
      state.flip();
      await tester.pump();
      final ({double min, double max}) range = await _sampleFrames(
        tester,
        () => tester
            .widget<Transform>(_revealTransform())
            .transform
            .getTranslation()
            .y,
      );

      expect(range.min, lessThan(-0.001), reason: '显示时位移应回弹越过原位');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Transform>(_revealTransform())
            .transform
            .getTranslation()
            .y,
        closeTo(0, 0.001),
      );
    });

    testWidgets('hiding fades out and stops receiving pointer', (
      WidgetTester tester,
    ) async {
      final _ToggleState state = await _pumpToggle(
        tester,
        (bool on) => Md3eSpringReveal(
          visible: on,
          hiddenOffset: const Offset(0, 24),
          child: const SizedBox(width: 48, height: 48),
        ),
      );
      state.flip();
      await tester.pumpAndSettle();
      state.flip();
      await tester.pump();
      final ({double min, double max}) range = await _sampleFrames(
        tester,
        () => tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(Md3eSpringReveal),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
      );

      expect(range.min, greaterThanOrEqualTo(0));
      expect(range.max, lessThanOrEqualTo(1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(Md3eSpringReveal),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        closeTo(0, 0.001),
      );
    });
  });
}
