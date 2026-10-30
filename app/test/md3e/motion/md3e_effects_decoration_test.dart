import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_effects_decorated_box.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_page_button.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

const Color _from = Color(0xFF000000);
const Color _to = Color(0xFFFFFFFF);

/// 逐通道比较颜色（插值结果的 colorSpace 可能与字面量不同，直接 == 会误判）。
void _expectColorClose(Color actual, Color expected) {
  expect(actual.r, closeTo(expected.r, 0.01));
  expect(actual.g, closeTo(expected.g, 0.01));
  expect(actual.b, closeTo(expected.b, 0.01));
  expect(actual.a, closeTo(expected.a, 0.01));
}

/// 解析 [Md3eEffectsDecoratedBox] 外层的 DecoratedBox（树序第一个）。
BoxDecoration _boxDecoration(WidgetTester tester, Finder scope) {
  final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
    find.descendant(of: scope, matching: find.byType(DecoratedBox)),
  );
  return boxes.first.decoration as BoxDecoration;
}

void main() {
  testWidgets(
    'background transitions through intermediate colors and settles',
    (WidgetTester tester) async {
      final GlobalKey<_HostState> key = GlobalKey<_HostState>();
      await pumpMd3eApp(tester, home: _Host(key: key));
      key.currentState!.setColor(_to);
      await tester.pump();

      final Finder scope = find.byType(Md3eEffectsDecoratedBox);
      final List<Color> seen = <Color>[];
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        seen.add(_boxDecoration(tester, scope).color!);
      }
      // 中间帧必须落在起止颜色之间（非跳变）。
      expect(
        seen.any((Color c) => c.r > 0.05 && c.r < 0.95),
        isTrue,
        reason: '背景应有中间过渡帧',
      );
      await tester.pumpAndSettle();
      _expectColorClose(_boxDecoration(tester, scope).color!, _to);
    },
  );

  testWidgets('reduce motion jumps straight to the target decoration', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_HostState> key = GlobalKey<_HostState>();
    await pumpMd3eApp(
      tester,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _Host(key: key),
      ),
    );
    key.currentState!.setColor(_to);
    await tester.pump();
    _expectColorClose(
      _boxDecoration(tester, find.byType(Md3eEffectsDecoratedBox)).color!,
      _to,
    );
  });

  testWidgets('split row corner radius animates on press', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: SizedBox(
        width: 360,
        height: 200,
        child: Md3eSplitListRow(
          onTap: () {},
          child: const SizedBox(height: 56, child: Text('row')),
        ),
      ),
    );
    final Finder row = find.byType(Md3eSplitListRow);
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(row),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final BorderRadius mid =
        (_boxDecoration(tester, row).borderRadius! as BorderRadius);
    final double midRadius = mid.topLeft.x;
    expect(midRadius, greaterThan(kMd3eSplitListInnerRadius));
    expect(midRadius, lessThan(kMd3eTonalSurfaceRadius));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('page button fill transitions when selection changes', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_PageHostState> key = GlobalKey<_PageHostState>();
    await pumpMd3eApp(tester, home: _PageHost(key: key));
    final Finder button = find.byType(Md3ePaginationPageButton);
    final Finder scope = find.descendant(
      of: button,
      matching: find.byType(Md3eEffectsDecoratedBox),
    );
    final Color before =
        _boxDecoration(tester, button).color ?? Colors.transparent;

    key.currentState!.setSelected(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final Color mid = _boxDecoration(tester, scope).color!;
    expect(mid, isNot(before), reason: '选中背景应有过渡中间帧');

    await tester.pumpAndSettle();
    final M3EColorScheme scheme = M3ETheme.of(tester.element(button))
        .colorScheme;
    _expectColorClose(
      _boxDecoration(tester, scope).color!,
      scheme.primaryContainer,
    );
  });
}

class _Host extends StatefulWidget {
  const _Host({super.key});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Color _color = _from;

  void setColor(Color color) => setState(() => _color = color);

  @override
  Widget build(BuildContext context) {
    return Md3eEffectsDecoratedBox(
      decoration: BoxDecoration(color: _color),
      child: const SizedBox(width: 40, height: 40),
    );
  }
}

class _PageHost extends StatefulWidget {
  const _PageHost({super.key});

  @override
  State<_PageHost> createState() => _PageHostState();
}

class _PageHostState extends State<_PageHost> {
  bool _selected = false;

  void setSelected(bool selected) => setState(() => _selected = selected);

  @override
  Widget build(BuildContext context) {
    return Md3ePaginationPageButton(
      page: 2,
      selected: _selected,
      onPressed: () {},
    );
  }
}
