import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_metadata_edit_page_lab_host.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('LabHost 字段锁 KV 可切换标题锁', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 720));
    await pumpMd3eApp(
      tester,
      home: const Scaffold(
        body: SizedBox(
          width: 900,
          height: 720,
          child: Md3eComicMetadataEditPageLabHost(
            initialLocks: ComicMetaLocks.unlocked,
          ),
        ),
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(Md3eComicMetadataEditPageLabHost)),
    );

    await tester.tap(find.text(l10n.dialogEditMetadataTabFieldLocks));
    await tester.pumpAndSettle();

    final Finder titleRow = find.ancestor(
      of: find.text(l10n.formComicTitleLabel),
      matching: find.byType(Md3eSettingsTileShell),
    );

    expect(find.byIcon(Symbols.lock_open_right), findsWidgets);
    expect(find.byIcon(Symbols.lock), findsNothing);

    await tester.tap(titleRow);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.lock), findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });
}
