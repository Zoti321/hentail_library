import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_named_facet.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eSegmentedCapsuleBar reports selection changes', (
    WidgetTester tester,
  ) async {
    var index = 0;
    await pumpMd3eApp(
      tester,
      home: Center(
        child: Md3eSegmentedCapsuleBar(
          segments: Md3eManagementNamedFacet.capsuleSegments(),
          selectedIndex: index,
          onSelected: (int value) => index = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('标签'));
    await tester.pumpAndSettle();

    expect(index, Md3eManagementNamedFacet.indexOf(Md3eManagementNamedFacet.tags));
  });
}
