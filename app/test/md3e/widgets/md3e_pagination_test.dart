import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3ePagination hides when only one page', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthExpanded,
          child: Md3ePagination(
            page: 1,
            totalPages: 1,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(Md3ePagination), findsOneWidget);
    expect(find.text('上一页'), findsNothing);
  });

  testWidgets('compact layout uses prev/next labels', (
    WidgetTester tester,
  ) async {
    var page = 2;
    await pumpMd3eApp(
      tester,
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Center(
            child: SizedBox(
              width: Md3eBreakpoints.previewWidthCompact,
              child: Md3ePagination(
                page: page,
                totalPages: 5,
                onPageChanged: (int value) => setState(() => page = value),
              ),
            ),
          );
        },
      ),
    );
    expect(find.byType(M3EIconButton), findsNWidgets(2));
    expect(find.text('2 / 5'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(page, 3);
    expect(find.text('3 / 5'), findsOneWidget);
  });

  testWidgets('standard layout shows numeric page controls', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthExpanded,
          child: Md3ePagination(
            page: 2,
            totalPages: 12,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('上一页'), findsNothing);
  });
}
