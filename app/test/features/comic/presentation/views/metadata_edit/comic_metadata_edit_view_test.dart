import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_page.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_form.dart';
import 'package:hentai_library/l10n/app_localizations.dart';

import '../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('language selection replaces unknown values and can be cleared', (
    WidgetTester tester,
  ) async {
    configureTestView(tester, const Size(1200, 1000));
    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      home: Scaffold(
        body: ComicMetadataEditFormLayout(
          comic: Comic.restore(
            comicId: 'language',
            path: '/language.cbz',
            resourceType: ResourceType.cbz,
            resourceSize: 1,
            createdAt: DateTime.utc(2026),
            lastUpdatedAt: DateTime.utc(2026),
            title: 'Language',
            pageCount: 1,
            languages: <String>['Esperanto'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ComicMetadataEditForm)),
    );
    expect(find.text('Esperanto'), findsOneWidget);
    await tester.ensureVisible(find.text(l10n.comicLanguageJapanese));
    await tester.tap(find.text(l10n.comicLanguageJapanese));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ComicMetadataEditForm>(find.byType(ComicMetadataEditForm))
          .draft
          .languages,
      <String>['Japanese'],
    );
    expect(find.text('Esperanto'), findsNothing);
    await tester.tap(find.text(l10n.comicLanguageChinese).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ComicMetadataEditForm>(find.byType(ComicMetadataEditForm))
          .draft
          .languages,
      <String>['Chinese'],
    );
    await tester.tap(find.text(l10n.comicLanguageChinese).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ComicMetadataEditForm>(find.byType(ComicMetadataEditForm))
          .draft
          .languages,
      isEmpty,
    );
  });

  testWidgets('comic metadata edit view shows comic title field', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime now = DateTime.utc(2026, 1, 1);
    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      home: Scaffold(
        body: ComicMetadataEditFormLayout(
          comic: Comic.restore(
            comicId: 'c1',
            path: '/tmp/c1.cbz',
            resourceType: ResourceType.cbz,
            resourceSize: 1,
            createdAt: now,
            lastUpdatedAt: now,
            title: 'Title',
            pageCount: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
  });
}
