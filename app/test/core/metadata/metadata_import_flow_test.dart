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

  const PreviewImportComicMetadataResultDto previewWithMatches =
      PreviewImportComicMetadataResultDto(
        wouldApply: 2,
        skippedNotFound: 0,
        skippedAmbiguous: 0,
        wouldUpsertOrphanFacetCount: 3,
        samplesWouldApply: <WouldApplySampleDto>[
          WouldApplySampleDto(
            comicId: 'backup-1',
            path: 'E:/very/long/library/root/folder/subfolder/comic.cbz',
            title: 'Sample Comic',
            matchedComicId: 'c1',
            matchTier: MatchTierDto.path,
          ),
        ],
        samplesNotFound: <NotFoundSampleDto>[],
        samplesAmbiguous: <AmbiguousSampleDto>[],
      );

  const PreviewImportComicMetadataResultDto previewWithSkips =
      PreviewImportComicMetadataResultDto(
        wouldApply: 0,
        skippedNotFound: 1,
        skippedAmbiguous: 1,
        wouldUpsertOrphanFacetCount: 5,
        samplesWouldApply: <WouldApplySampleDto>[],
        samplesNotFound: <NotFoundSampleDto>[
          NotFoundSampleDto(
            comicId: 'missing',
            path: 'E:/lib/gone.cbz',
            title: 'Missing Comic',
          ),
        ],
        samplesAmbiguous: <AmbiguousSampleDto>[
          AmbiguousSampleDto(
            comicId: 'dup',
            path: 'E:/lib/dup.cbz',
            title: 'Dup Comic',
            candidateComicIds: <String>['c2', 'c3'],
          ),
        ],
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
                    const MetadataImportConfirmDialog(
                      manifest: manifest,
                      preview: previewWithMatches,
                    ),
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

  testWidgets('confirm dialog shows preview summary and import count action', (
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
                    const MetadataImportConfirmDialog(
                      manifest: manifest,
                      preview: previewWithMatches,
                    ),
              );
              if (confirmed != true || !context.mounted) {
                return;
              }
              importCalls += 1;
              await showDialog<void>(
                context: context,
                builder: (BuildContext context) => MetadataImportResultDialog(
                  result: const ImportComicMetadataResultDto(
                    applied: 2,
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

    expect(find.text('匹配预演'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('将新增字典项: 3'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText && widget.text.toPlainText().contains('将恢复: 2'),
      ),
      findsOneWidget,
    );
    expect(find.text('导入 2'), findsOneWidget);

    await tester.tap(find.text('导入 2'));
    await tester.pumpAndSettle();

    expect(importCalls, 1);
    expect(find.text('导入完成'), findsOneWidget);
  });

  testWidgets('confirm dialog disables import when wouldApply is zero', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return FilledButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) =>
                    const MetadataImportConfirmDialog(
                      manifest: manifest,
                      preview: previewWithSkips,
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

    expect(find.text('无法导入'), findsOneWidget);
    final Finder button = find.widgetWithText(FilledButton, '无法导入');
    final FilledButton filledButton = tester.widget<FilledButton>(button);
    expect(filledButton.onPressed, isNull);
  });

  testWidgets('confirm dialog auto-expands details when skips present', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return FilledButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) =>
                    const MetadataImportConfirmDialog(
                      manifest: manifest,
                      preview: previewWithSkips,
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

    expect(find.text('Missing Comic'), findsOneWidget);
    expect(find.text('Dup Comic'), findsOneWidget);
  });

  test('ellipsisMiddlePath shortens long paths in the middle', () {
    const String path =
        'E:/very/long/library/root/folder/subfolder/deep/nested/comic.cbz';
    final String shortened = ellipsisMiddlePath(path, maxLength: 40);
    expect(shortened.length, lessThanOrEqualTo(40));
    expect(shortened, startsWith('E:/very'));
    expect(shortened, endsWith('comic.cbz'));
    expect(shortened, contains('…'));
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
