import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_management_browse_page_lab_host.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_create_interaction.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('LabHost Dialog 创建实体后 chip 出现在 preview 列表', (
    WidgetTester tester,
  ) async {
    const ManagedNamedFacetKind facet = ManagedNamedFacetKind.tag;
    const String newLabel = 'Lab 新建标签';

    await pumpMd3eApp(
      tester,
      home: Md3eManagementBrowsePageLabHost(
        initialFacet: facet,
        createInteractionOverride:
            Md3eManagementCreateInteraction.mobileDialog,
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(Md3eManagementBrowsePageLabHost)),
    );

    expect(find.text(newLabel), findsNothing);

    await tester.tap(find.bySemanticsLabel(l10n.metadataAddLabel(facet)));
    await tester.pumpAndSettle();

    expect(find.byType(M3EDialog), findsOneWidget);

    await tester.enterText(find.byType(M3ETextField), newLabel);
    await tester.tap(
      find.descendant(
        of: find.byType(M3EDialog),
        matching: find.text(l10n.commonAdd),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(newLabel), findsOneWidget);
    expect(find.text('11 个标签'), findsOneWidget);
  });
}
