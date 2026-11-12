import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/di/library_commands.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/libraries_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_confirm_dialog.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_form_dialog.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

class _RecordingLibrariesNotifier extends LibrariesNotifier {
  final List<({LibraryForm form, LocalLibrary? original})> submitCalls =
      <({LibraryForm form, LocalLibrary? original})>[];

  @override
  Future<LibrariesState> build() async {
    return const LibrariesState(libraries: <LocalLibrary>[]);
  }

  @override
  Future<LibraryFormApplyResult> submitLibraryForm(
    LibraryForm form, {
    LocalLibrary? original,
  }) async {
    submitCalls.add((form: form, original: original));
    return const LibraryFormApplySucceeded();
  }
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required LibraryFormMode mode,
  LocalLibrary? library,
  required _RecordingLibrariesNotifier notifier,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpLocalizedApp(
    tester,
    overrides: <Override>[
      librariesProvider.overrideWith(() => notifier),
      submitLibraryFormCommandProvider.overrideWith(
        createSubmitLibraryFormCommand,
      ),
    ],
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showLibraryFormDialog(
              context: context,
              mode: mode,
              library: library,
            ),
            child: const Text('OPEN'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _primaryButton(String label) {
  return find.text(label).last;
}

Finder _webDavUrlField() {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is EditableText && widget.keyboardType == TextInputType.url,
  );
}

Future<void> _tapPrimary(WidgetTester tester, String label) async {
  await tester.tap(_primaryButton(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('empty local create shows field errors and does not submit', (
    WidgetTester tester,
  ) async {
    final _RecordingLibrariesNotifier notifier = _RecordingLibrariesNotifier();
    await _pumpForm(
      tester,
      mode: LibraryFormMode.createLocal,
      notifier: notifier,
    );

    await _tapPrimary(tester, '添加');

    expect(find.text('库名称不能为空'), findsOneWidget);
    expect(find.text('Library root 不能为空'), findsOneWidget);
    expect(notifier.submitCalls, isEmpty);
    expect(find.byType(M3EDialog), findsOneWidget);
  });

  testWidgets('remote create without password switches to WebDAV tab', (
    WidgetTester tester,
  ) async {
    final _RecordingLibrariesNotifier notifier = _RecordingLibrariesNotifier();
    await _pumpForm(
      tester,
      mode: LibraryFormMode.createRemote,
      notifier: notifier,
    );

    await tester.enterText(find.byType(EditableText).first, '远程 A');
    await tester.tap(find.text('WebDAV').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(_webDavUrlField(), 'https://example.com/dav');
    await _tapPrimary(tester, '添加');

    expect(find.text('密码不能为空'), findsOneWidget);
    expect(notifier.submitCalls, isEmpty);
  });

  testWidgets('valid remote create calls submitLibraryForm and closes', (
    WidgetTester tester,
  ) async {
    final _RecordingLibrariesNotifier notifier = _RecordingLibrariesNotifier();
    await _pumpForm(
      tester,
      mode: LibraryFormMode.createRemote,
      notifier: notifier,
    );

    await tester.enterText(find.byType(EditableText).first, '远程库 B');
    await tester.pump();
    await tester.tap(find.text('WebDAV').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(_webDavUrlField(), 'https://example.com/dav');
    await tester.pump();
    await tester.enterText(
      find.byWidgetPredicate(
        (Widget widget) => widget is EditableText && widget.obscureText,
      ),
      'secret',
    );
    await tester.pump();
    await _tapPrimary(tester, '添加');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('库名称不能为空'), findsNothing);
    expect(find.text('WebDAV 根 URL 不能为空'), findsNothing);
    expect(find.text('密码不能为空'), findsNothing);
    expect(notifier.submitCalls, hasLength(1));
    expect(notifier.submitCalls.single.form.name, '远程库 B');
    expect(notifier.submitCalls.single.form.password, 'secret');
    expect(find.byType(M3EDialog), findsNothing);
  });

  testWidgets('confirm helper returns false on cancel and true on confirm', (
    WidgetTester tester,
  ) async {
    bool? result;
    await pumpLocalizedApp(
      tester,
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                result = await showLibraryConfirmDialog(
                  context,
                  title: '确认标题',
                  content: const Text('确认内容'),
                  confirmLabel: '好的',
                  destructive: true,
                );
              },
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(_primaryButton('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(result, isFalse);

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(_primaryButton('好的'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(result, isTrue);
  });
}
