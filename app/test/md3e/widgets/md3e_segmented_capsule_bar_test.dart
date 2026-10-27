import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_managed_named_facet_ui.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eSegmentedCapsuleBar reports selection changes', (
    WidgetTester tester,
  ) async {
    var index = 0;
    await pumpMd3eApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return Center(
            child: Md3eSegmentedCapsuleBar(
              segments: Md3eManagedNamedFacetUi.capsuleSegments(context.l10n),
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

    expect(
      index,
      Md3eManagedNamedFacetUi.indexOf(ManagedNamedFacetKind.tag),
    );
  });
}
