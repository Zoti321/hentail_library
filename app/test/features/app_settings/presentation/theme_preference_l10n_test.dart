import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/app_setting.dart';

void main() {
  testWidgets('theme preference labels follow locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            final AppLocalizations l10n = context.l10n;
            return Text(
              '${l10n.themePreferenceLabel(AppThemePreference.system)}|'
              '${l10n.themePreferenceLabel(AppThemePreference.light)}|'
              '${l10n.themePreferenceLabel(AppThemePreference.dark)}|'
              '${l10n.settingsThemeLabel}',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System|Light|Dark|App theme'), findsOneWidget);
  });
}
