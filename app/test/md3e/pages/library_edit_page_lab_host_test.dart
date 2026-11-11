import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_edit_page.dart';

import '../../../widgetbook/hosts/md3e_library_edit_page_lab_host.dart';

import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('LabHost 远程 WebDAV 凭证编辑后保存 preview 表单', (
    WidgetTester tester,
  ) async {
    LibraryForm? saved;

    await tester.binding.setSurfaceSize(const Size(900, 720));
    await pumpApp(
      tester,
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 720,
          child: LibraryEditPageLabHost(
            intent: LibraryEditPageIntent.editRemote,
            onSaved: (LibraryForm form) => saved = form,
          ),
        ),
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(LibraryEditPageLabHost)),
    );

    await tester.tap(find.text(l10n.dialogEditLibraryTabWebDav));
    await tester.pumpAndSettle();

    const String nextUsername = 'lab-preview-user';
    await tester.enterText(find.text('reader'), nextUsername);

    await tester.tap(find.text(l10n.commonSave));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(saved, isNotNull);
    expect(saved!.username, nextUsername);
    expect(saved!.rootPath, contains('nas.example'));

    await tester.binding.setSurfaceSize(null);
  });
}
