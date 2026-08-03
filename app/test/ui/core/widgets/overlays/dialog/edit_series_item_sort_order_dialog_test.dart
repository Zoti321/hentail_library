import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_series_item_sort_order_dialog.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  required Future<void> Function(double sortOrder, bool locked) onSubmit,
  bool initialSortOrderLocked = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext dialogContext) =>
                      EditSeriesItemSortOrderDialog(
                        seriesId: 'series-1',
                        comicId: 'comic-1',
                        comicTitle: 'Test Comic',
                        initialSortOrder: 1,
                        initialSortOrderLocked: initialSortOrderLocked,
                        onSubmit: onSubmit,
                      ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty or non-number sort order blocks save', (
    WidgetTester tester,
  ) async {
    var saveCount = 0;

    Future<void> onSubmit(double sortOrder, bool locked) async {
      saveCount += 1;
    }

    await _openDialog(tester, onSubmit: onSubmit);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saveCount, 0);
    expect(find.byType(EditSeriesItemSortOrderDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saveCount, 0);
    expect(find.text('Enter a valid number'), findsOneWidget);
  });
}
