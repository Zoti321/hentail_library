import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_facet_search_bar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../../support/pump_app.dart';

void main() {
  testWidgets('compact uses full available width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpApp(
      tester,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ManagementFacetSearchBar(
            controller: controller,
            hintText: '搜索名称…',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size barSize = tester.getSize(find.byType(M3ESearchBar));
    expect(barSize.width, closeTo(390 - 32, 0.5));
    expect(barSize.height, closeTo(ManagementFacetSearchBar.height, 0.5));
  });

  testWidgets('medium+ caps width and stays start-aligned', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpApp(
      tester,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ManagementFacetSearchBar(
            controller: controller,
            hintText: 'Search by name…',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size barSize = tester.getSize(find.byType(M3ESearchBar));
    expect(barSize.width, lessThanOrEqualTo(ManagementFacetSearchBar.maxWidth));
    expect(barSize.height, closeTo(ManagementFacetSearchBar.height, 0.5));

    final double barLeft = tester.getTopLeft(find.byType(M3ESearchBar)).dx;
    expect(barLeft, closeTo(24, 0.5));
  });

  testWidgets('shows match count to the right of the search bar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpApp(
      tester,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ManagementFacetSearchBar(
            controller: controller,
            hintText: 'Search by name…',
            matchCountLabel: '3 个结果',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 个结果'), findsOneWidget);
    final double barRight = tester.getTopRight(find.byType(M3ESearchBar)).dx;
    final double labelLeft = tester.getTopLeft(find.text('3 个结果')).dx;
    expect(labelLeft, greaterThan(barRight));
  });

  testWidgets('forwards onChanged when typing', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    final List<String> changes = <String>[];

    await pumpApp(
      tester,
      home: Scaffold(
        body: ManagementFacetSearchBar(
          controller: controller,
          hintText: '搜索名称…',
          onChanged: changes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'alpha');
    await tester.pump();

    expect(changes, contains('alpha'));
  });

  testWidgets('forwards onChanged when clear button empties the field', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(text: 'alpha');
    addTearDown(controller.dispose);
    final List<String> changes = <String>[];

    await pumpApp(
      tester,
      home: Scaffold(
        body: ManagementFacetSearchBar(
          controller: controller,
          hintText: '搜索名称…',
          onChanged: changes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(M3EIcons.close));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changes, contains(''));
  });
}
