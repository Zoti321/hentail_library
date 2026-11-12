import 'package:flutter/services.dart';
import 'package:hentai_library/features/metadata_backup/application/prepare_metadata_import_use_case.dart';
import 'package:hentai_library/features/metadata_backup/di/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/metadata_backup/data/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_bytes.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_match_tier.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:hentai_library/features/metadata_backup/presentation/metadata_import_flow.dart';

import '../../../support/pump_localized_app.dart';

void main() {
  const MetadataBackupManifest manifest = MetadataBackupManifest(
    schemaVersion: 1,
    exportedAt: '2026-01-01T00:00:00.000Z',
    appVersion: '0.1.0',
    comicCount: 2,
    includeOrphanFacets: false,
  );

  const MetadataImportPreview previewWithMatches = MetadataImportPreview(
    wouldApply: 2,
    skippedNotFound: 0,
    skippedAmbiguous: 0,
    wouldUpsertOrphanFacetCount: 3,
    samplesWouldApply: <MetadataImportWouldApplySample>[
      MetadataImportWouldApplySample(
        comicId: 'backup-1',
        path: 'E:/very/long/library/root/folder/subfolder/comic.cbz',
        title: 'Sample Comic',
        matchedComicId: 'c1',
        matchTier: MetadataImportMatchTier.path,
      ),
    ],
    samplesNotFound: <MetadataImportNotFoundSample>[],
    samplesAmbiguous: <MetadataImportAmbiguousSample>[],
  );

  const MetadataImportPreview previewWithSkips = MetadataImportPreview(
    wouldApply: 0,
    skippedNotFound: 1,
    skippedAmbiguous: 1,
    wouldUpsertOrphanFacetCount: 5,
    samplesWouldApply: <MetadataImportWouldApplySample>[],
    samplesNotFound: <MetadataImportNotFoundSample>[
      MetadataImportNotFoundSample(
        comicId: 'missing',
        path: 'E:/lib/gone.cbz',
        title: 'Missing Comic',
      ),
    ],
    samplesAmbiguous: <MetadataImportAmbiguousSample>[
      MetadataImportAmbiguousSample(
        comicId: 'dup',
        path: 'E:/lib/dup.cbz',
        title: 'Dup Comic',
        candidateComicIds: <String>['c2', 'c3'],
      ),
    ],
  );

  for (final confirm in [false, true]) {
    testWidgets(
      'actual import flow commits only after confirmation: $confirm',
      (tester) async {
        final repo = _FlowRepository(
          manifest,
          const MetadataImportPreview(
            wouldApply: 2,
            skippedNotFound: 0,
            skippedAmbiguous: 0,
            wouldUpsertOrphanFacetCount: 0,
            samplesWouldApply: [],
            samplesNotFound: [],
            samplesAmbiguous: [],
          ),
        );
        const picker = MethodChannel('miguelruivo.flutter.plugins.filepicker');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          picker,
          (_) async => [
            {
              'name': 'backup.hlmeta.json',
              'path': '/isolated/backup.hlmeta.json',
              'size': 1,
              'bytes': Uint8List.fromList([9]),
            },
          ],
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            picker,
            null,
          ),
        );
        await pumpLocalizedApp(
          tester,
          wrapProviderScope: true,
          overrides: [
            prepareMetadataImportUseCaseProvider.overrideWithValue(
              PrepareMetadataImportUseCase(
                repo,
                const LocalMetadataBackupFileGateway(),
              ),
            ),
          ],
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => runMetadataImportFlow(context),
              child: const Text('start-import'),
            ),
          ),
        );
        await tester.tap(find.text('start-import'));
        await tester.pumpAndSettle();
        expect(find.byType(MetadataImportConfirmDialog), findsOneWidget);
        expect(repo.imports, 0);
        await tester.tap(find.text(confirm ? '导入 2' : '取消').last);
        await tester.pumpAndSettle();
        expect(repo.imports, confirm ? 1 : 0);
        if (confirm) expect(repo.importedBytes, [9]);
        expect(tester.takeException(), isNull);
      },
    );
  }

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
                builder: (BuildContext context) =>
                    const MetadataImportResultDialog(
                      result: MetadataImportResult(
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
    await tester.tap(find.text('无法导入'));
    await tester.pumpAndSettle();
    expect(find.text('无法导入'), findsOneWidget);
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

  test('decodeMetadataBackupFileBytes accepts gzip payloads', () async {
    final List<int> gz = GZipCodec().encode(<int>[123, 125]);
    final Uint8List decoded = await decodeMetadataBackupFileBytes(
      gz,
      'backup.hlmeta.json.gz',
    );
    expect(decoded, equals(Uint8List.fromList(<int>[123, 125])));
  });
}

class _FlowRepository implements MetadataBackupRepository {
  _FlowRepository(this.manifest, this.preview);
  final MetadataBackupManifest manifest;
  final MetadataImportPreview preview;
  var imports = 0;
  Uint8List? importedBytes;
  @override
  MetadataBackupManifest peekManifest(Uint8List bytes) => manifest;
  @override
  MetadataImportPreview previewImport(Uint8List bytes) => preview;
  @override
  MetadataImportResult importMetadata(Uint8List bytes) {
    imports++;
    importedBytes = bytes;
    return const MetadataImportResult(
      applied: 1,
      skippedNotFound: 0,
      skippedAmbiguous: 0,
      errors: [],
    );
  }

  @override
  Uint8List exportComicMetadata({
    String? libraryId,
    required bool includeOrphanFacets,
  }) => throw UnimplementedError();
}
