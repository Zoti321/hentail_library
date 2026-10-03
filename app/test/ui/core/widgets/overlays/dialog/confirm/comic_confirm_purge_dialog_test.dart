import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_purge_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_trash_dialog.dart';

import '../../../../../../support/pump_localized_app.dart';

DestructiveFilledButton _confirmButton(WidgetTester tester) => tester
    .widget<DestructiveFilledButton>(find.byType(DestructiveFilledButton));

void main() {
  testWidgets('local purge requires acknowledgement before confirm', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: ComicConfirmPurgeDialog(title: '本子A', isLocal: true),
      ),
    );

    expect(find.text('我了解磁盘上的资源将被永久删除'), findsOneWidget);
    expect(_confirmButton(tester).onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    expect(_confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'remote purge shows library-only copy without acknowledgement gate',
    (WidgetTester tester) async {
      await pumpLocalizedApp(
        tester,
        locale: const Locale('en'),
        home: Scaffold(
          body: ComicConfirmPurgeDialog(title: 'Remote Comic', isLocal: false),
        ),
      );

      expect(
        find.textContaining('removed from the library only'),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(_confirmButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets('mixed batch purge shows both counts and gates on local', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const Scaffold(
        body: ComicConfirmPurgeDialog.batch(counts: (local: 2, remote: 3)),
      ),
    );

    expect(find.textContaining('2 本本地漫画将永久删除磁盘文件'), findsOneWidget);
    expect(find.textContaining('3 本远程漫画仅从库中移除'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(_confirmButton(tester).onPressed, isNull);
  });

  testWidgets('remote-only batch purge needs no acknowledgement', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const Scaffold(
        body: ComicConfirmPurgeDialog.batch(counts: (local: 0, remote: 4)),
      ),
    );

    expect(find.textContaining('4 本远程漫画'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(_confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('trash confirm is light: no gate and no destructive button', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const Scaffold(body: ComicConfirmTrashDialog(title: '本子A')),
    );

    expect(find.textContaining('将移入「已删除」'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(DestructiveFilledButton), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
