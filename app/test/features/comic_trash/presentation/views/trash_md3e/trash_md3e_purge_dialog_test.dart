import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash_md3e/trash_md3e_purge_dialog.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_purge_strategy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../support/pump_md3e_app.dart';

M3EButton _confirmButton(WidgetTester tester, String label) =>
    tester.widget<M3EButton>(find.widgetWithText(M3EButton, label));

Future<void> _pumpDialog(
  WidgetTester tester, {
  required PurgeTargetCounts counts,
  String? title,
  Locale locale = const Locale('zh'),
}) async {
  await pumpMd3eApp(
    tester,
    locale: locale,
    home: Scaffold(
      body: Md3eTrashPurgeConfirmDialog(title: title, counts: counts),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final AppLocalizations zh = lookupAppLocalizations(const Locale('zh'));

  testWidgets('local purge requires acknowledgement before confirm', (
    WidgetTester tester,
  ) async {
    await _pumpDialog(tester, title: '本子A', counts: (local: 1, remote: 0));

    expect(find.text('我了解磁盘上的资源将被永久删除'), findsOneWidget);
    expect(_confirmButton(tester, zh.trashPurge).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(_confirmButton(tester, zh.trashPurge).onPressed, isNotNull);
  });

  testWidgets(
    'remote purge shows library-only copy and requires acknowledgement',
    (WidgetTester tester) async {
      await _pumpDialog(
        tester,
        locale: const Locale('en'),
        title: 'Remote Comic',
        counts: (local: 0, remote: 1),
      );

      expect(
        find.textContaining('removed from the library only'),
        findsOneWidget,
      );
      expect(
        find.textContaining('permanently remove them from the library'),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsOneWidget);
      final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
      expect(_confirmButton(tester, en.trashPurge).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(_confirmButton(tester, en.trashPurge).onPressed, isNotNull);
    },
  );

  testWidgets('mixed batch purge shows both counts and gates on local', (
    WidgetTester tester,
  ) async {
    await _pumpDialog(tester, counts: (local: 2, remote: 3));

    expect(find.textContaining('2 本本地漫画将永久删除磁盘文件'), findsOneWidget);
    expect(find.textContaining('3 本远程漫画仅从库中移除'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(_confirmButton(tester, zh.trashPurge).onPressed, isNull);
  });

  testWidgets('remote-only batch purge requires acknowledgement', (
    WidgetTester tester,
  ) async {
    await _pumpDialog(tester, counts: (local: 0, remote: 4));

    expect(find.textContaining('4 本远程漫画'), findsOneWidget);
    expect(find.text('我了解将从库中永久移除，此操作不可撤销'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(_confirmButton(tester, zh.trashPurge).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(_confirmButton(tester, zh.trashPurge).onPressed, isNotNull);
  });
}
