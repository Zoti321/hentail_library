import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page_lab_host.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('LabHost 远程 WebDAV 凭证编辑后保存 preview 表单', (
    WidgetTester tester,
  ) async {
    LibraryForm? saved;

    await tester.binding.setSurfaceSize(const Size(900, 720));
    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 720,
          child: Md3eLibraryEditPageLabHost(
            intent: Md3eLibraryEditPageIntent.editRemote,
            onSaved: (LibraryForm form) => saved = form,
          ),
        ),
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(Md3eLibraryEditPageLabHost)),
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
