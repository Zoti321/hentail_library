import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/clear_reading_history_confirm_dialog.dart';

void main() {
  testWidgets('confirm action uses DestructiveFilledButton with clear label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: ClearReadingHistoryConfirmDialog()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DestructiveFilledButton), findsOneWidget);
    expect(find.text('清空'), findsOneWidget);
  });
}
