import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/tag_confirm_delete_dialog.dart';

void main() {
  testWidgets('footer action buttons use 4px corners', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: TagConfirmDeleteDialog(count: 1)),
      ),
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
}

BorderRadius _resolvedButtonRadius(WidgetTester tester, Finder buttonFinder) {
  final Material material = tester.widget<Material>(
    find.descendant(of: buttonFinder, matching: find.byType(Material)).first,
  );
  expect(material.shape, isA<RoundedRectangleBorder>());
  return (material.shape! as RoundedRectangleBorder).borderRadius
      as BorderRadius;
}
