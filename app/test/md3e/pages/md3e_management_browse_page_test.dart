import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_management_browse_page.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_create_interaction.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_draft_entity_chip.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_named_facet.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('management browse page shows title, facet count, and chips', (
    WidgetTester tester,
  ) async {
    const Md3eManagementNamedFacet facet = Md3eManagementNamedFacet.tags;
    final List<String> chips =
        Md3eManagementBrowsePagePreviewData.sampleChipsFor(facet);

    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: Md3eManagementBrowsePage(
          facet: facet,
          facetCount: chips.length,
          chipLabels: chips,
          onFacetChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('管理'), findsOneWidget);
    expect(find.text('10 个标签'), findsOneWidget);
    expect(find.text('奇幻'), findsOneWidget);
    expect(find.byType(M3EChip), findsWidgets);
  });

  testWidgets('desktop draft chip appears only after FAB tap', (
    WidgetTester tester,
  ) async {
    const Md3eManagementNamedFacet facet = Md3eManagementNamedFacet.tags;
    final List<String> chips =
        Md3eManagementBrowsePagePreviewData.sampleChipsFor(facet);

    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: Md3eManagementBrowsePage(
          facet: facet,
          facetCount: chips.length,
          chipLabels: chips,
          createInteractionOverride:
              Md3eManagementCreateInteraction.desktopInline,
          onFacetChanged: (_) {},
          onEntityCreated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Md3eManagementDraftEntityChip), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(Md3eManagementDraftEntityChip), findsOneWidget);
  });

  testWidgets('mobile dialog create hides draft chip until FAB opens dialog', (
    WidgetTester tester,
  ) async {
    const Md3eManagementNamedFacet facet = Md3eManagementNamedFacet.tags;
    final List<String> chips =
        Md3eManagementBrowsePagePreviewData.sampleChipsFor(facet);

    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: Md3eManagementBrowsePage(
          facet: facet,
          facetCount: chips.length,
          chipLabels: chips,
          createInteractionOverride:
              Md3eManagementCreateInteraction.mobileDialog,
          onFacetChanged: (_) {},
          onEntityCreated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Md3eManagementDraftEntityChip), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('新建标签'), findsOneWidget);
    expect(find.byType(Md3eManagementDraftEntityChip), findsNothing);
  });
}
