import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_positioned.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

Future<void> _pumpWithWindowSize(
  WidgetTester tester, {
  required Size windowSize,
  required Widget home,
}) async {
  tester.view.physicalSize = windowSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await pumpMd3eApp(tester, home: home);
}

void main() {
  testWidgets('Md3ePagination hides when only one page', (
    WidgetTester tester,
  ) async {
    await _pumpWithWindowSize(
      tester,
      windowSize: Size(
        Md3eBreakpoints.previewWidthExpanded,
        800,
      ),
      home: Center(
        child: Md3ePagination(
          page: 1,
          totalPages: 1,
          onPageChanged: (_) {},
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
    await _pumpWithWindowSize(
      tester,
      windowSize: Size(Md3eBreakpoints.previewWidthCompact, 844),
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Center(
            child: Md3ePagination(
              page: page,
              totalPages: 5,
              onPageChanged: (int value) => setState(() => page = value),
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
    await _pumpWithWindowSize(
      tester,
      windowSize: Size(
        Md3eBreakpoints.previewWidthExpanded,
        800,
      ),
      home: Center(
        child: Md3ePagination(
          page: 2,
          totalPages: 12,
          onPageChanged: (_) {},
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('上一页'), findsNothing);
    expect(find.byType(Md3eSpringPositioned), findsOneWidget);
  });
}
