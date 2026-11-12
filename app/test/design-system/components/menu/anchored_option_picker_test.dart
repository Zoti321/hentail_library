import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/pump_app.dart';

class _PickerTrigger extends StatelessWidget {
  const _PickerTrigger({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Builder(
        builder: (BuildContext anchorContext) => TextButton(
          onPressed: () => pickAnchoredOption<int>(
            anchorContext,
            options: const <int>[1, 2, 3],
            selected: 1,
            labelOf: (int value) => '$value',
            onSelected: onSelected,
          ),
          child: const Text('打开'),
        ),
      ),
    );
  }
}

/// 在 initState 里调用（此时 `findRenderObject` 为空），用于覆盖「锚点为空」分支。
class _AnchorlessProbe extends StatefulWidget {
  const _AnchorlessProbe({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  State<_AnchorlessProbe> createState() => _AnchorlessProbeState();
}

class _AnchorlessProbeState extends State<_AnchorlessProbe> {
  @override
  void initState() {
    super.initState();
    pickAnchoredOption<int>(
      context,
      options: const <int>[1],
      selected: 1,
      labelOf: (int value) => '$value',
      onSelected: widget.onSelected,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('锚点为空时不触发回调', (WidgetTester tester) async {
    int calls = 0;
    await pumpApp(
      tester,
      home: Scaffold(body: _AnchorlessProbe(onSelected: (_) => calls++)),
    );
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('选中项按类型回传', (WidgetTester tester) async {
    int? picked;
    await pumpApp(
      tester,
      home: Scaffold(body: _PickerTrigger(onSelected: (int v) => picked = v)),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(picked, 2);
  });
}
