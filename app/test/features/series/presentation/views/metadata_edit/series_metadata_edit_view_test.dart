import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/series/presentation/views/metadata_edit/series_metadata_edit_page.dart';
import 'package:hentai_library/features/series/presentation/view_models/series_metadata_editor_notifier.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/ui/catalog/metadata_edit/metadata_field_locks_kv_list.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/series_metadata_form.dart';
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

/// 在路由中打开整页（与生产 push 行为一致，保存后可 pop 回来）。
Future<void> _pumpEditSeriesPage(
  WidgetTester tester, {
  required _RecordingSeriesMetadataEditor editor,
  Series? series,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final Series target = series ?? _series();
  await pumpLocalizedApp(
    tester,
    overrides: <Override>[
      seriesMetadataEditorProvider.overrideWith(() => editor),
    ],
    home: Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                Scaffold(body: SeriesMetadataEditFormLayout(series: target)),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _nameField(WidgetTester tester) {
  return find
      .descendant(
        of: find.byType(SeriesMetadataEditFormLayout),
        matching: find.byType(EditableText),
      )
      .first;
}

void main() {
  testWidgets('empty name shows validation error on save', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesPage(tester, editor: editor);

    await tester.enterText(_nameField(tester), '   ');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('系列名称不能为空'), findsOneWidget);
    expect(editor.applyForms, isEmpty);
    expect(find.byType(SeriesMetadataEditFormLayout), findsOneWidget);
  });

  testWidgets('lock button forwards setLocks to editor notifier', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesPage(tester, editor: editor);

    await tester.tap(find.text('字段锁'));
    await tester.pump();
    await tester.tap(
      find
          .descendant(
            of: find.byType(MetadataFieldLocksKvList),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(editor.lockCalls, <({String seriesId, bool? name})>[
      (seriesId: 'series-1', name: true),
    ]);
  });

  testWidgets('unchanged save calls apply and leaves the page', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesPage(tester, editor: editor);

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(editor.applyForms, hasLength(1));
    expect(editor.applyForms.single.name, '系列甲');
    expect(find.byType(SeriesMetadataEditFormLayout), findsNothing);
  });

  testWidgets('changed name save calls apply with new name', (
    WidgetTester tester,
  ) async {
    final _RecordingSeriesMetadataEditor editor =
        _RecordingSeriesMetadataEditor();
    await _pumpEditSeriesPage(tester, editor: editor);

    await tester.enterText(_nameField(tester), '新名称');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(editor.applyForms.single.name, '新名称');
    expect(find.byType(SeriesMetadataEditFormLayout), findsNothing);
  });
}
