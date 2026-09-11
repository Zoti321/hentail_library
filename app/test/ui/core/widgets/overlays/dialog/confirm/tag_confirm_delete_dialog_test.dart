import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/tag_confirm_delete_dialog.dart';

import '../../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('footer action buttons use 4px corners', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      locale: const Locale('en'),
      home: const Scaffold(body: TagConfirmDeleteDialog(count: 1)),
    );
    await tester.pumpAndSettle();

    expect(
      _resolvedButtonRadius(tester, find.byType(TextButton)),
      BorderRadius.circular(4),
    );
    expect(
      _resolvedButtonRadius(tester, find.byType(FilledButton)),
      BorderRadius.circular(4),
    );
  });

  testWidgets('confirm action uses DestructiveFilledButton', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      locale: const Locale('en'),
      home: const Scaffold(body: TagConfirmDeleteDialog(count: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DestructiveFilledButton), findsOneWidget);
  });
}

BorderRadius _resolvedButtonRadius(WidgetTester tester, Finder buttonFinder) {
  final Material material = tester.widget<Material>(
    find.descendant(of: buttonFinder, matching: find.byType(Material)).first,
  );
  expect(material.shape, isA<RoundedRectangleBorder>());
  return (material.shape! as RoundedRectangleBorder).borderRadius
      as BorderRadius;
}
