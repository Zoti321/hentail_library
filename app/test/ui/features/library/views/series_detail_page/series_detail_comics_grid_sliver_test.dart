import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_comics_grid.dart';

Future<void> _pumpGridSliver(
  WidgetTester tester, {
  required List<Comic> comics,
  bool isLoading = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SeriesDetailComicsGridSliver(
                comics: comics,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'SeriesDetailComicsGridSliver loading state mounts under SliverPadding',
    (WidgetTester tester) async {
      await _pumpGridSliver(tester, comics: const <Comic>[], isLoading: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'SeriesDetailComicsGridSliver empty state mounts under SliverPadding',
    (WidgetTester tester) async {
      await _pumpGridSliver(tester, comics: const <Comic>[]);

      expect(tester.takeException(), isNull);
      expect(find.byType(SeriesDetailComicsGridSliver), findsOneWidget);
    },
  );
}
