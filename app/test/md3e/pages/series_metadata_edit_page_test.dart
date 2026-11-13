import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/l10n/app_localizations.dart';

import '../../../widgetbook/preview/md3e_series_detail_page_preview_data.dart';

import 'package:hentai_library/features/series/presentation/views/metadata_edit/series_metadata_edit_page.dart';

import '../../support/pump_localized_app.dart';

void main() {
  testWidgets('shows edit series title', (WidgetTester tester) async {
    await _pumpEditor(
      tester,
      size: const Size(520, 640),
      draft: SeriesMetadataEditDraft.fromEntry(
        SeriesDetailPagePreviewData.sample(),
      ),
    );
    expect(find.text('编辑系列'), findsOneWidget);
  });

  testWidgets(
    'zero cannot save and correcting the count clears the domain error',
    (tester) async {
      final saved = <SeriesMetadataEditDraft>[];
      final l10n = await _pumpEditor(tester, onSaved: saved.add);
      await tester.enterText(_field(l10n.formSeriesTotalCountLabel), '0');
      await _save(tester, l10n);
      expect(saved, isEmpty);
      expect(find.text(_totalError), findsOneWidget);

      await tester.enterText(_field(l10n.formSeriesTotalCountLabel), '12');
      await tester.pumpAndSettle();
      expect(find.text(_totalError), findsNothing);
      await _save(tester, l10n);
      expect(saved, hasLength(1));
      expect(saved.single.name, '系列甲');
      expect(saved.single.totalCountText, '12');
    },
  );

  testWidgets('clearing the total count can save an unset value', (
    tester,
  ) async {
    final saved = <SeriesMetadataEditDraft>[];
    final l10n = await _pumpEditor(tester, onSaved: saved.add);
    await tester.enterText(_field(l10n.formSeriesTotalCountLabel), '');
    await _save(tester, l10n);
    expect(saved, hasLength(1));
    expect(saved.single.totalCountText, isEmpty);
    expect(find.text(_totalError), findsNothing);
  });

  testWidgets('empty name and invalid count show both errors without saving', (
    tester,
  ) async {
    final saved = <SeriesMetadataEditDraft>[];
    final l10n = await _pumpEditor(tester, onSaved: saved.add);
    await tester.enterText(_field(l10n.formSeriesNameLabel), '   ');
    await tester.pumpAndSettle();
    await tester.enterText(_field(l10n.formSeriesTotalCountLabel), '-1');
    await tester.pumpAndSettle();
    await _save(tester, l10n);
    expect(saved, isEmpty);
    expect(find.text('系列名称不能为空'), findsOneWidget);
    expect(find.text(_totalError), findsOneWidget);
  });
}

const _totalError = '漫画总数须为正整数，留空表示不设置';

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(OutlinedTextField, label),
  matching: find.byType(EditableText),
);

Future<AppLocalizations> _pumpEditor(
  WidgetTester tester, {
  Size size = const Size(900, 800),
  SeriesMetadataEditDraft draft = const SeriesMetadataEditDraft(
    name: '系列甲',
    totalCountText: '5',
  ),
  ValueChanged<SeriesMetadataEditDraft>? onSaved,
}) async {
  configureTestView(tester, size);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpLocalizedApp(
    tester,
    home: Scaffold(
      body: SeriesMetadataEditLayout(initialDraft: draft, onSaved: onSaved),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold)));
}

Future<void> _save(WidgetTester tester, AppLocalizations l10n) async {
  final action = find.text(l10n.commonSave);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pump();
  await tester.pump(LabMotion.labSimulatedSaveDuration);
  await tester.pumpAndSettle();
}
