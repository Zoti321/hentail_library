import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/navigation/desktop_sidebar.dart';

void main() {
  testWidgets(
    'settings system item clears injected bottom system viewPadding',
    (WidgetTester tester) async {
      const Size viewport = Size(256, 640);
      const double bottomInset = 48;

      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              size: viewport,
              viewPadding: EdgeInsets.only(bottom: bottomInset),
              padding: EdgeInsets.only(bottom: bottomInset),
            ),
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAppTheme(Brightness.light),
              home: Scaffold(
                body: DesktopSidebar(
                  activeId: 'home',
                  isExpanded: true,
                  showCollapseToggle: false,
                  onToggleExpanded: () {},
                  onDestinationSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder settings = find.text('设置');
      expect(settings, findsOneWidget);

      final Rect settingsRect = tester.getRect(settings);
      final double gapAboveViewportBottom =
          viewport.height - settingsRect.bottom;
      expect(gapAboveViewportBottom, greaterThanOrEqualTo(bottomInset));
    },
  );
}
