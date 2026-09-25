import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/metadata/metadata_backup_bytes.dart';
import 'package:hentai_library/core/metadata/metadata_import_flow.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';

import '../../support/pump_localized_app.dart';

void main() {
  const MetadataBackupManifestDto manifest = MetadataBackupManifestDto(
    schemaVersion: 1,
    exportedAt: '2026-01-01T00:00:00.000Z',
    appVersion: '0.1.0',
    comicCount: 2,
    includeOrphanFacets: false,
  );

  testWidgets('confirm dialog cancels without calling import', (
    WidgetTester tester,
  ) async {
    var importCalls = 0;

    await pumpLocalizedApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return FilledButton(
            onPressed: () async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) =>
                    const MetadataImportConfirmDialog(manifest: manifest),
              );
              if (confirmed == true) {
                importCalls += 1;
              }
            },
            child: const Text('open'),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('导入元数据备份？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(importCalls, 0);
  });

  testWidgets('confirm dialog proceeds to mocked import summary', (
    WidgetTester tester,
  ) async {
    var importCalls = 0;

    await pumpLocalizedApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return FilledButton(
            onPressed: () async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) =>
                    const MetadataImportConfirmDialog(manifest: manifest),
              );
              if (confirmed != true || !context.mounted) {
                return;
              }
              importCalls += 1;
              await showDialog<void>(
                context: context,
                builder: (BuildContext context) => MetadataImportResultDialog(
                  result: const ImportComicMetadataResultDto(
                    applied: 1,
                    skippedNotFound: 0,
                    skippedAmbiguous: 0,
                    errors: <String>[],
                  ),
                ),
              );
            },
            child: const Text('open'),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入'));
    await tester.pumpAndSettle();

    expect(importCalls, 1);
    expect(find.text('导入完成'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('已恢复: 1'),
      ),
      findsOneWidget,
    );
  });

  test('decodeMetadataBackupFileBytes accepts gzip payloads', () {
    final List<int> gz = GZipCodec().encode(<int>[123, 125]);
    final Uint8List decoded = decodeMetadataBackupFileBytes(
      gz,
      'backup.hlmeta.json.gz',
    );
    expect(decoded, equals(Uint8List.fromList(<int>[123, 125])));
  });
}
