import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Documents that ScrollablePositionedList tends to keep the anchored index
/// when item heights change uniformly — so resume drift is more likely from
/// premature visible→index sync than from SPL alone.
void main() {
  testWidgets(
    'uniform item height growth keeps primary visible near jump target',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const int targetIndex = 53;
      const int itemCount = 70;
      final ItemScrollController scrollController = ItemScrollController();
      final ItemPositionsListener positionsListener =
          ItemPositionsListener.create();
      final ValueNotifier<double> itemHeight = ValueNotifier<double>(40);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<double>(
              valueListenable: itemHeight,
              builder: (BuildContext context, double height, Widget? child) {
                return ScrollablePositionedList.builder(
                  itemScrollController: scrollController,
                  itemPositionsListener: positionsListener,
                  initialScrollIndex: targetIndex,
                  itemCount: itemCount,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(height: height, child: Text('$index'));
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      scrollController.jumpTo(index: targetIndex, alignment: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final int before = _primaryVisibleIndex(
        positionsListener.itemPositions.value,
      )!;
      itemHeight.value = 800;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final int after = _primaryVisibleIndex(
        positionsListener.itemPositions.value,
      )!;

      expect((before - targetIndex).abs() <= 1, isTrue);
      expect((after - targetIndex).abs() <= 1, isTrue);
    },
  );
}

int? _primaryVisibleIndex(Iterable<ItemPosition> positions) {
  final List<ItemPosition> visible = positions
      .where(
        (ItemPosition p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1,
      )
      .toList();
  if (visible.isEmpty) {
    return null;
  }
  visible.sort(
    (ItemPosition a, ItemPosition b) =>
        a.itemLeadingEdge.abs().compareTo(b.itemLeadingEdge.abs()),
  );
  return visible.first.index;
}
