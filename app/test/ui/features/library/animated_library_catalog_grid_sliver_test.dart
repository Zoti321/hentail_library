import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReorderableBuilder grid child exposes ValueKey on root widget', (
    WidgetTester tester,
  ) async {
    const List<String> itemIds = <String>['comic-a', 'comic-b'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: ReorderableBuilder<void>.builder(
                  enableDraggable: false,
                  itemCount: itemIds.length,
                  childBuilder:
                      (Widget Function(Widget child, int index) wrapGridChild) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: itemIds.length,
                      itemBuilder: (BuildContext context, int index) {
                        return wrapGridChild(
                          Center(
                            key: ValueKey<String>(itemIds[index]),
                            child: Text(itemIds[index]),
                          ),
                          index,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('comic-a'), findsOneWidget);
    expect(find.text('comic-b'), findsOneWidget);
  });
}
