import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('expanded width shows list and detail panes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 1280,
          height: 400,
          child: ListDetailAdaptiveLayout(
            listPaneKey: const Key('_list'),
            detailPaneKey: const Key('_detail'),
            listPane: const Text('list'),
            detailPane: const Text('detail'),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('_list')), findsOneWidget);
    expect(find.byKey(const Key('_detail')), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('compact width shows list only by default', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 390,
          height: 400,
          child: ListDetailAdaptiveLayout(
            listPaneKey: const Key('_list'),
            detailPaneKey: const Key('_detail'),
            listPane: const Text('list'),
            detailPane: const Text('detail'),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('_list')), findsOneWidget);
    expect(find.byKey(const Key('_detail')), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
