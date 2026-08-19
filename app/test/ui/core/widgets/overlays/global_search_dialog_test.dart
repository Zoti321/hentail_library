import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/core/widgets/overlays/global_search_dialog.dart';

void main() {
  testWidgets('global search dialog autofocuses the query field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showGlobalSearchDialog(context),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomTextField), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<CustomTextField>(),
      isNotNull,
    );
  });

  testWidgets('submit closes the dialog when query is non-empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showGlobalSearchDialog(context),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, '搜索'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
