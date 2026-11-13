import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_detail_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/views/bulk_edit/bulk_edit_metadata_form.dart';
import 'package:hentai_library/features/comic/presentation/views/bulk_edit/bulk_edit_metadata_presenter.dart';
import 'package:hentai_library/features/library_admin/public/contracts.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

Comic _comic(String id) {
  return Comic.restore(
    comicId: id,
    path: '/comics/$id',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: DateTime.utc(2024),
    lastUpdatedAt: DateTime.utc(2024),
    title: id,
    pageCount: 1,
  );
}

Future<void> _pumpForm(WidgetTester tester, List<String> ids) async {
  await pumpLocalizedApp(
    tester,
    overrides: _overrides(ids),
    home: Scaffold(
      body: SizedBox(
        height: 480,
        width: 800,
        child: BulkEditMetadataForm(comicIds: ids),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'missing and invalid replacements stay visible and block confirmation until corrected',
    (tester) async {
      final h = await _openEditor(tester);
      await _selectDateOp(tester, h.l10n, h.l10n.bulkEditMetadataOpClear);
      await _selectDateOp(tester, h.l10n, h.l10n.bulkEditMetadataOpReplace);
      await _save(tester, h.l10n);
      expect(find.text(h.l10n.formDateInvalidFormat), findsOneWidget);
      expect(find.text(h.l10n.bulkEditMetadataConfirmTitle), findsNothing);
      expect(h.results, isEmpty);

      await tester.enterText(_dateField(), 'not a date');
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(_dateField()).controller.text,
        'not a date',
      );
      await _save(tester, h.l10n);
      expect(find.text(h.l10n.formDateInvalidFormat), findsOneWidget);
      expect(find.text(h.l10n.bulkEditMetadataConfirmTitle), findsNothing);
      expect(h.results, isEmpty);

      await tester.enterText(_dateField(), '2026-01-02');
      await tester.pumpAndSettle();
      expect(find.text(h.l10n.formDateInvalidFormat), findsNothing);
      await _save(tester, h.l10n);
      expect(find.text(h.l10n.bulkEditMetadataConfirmTitle), findsOneWidget);
      await _save(tester, h.l10n);
      expect(h.results, hasLength(1));
      final published =
          h.results.single!.publishedAt as ComicMetadataBulkPublishedAtReplace;
      expect(published.value, DateTime(2026, 1, 2));
    },
  );

  testWidgets('explicit clear can confirm without a replacement date', (
    tester,
  ) async {
    final h = await _openEditor(tester);
    await _selectDateOp(tester, h.l10n, h.l10n.bulkEditMetadataOpClear);
    await _save(tester, h.l10n);
    expect(find.text(h.l10n.formDateInvalidFormat), findsNothing);
    expect(find.text(h.l10n.bulkEditMetadataConfirmTitle), findsOneWidget);
    await _save(tester, h.l10n);
    expect(h.results, hasLength(1));
    expect(
      h.results.single!.publishedAt,
      isA<ComicMetadataBulkPublishedAtClear>(),
    );
  });

  testWidgets('a deliberately entered UTC epoch is a valid replacement', (
    tester,
  ) async {
    final h = await _openEditor(tester);
    await tester.ensureVisible(_dateField());
    await tester.enterText(_dateField(), '1970-01-01T00:00:00Z');
    await tester.pumpAndSettle();
    await _save(tester, h.l10n);
    expect(find.text(h.l10n.bulkEditMetadataConfirmTitle), findsOneWidget);
    await _save(tester, h.l10n);
    expect(h.results, hasLength(1));
    final published =
        h.results.single!.publishedAt as ComicMetadataBulkPublishedAtReplace;
    expect(
      published.value,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    expect(published.value.isUtc, isTrue);
  });

  testWidgets('general tab shows description editor and no tag input', (
    WidgetTester tester,
  ) async {
    await _pumpForm(tester, const <String>['c1', 'c2']);

    expect(find.byType(SegmentedCapsuleBar), findsWidgets);
    expect(find.byType(OutlinedTextField), findsWidgets);
    expect(find.byType(TagInputField), findsOneWidget);
    expect(find.byType(MetadataFieldLabelRow), findsWidgets);
  });

  testWidgets('switching to authors and tags tab hides general editors', (
    WidgetTester tester,
  ) async {
    await _pumpForm(tester, const <String>['c1', 'c2']);

    await tester.tap(find.text('作者&标签'));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedTextField), findsNothing);
    expect(find.byType(TagInputField), findsWidgets);
  });
}

List<Override> _overrides(List<String> ids) => [
  bulkEditComicsByIdsProvider.overrideWith(
    (Ref ref, List<String> _) async => ids.map(_comic).toList(growable: false),
  ),
];

Finder _dateField() => find.descendant(
  of: find.byType(PublishedDateTextField),
  matching: find.byType(EditableText),
);

Future<void> _selectDateOp(
  WidgetTester tester,
  AppLocalizations l10n,
  String label,
) async {
  final dateOps = find
      .widgetWithText(SegmentedCapsuleBar, l10n.bulkEditMetadataOpClear)
      .last;
  final target = find.descendant(of: dateOps, matching: find.text(label));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, AppLocalizations l10n) async {
  final target = find.text(l10n.commonSaveChanges).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<({AppLocalizations l10n, List<ComicMetadataBulkPatch?> results})>
_openEditor(WidgetTester tester) async {
  configureTestView(tester, const Size(800, 1000));
  addTearDown(tester.view.resetDevicePixelRatio);
  final results = <ComicMetadataBulkPatch?>[];
  late AppLocalizations l10n;
  const ids = ['c1', 'c2'];
  await pumpLocalizedApp(
    tester,
    overrides: _overrides(ids),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return TextButton(
            onPressed: () async {
              results.add(
                await showBulkEditMetadata(context: context, comicIds: ids),
              );
            },
            child: const Text('open'),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return (l10n: l10n, results: results);
}
