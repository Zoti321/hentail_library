import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_history_browse_page_lab_host.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page_lab_host.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('LabHost 点击列表项进入阅读页', (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Md3eHistoryBrowsePageLabHost(clock: DateTime(2026, 6, 15, 14)),
    );

    await tester.tap(find.text('只有神知道的世界').first);
    await tester.pumpAndSettle();

    expect(find.byType(Md3eReaderPageLabHost), findsOneWidget);
  });

  testWidgets('LabHost 删除记录会移除对应假数据', (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Md3eHistoryBrowsePageLabHost(clock: DateTime(2026, 6, 15, 14)),
    );

    expect(find.byType(Md3eReadingHistoryListItem), findsNWidgets(6));

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除记录').first);
    await tester.pumpAndSettle();

    expect(find.byType(Md3eReadingHistoryListItem), findsNWidgets(5));
  });

  testWidgets('LabHost 确认清空后 preview 列表为空', (WidgetTester tester) async {
    final DateTime clock = DateTime(2026, 6, 15, 14);

    await pumpMd3eApp(
      tester,
      home: Md3eHistoryBrowsePageLabHost(clock: clock),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(Md3eHistoryBrowsePageLabHost)),
    );

    expect(find.text('只有神知道的世界'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(l10n.commonClear));
    await tester.pumpAndSettle();

    expect(find.byType(M3EDialog), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(M3EDialog),
        matching: find.text(l10n.commonClear),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.historyEmpty), findsOneWidget);
    expect(find.text('只有神知道的世界'), findsNothing);
  });
}
