import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/managed_named_facet_ui.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('SegmentedCapsuleBar reports selection changes', (
    WidgetTester tester,
  ) async {
    var index = 0;
    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: SegmentedCapsuleBar(
              segments: ManagedNamedFacetUi.capsuleSegments(context.l10n),
              selectedIndex: index,
              onSelected: (int value) => index = value,
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('标签'));
    await tester.pumpAndSettle();

    expect(index, ManagedNamedFacetUi.indexOf(ManagedNamedFacetKind.tag));
  });
}
