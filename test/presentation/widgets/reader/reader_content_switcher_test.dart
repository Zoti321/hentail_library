import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page/widgets/reader_content_switcher.dart';

void main() {
  testWidgets('ReaderContentSwitcher renders vertical child in vertical mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReaderContentSwitcher(
          comicId: 'comic-1',
          initialPage: 0,
          preferredPageIndex: null,
          isVertical: true,
          verticalChild: Text('vertical'),
          pagedChild: Text('paged'),
        ),
      ),
    );
    expect(find.text('vertical'), findsOneWidget);
    expect(find.text('paged'), findsNothing);
  });

  testWidgets('ReaderContentSwitcher renders paged child in paged mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReaderContentSwitcher(
          comicId: 'comic-1',
          initialPage: 0,
          preferredPageIndex: null,
          isVertical: false,
          verticalChild: Text('vertical'),
          pagedChild: Text('paged'),
        ),
      ),
    );
    expect(find.text('paged'), findsOneWidget);
    expect(find.text('vertical'), findsNothing);
  });
}
