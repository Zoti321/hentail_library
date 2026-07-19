import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';

Series _series({int itemCount = 3, int? totalCount}) {
  return Series(
    id: 'series-1',
    name: 'Test Series',
    folderPath: '/series',
    totalCount: totalCount,
    items: List<SeriesItem>.generate(
      itemCount,
      (int index) => SeriesItem(comicId: 'comic-$index', order: index),
    ),
  );
}

void main() {
  group('Series volume labels', () {
    testWidgets('volume count label uses l10n', (WidgetTester tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              l10n = context.l10n;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.seriesVolumeCountLabel(_series().items.length), '3 本');
      expect(
        l10n.seriesVolumeProgressLabel(current: 3, total: 12),
        '3 / 共 12 本',
      );
      expect(l10n.seriesVolumeProgressLabel(current: 3, total: null), isNull);
    });
  });
}
