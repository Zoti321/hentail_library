import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/library/format_group.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';
import 'package:hentai_library/features/library_admin/di/shared_state_ports.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/library_form_dialog.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

class _RecordingCurrentLibraryNotifier extends CurrentLibraryNotifier {
  final List<({LibraryForm form, LocalLibrary? original})> submitCalls =
      <({LibraryForm form, LocalLibrary? original})>[];

  @override
  Future<CurrentLibraryState> build() async {
    return const CurrentLibraryState(
      libraries: <LocalLibrary>[],
      currentId: null,
    );
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

LocalLibrary _remoteLibrary() {
  return (
    libraryId: 'remote-1',
    kind: 'remote',
    rootPath: 'https://example.com/dav',
    name: '远程库',
    enabledFormatGroups: FormatGroup.all
        .where((FormatGroup g) => g != FormatGroup.folder)
        .toList(growable: false),
    username: 'user',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: false,
    sidebarOrder: 0,
  );
}

LocalLibrary _localLibrary() {
  return (
    libraryId: 'local-1',
    kind: 'local',
    rootPath: '/data/comics',
    name: '本地库',
    enabledFormatGroups: List<FormatGroup>.from(FormatGroup.all),
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: false,
    sidebarOrder: 0,
  );
}

Future<void> _pumpLibraryForm(
  WidgetTester tester, {
  required LibraryFormMode mode,
  LocalLibrary? library,
  required _RecordingCurrentLibraryNotifier notifier,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpLocalizedApp(
    tester,
    overrides: <Override>[
      currentLibraryProvider.overrideWith(() => notifier),
      currentLibraryPortProvider.overrideWith(createCurrentLibraryPort),
    ],
    home: Scaffold(
      body: LibraryFormDialog(mode: mode, library: library),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _tapPrimaryAction(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Finder _fieldTextInput(String key) {
  return find.descendant(
    of: find.byKey(ValueKey<String>(key)),
    matching: find.byType(TextField),
  );
}

void main() {
  testWidgets('empty local create shows field errors on general tab', (
    WidgetTester tester,
  ) async {
    final _RecordingCurrentLibraryNotifier notifier =
        _RecordingCurrentLibraryNotifier();
    await _pumpLibraryForm(
      tester,
      mode: LibraryFormMode.createLocal,
      notifier: notifier,
    );

    await _tapPrimaryAction(tester, '添加');

    expect(find.text('库名称不能为空'), findsOneWidget);
    expect(find.text('Library root 不能为空'), findsOneWidget);
    expect(notifier.submitCalls, isEmpty);
    expect(find.text('添加本地库'), findsOneWidget);
  });

  testWidgets('remote create without password switches to WebDAV tab', (
    WidgetTester tester,
  ) async {
    final _RecordingCurrentLibraryNotifier notifier =
        _RecordingCurrentLibraryNotifier();
    await _pumpLibraryForm(
      tester,
      mode: LibraryFormMode.createRemote,
      notifier: notifier,
    );

    await tester.enterText(_fieldTextInput('library-name-0'), '远程 A');
    await tester.tap(find.text('WebDAV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(
      _fieldTextInput('webdav-root-0'),
      'https://example.com/dav',
    );
    await _tapPrimaryAction(tester, '添加');

    expect(find.text('密码不能为空'), findsOneWidget);
    expect(find.text('WebDAV'), findsWidgets);
    expect(notifier.submitCalls, isEmpty);
  });

  testWidgets('remote edit shows keep-password hint on WebDAV tab', (
    WidgetTester tester,
  ) async {
    final _RecordingCurrentLibraryNotifier notifier =
        _RecordingCurrentLibraryNotifier();
    await _pumpLibraryForm(
      tester,
      mode: LibraryFormMode.edit,
      library: _remoteLibrary(),
      notifier: notifier,
    );

    await tester.tap(find.text('WebDAV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('密码（留空则不修改）'), findsOneWidget);
    expect(find.text('留空表示保持原密码'), findsOneWidget);
  });

  testWidgets(
    'disabling all format groups shows confirm; cancel skips submit',
    (WidgetTester tester) async {
      final _RecordingCurrentLibraryNotifier notifier =
          _RecordingCurrentLibraryNotifier();
      await _pumpLibraryForm(
        tester,
        mode: LibraryFormMode.edit,
        library: _localLibrary(),
        notifier: notifier,
      );

      await tester.tap(find.text('扫描'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      for (final FormatGroup group in FormatGroup.all) {
        final Finder tile = find.widgetWithText(
          CheckboxListTile,
          _formatLabel(group),
        );
        if (tile.evaluate().isNotEmpty) {
          final CheckboxListTile checkbox = tester.widget<CheckboxListTile>(
            tile,
          );
          if (checkbox.value == true) {
            await tester.tap(tile);
            await tester.pump();
          }
        }
      }

      await _tapPrimaryAction(tester, '保存更改');

      expect(find.text('关闭全部格式？'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '取消').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(notifier.submitCalls, isEmpty);
      expect(find.text('编辑库'), findsOneWidget);
    },
  );

  testWidgets('confirming disable-all proceeds to submitLibraryForm', (
    WidgetTester tester,
  ) async {
    final _RecordingCurrentLibraryNotifier notifier =
        _RecordingCurrentLibraryNotifier();
    await _pumpLibraryForm(
      tester,
      mode: LibraryFormMode.edit,
      library: _localLibrary(),
      notifier: notifier,
    );

    await tester.tap(find.text('扫描'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    for (final FormatGroup group in FormatGroup.all) {
      final Finder tile = find.widgetWithText(
        CheckboxListTile,
        _formatLabel(group),
      );
      if (tile.evaluate().isNotEmpty) {
        final CheckboxListTile checkbox = tester.widget<CheckboxListTile>(tile);
        if (checkbox.value == true) {
          await tester.tap(tile);
          await tester.pump();
        }
      }
    }

    await _tapPrimaryAction(tester, '保存更改');
    expect(find.text('关闭全部格式？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '保存').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(notifier.submitCalls, hasLength(1));
    expect(notifier.submitCalls.single.form.enabledFormatGroups, isEmpty);
    expect(find.byType(LibraryFormDialog), findsNothing);
  });

  testWidgets('valid remote create calls submitLibraryForm', (
    WidgetTester tester,
  ) async {
    final _RecordingCurrentLibraryNotifier notifier =
        _RecordingCurrentLibraryNotifier();
    await _pumpLibraryForm(
      tester,
      mode: LibraryFormMode.createRemote,
      notifier: notifier,
    );

    await tester.enterText(_fieldTextInput('library-name-0'), '远程库 B');
    await tester.pump();
    await tester.tap(find.text('WebDAV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(
      _fieldTextInput('webdav-root-0'),
      'https://example.com/dav',
    );
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(LibraryFormDialog),
        matching: find.byWidgetPredicate(
          (Widget widget) => widget is TextField && widget.obscureText,
        ),
      ),
      'secret',
    );
    await tester.pump();
    await _tapPrimaryAction(tester, '添加');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(notifier.submitCalls, hasLength(1));
    expect(notifier.submitCalls.single.form.name, '远程库 B');
    expect(notifier.submitCalls.single.form.password, 'secret');
    expect(find.byType(LibraryFormDialog), findsNothing);
  });
}

String _formatLabel(FormatGroup group) {
  return switch (group) {
    FormatGroup.folder => '漫画文件夹',
    FormatGroup.pdf => 'PDF',
    FormatGroup.epub => 'EPUB',
    FormatGroup.archive => '漫画压缩包',
  };
}
