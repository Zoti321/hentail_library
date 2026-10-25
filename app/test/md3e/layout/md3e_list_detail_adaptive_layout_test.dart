import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_list_detail_adaptive_layout.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('expanded width shows list and detail panes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 1280,
          height: 400,
          child: Md3eListDetailAdaptiveLayout(
            listPaneKey: const Key('md3e_list'),
            detailPaneKey: const Key('md3e_detail'),
            listPane: const Text('list'),
            detailPane: const Text('detail'),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('md3e_list')), findsOneWidget);
    expect(find.byKey(const Key('md3e_detail')), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('compact width shows list only by default', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 390,
          height: 400,
          child: Md3eListDetailAdaptiveLayout(
            listPaneKey: const Key('md3e_list'),
            detailPaneKey: const Key('md3e_detail'),
            listPane: const Text('list'),
            detailPane: const Text('detail'),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('md3e_list')), findsOneWidget);
    expect(find.byKey(const Key('md3e_detail')), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
