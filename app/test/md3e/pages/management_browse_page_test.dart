import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/lab/pages/md3e_management_browse_page.dart';

import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_create_interaction.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_draft_entity_chip.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('management browse page shows title, facet count, and chips', (
    WidgetTester tester,
  ) async {
    const ManagedNamedFacetKind facet = ManagedNamedFacetKind.tag;
    final List<String> chips = ManagementBrowsePagePreviewData.sampleChipsFor(
      facet,
    );

    await pumpApp(
      tester,
      home: Scaffold(
        body: ManagementBrowsePage(
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
    const ManagedNamedFacetKind facet = ManagedNamedFacetKind.tag;
    final List<String> chips = ManagementBrowsePagePreviewData.sampleChipsFor(
      facet,
    );

    await pumpApp(
      tester,
      home: Scaffold(
        body: ManagementBrowsePage(
          facet: facet,
          facetCount: chips.length,
          chipLabels: chips,
          createInteractionOverride: ManagementCreateInteraction.desktopInline,
          onFacetChanged: (_) {},
          onEntityCreated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ManagementDraftEntityChip), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(ManagementDraftEntityChip), findsOneWidget);
  });

  testWidgets('mobile dialog create hides draft chip until FAB opens dialog', (
    WidgetTester tester,
  ) async {
    const ManagedNamedFacetKind facet = ManagedNamedFacetKind.tag;
    final List<String> chips = ManagementBrowsePagePreviewData.sampleChipsFor(
      facet,
    );

    await pumpApp(
      tester,
      home: Scaffold(
        body: ManagementBrowsePage(
          facet: facet,
          facetCount: chips.length,
          chipLabels: chips,
          createInteractionOverride: ManagementCreateInteraction.mobileDialog,
          onFacetChanged: (_) {},
          onEntityCreated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ManagementDraftEntityChip), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('添加标签'), findsOneWidget);
    expect(find.byType(ManagementDraftEntityChip), findsNothing);
  });
}
