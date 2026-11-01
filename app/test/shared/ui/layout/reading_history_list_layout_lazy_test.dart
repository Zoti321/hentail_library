import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/reading_history_list_layout.dart';

void main() {
  testWidgets('history list builds only rows near the viewport', (
    WidgetTester tester,
  ) async {
    const int itemCount = 200;
    final Set<int> built = <int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: CustomScrollView(
              slivers: <Widget>[
                Md3eReadingHistoryListLayout(
                  itemCount: itemCount,
                  itemBuilder: (BuildContext context, int index) {
                    built.add(index);
                    return const SizedBox(height: 100);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(built, isNotEmpty);
    // 视口高 600 + cacheExtent，远少于 200 条全部构建。
    expect(built.length, lessThan(60));
    expect(built.contains(itemCount - 1), isFalse);
  });
}
