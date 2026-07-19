import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/views/library_page/library_empty_state.dart';

void main() {
  testWidgets(
    'comics table empty shows English copy when locale is en',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              final LibraryEmptyStateContent content =
                  resolveLibraryEmptyStateContent(
                    l10n: AppLocalizations.of(context),
                    entity: LibraryDisplayTarget.comics,
                    isTableEmpty: true,
                  );
              return Text('${content.title}\n${content.hint}');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No comics yet'), findsOneWidget);
      expect(
        find.textContaining('Add a path under Selected Paths and scan'),
        findsOneWidget,
      );
    },
  );
}
