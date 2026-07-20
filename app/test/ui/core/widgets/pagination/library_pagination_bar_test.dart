import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/pagination/library_pagination_bar.dart';

void main() {
  testWidgets('keeps pagination chrome visible while catalog reloads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: LibraryPaginationBar(
              target: LibraryPaginationTarget.series,
              page: 2,
              totalPages: 5,
              isLoading: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('第 2 / 5 页'), findsOneWidget);
  });
}
