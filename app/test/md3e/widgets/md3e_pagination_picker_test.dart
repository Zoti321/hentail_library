import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_compact_summary.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('compact page picker opens M3E sheet and returns chosen page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = Size(Md3eBreakpoints.previewWidthCompact, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final List<int> changed = <int>[];
    await pumpMd3eApp(
      tester,
      home: Center(
        child: Md3ePagination(
          page: 1,
          totalPages: 5,
          onPageChanged: changed.add,
        ),
      ),
    );

    await tester.tap(find.byType(Md3ePaginationCompactSummary));
    await tester.pumpAndSettle();
    expect(find.text('第 3 页'), findsOneWidget);

    await tester.tap(find.text('第 3 页'));
    await tester.pumpAndSettle();
    expect(changed, <int>[3]);
    expect(find.text('第 3 页'), findsNothing, reason: '选择后弹窗应关闭');
  });
}
