import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_delete_dialog.dart';

import '../../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('local delete requires acknowledgement before confirm', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const Scaffold(
        body: ComicConfirmDeleteDialog(title: '本子A', isLocal: true),
      ),
    );

    expect(find.text('我了解磁盘上的资源将被永久删除'), findsOneWidget);

    final DestructiveFilledButton buttonBefore = tester
        .widget<DestructiveFilledButton>(find.byType(DestructiveFilledButton));
    expect(buttonBefore.onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    final DestructiveFilledButton buttonAfter = tester
        .widget<DestructiveFilledButton>(find.byType(DestructiveFilledButton));
    expect(buttonAfter.onPressed, isNotNull);
  });

  testWidgets(
    'remote delete shows library-only copy without acknowledgement gate',
    (WidgetTester tester) async {
      await pumpLocalizedApp(
        tester,
        locale: const Locale('en'),
        home: const Scaffold(
          body: ComicConfirmDeleteDialog(title: 'Remote Comic', isLocal: false),
        ),
      );

      expect(
        find.textContaining('removed from the library only'),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(
        tester
            .widget<DestructiveFilledButton>(
              find.byType(DestructiveFilledButton),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('confirm action uses DestructiveFilledButton', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const Scaffold(
        body: ComicConfirmDeleteDialog(title: '本子A', isLocal: false),
      ),
    );

    expect(find.byType(DestructiveFilledButton), findsOneWidget);
  });
}
