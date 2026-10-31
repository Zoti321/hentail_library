import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/confirm/comic_confirm_trash_dialog.dart';

import '../../../../../../support/pump_localized_app.dart';

void main() {
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
