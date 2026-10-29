import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_settings_page_lab_host.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_metadata_backup_import_lab_flow.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_md3e_app.dart';

void main() {
  Future<AppLocalizations> pumpMetadataBackupPane(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpMd3eApp(
      tester,
      home: const Md3eSettingsPageLabHost(
        initialCategory: Md3eSettingsCategory.metadataBackup,
      ),
    );
    return AppLocalizations.of(
      tester.element(find.byType(Md3eSettingsPageLabHost)),
    );
  }

  Finder inDialog(Finder matching) {
    return find.descendant(of: find.byType(M3EDialog), matching: matching);
  }

  testWidgets('导入元数据 tile 走完 选择 → 确认 → 结果', (WidgetTester tester) async {
    final AppLocalizations l10n = await pumpMetadataBackupPane(tester);

    await tester.tap(find.text(l10n.settingsMetadataBackupImportLabel));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.settingsMetadataBackupImportPickDialogTitle),
      findsOneWidget,
    );

    await tester.tap(inDialog(find.text(l10n.commonConfirm)));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.settingsMetadataBackupImportConfirmTitle),
      findsOneWidget,
    );

    final String confirmLabel = l10n
        .settingsMetadataBackupImportConfirmActionWithCount(
          kMd3eMetadataBackupImportLabPreview.wouldApply,
        );
    await tester.tap(inDialog(find.text(confirmLabel)));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.settingsMetadataBackupImportResultTitle),
      findsOneWidget,
    );

    await tester.tap(inDialog(find.text(l10n.commonClose)));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.settingsMetadataBackupImportResultTitle),
      findsNothing,
    );
  });

  testWidgets('选择阶段取消则不进入确认', (WidgetTester tester) async {
    final AppLocalizations l10n = await pumpMetadataBackupPane(tester);

    await tester.tap(find.text(l10n.settingsMetadataBackupImportLabel));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text(l10n.commonCancel)));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.settingsMetadataBackupImportConfirmTitle),
      findsNothing,
    );
    expect(find.byType(M3EDialog), findsNothing);
  });
}
