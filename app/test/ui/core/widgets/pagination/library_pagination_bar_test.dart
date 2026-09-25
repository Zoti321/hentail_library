import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/value_objects/page_jump.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/pagination/library_pagination_bar.dart';

void _ignoreJump(PageJump _) {}

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
              page: 2,
              totalPages: 5,
              onJump: _ignoreJump,
            ),
          ),
        ),
      ),
    );

    expect(find.text('第 2 / 5 页'), findsOneWidget);
  });

  testWidgets('mid-range page keeps all page buttons enabled', (
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
              page: 2,
              totalPages: 5,
              onJump: _ignoreJump,
            ),
          ),
        ),
      ),
    );

    final Iterable<IconButton> buttons = tester.widgetList<IconButton>(
      find.byType(IconButton),
    );
    expect(buttons.length, 4);
    for (final IconButton button in buttons) {
      expect(button.onPressed, isNotNull);
    }
  });
}
