import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/remove_saved_path_confirm_dialog.dart';

void main() {
  testWidgets('confirm action uses DestructiveFilledButton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: RemoveSavedPathConfirmDialog(path: r'E:\comics\lib'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DestructiveFilledButton), findsOneWidget);
    expect(
      tester
          .widget<DestructiveFilledButton>(
            find.byType(DestructiveFilledButton),
          )
          .onPressed,
      isNotNull,
    );
  });
}
