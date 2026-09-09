import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/comic_confirm_delete_dialog.dart';

void main() {
  testWidgets('local delete requires acknowledgement before confirm', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: ComicConfirmDeleteDialog(title: '本子A', isLocal: true),
        ),
      ),
    );

    expect(find.text('我了解磁盘上的资源将被永久删除'), findsOneWidget);

    final FilledButton buttonBefore = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(buttonBefore.onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    final FilledButton buttonAfter = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(buttonAfter.onPressed, isNotNull);
    expect(
      buttonAfter.style?.backgroundColor?.resolve(<WidgetState>{}),
      Theme.of(tester.element(find.byType(FilledButton))).colorScheme.error,
    );
  });

  testWidgets(
    'remote delete shows library-only copy without acknowledgement gate',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: ComicConfirmDeleteDialog(
              title: 'Remote Comic',
              isLocal: false,
            ),
          ),
        ),
      );

      expect(
        find.textContaining('removed from the library only'),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );
}
