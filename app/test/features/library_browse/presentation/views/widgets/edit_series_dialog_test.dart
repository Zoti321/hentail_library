import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/series_metadata_editor_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/edit_series_dialog.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

class _RecordingSeriesMetadataEditor extends SeriesMetadataEditorNotifier {
  final List<({String seriesId, bool? name})> lockCalls =
      <({String seriesId, bool? name})>[];
  final List<SeriesMetadataForm> applyForms = <SeriesMetadataForm>[];

  @override
  void build() {}

  @override
  Future<void> setLocks(
    String seriesId, {
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) async {
    lockCalls.add((seriesId: seriesId, name: name));
  }

  @override
  Future<SeriesMetadataApplyResult> apply(
    SeriesMetadataForm form,
    Series original,
  ) async {
    final SeriesMetadataFormValidation validation = form.validate();
    if (!validation.isValid) {
      return SeriesMetadataApplyInvalid(validation);
    }
    applyForms.add(form);
    return const SeriesMetadataApplySucceeded();
  }
}

Series _series() {
  return Series(id: 'series-1', name: '系列甲', folderPath: '/library/series-1');
}

Future<void> _pumpEditSeriesDialog(
  WidgetTester tester, {
  required _RecordingSeriesMetadataEditor editor,
  Series? series,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpLocalizedApp(
    tester,
    overrides: <Override>[
      seriesMetadataEditorProvider.overrideWith(() => editor),
    ],
    home: Scaffold(body: EditSeriesDialog(series: series ?? _series())),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Finder _nameField(WidgetTester tester) {
  return find
      .descendant(
        of: find.byType(EditSeriesDialog),
        matching: find.byType(TextField),
      )
      .first;
}

void main() {
  testWidgets('empty name shows validation error on save', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesDialog(tester, editor: editor);

    await tester.enterText(_nameField(tester), '   ');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('系列名称不能为空'), findsOneWidget);
    expect(editor.applyForms, isEmpty);
    expect(find.byType(EditSeriesDialog), findsOneWidget);
  });

  testWidgets('lock button forwards setLocks to editor notifier', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesDialog(tester, editor: editor);

    await tester.tap(
      find
          .descendant(
            of: find.byType(EditSeriesDialog),
            matching: find.byType(IconButton),
          )
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(editor.lockCalls, <({String seriesId, bool? name})>[
      (seriesId: 'series-1', name: true),
    ]);
  });

  testWidgets('unchanged save calls apply and closes dialog', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesDialog(tester, editor: editor);

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(editor.applyForms, hasLength(1));
    expect(editor.applyForms.single.name, '系列甲');
    expect(find.byType(EditSeriesDialog), findsNothing);
  });

  testWidgets('changed name save calls apply with new name', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesDialog(tester, editor: editor);

    await tester.enterText(_nameField(tester), '新名称');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(editor.applyForms.single.name, '新名称');
    expect(find.byType(EditSeriesDialog), findsNothing);
  });
}
