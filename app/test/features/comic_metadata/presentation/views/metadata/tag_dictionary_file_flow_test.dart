import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/tag_dictionary_file_provider.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/tag_dictionary_import_view_model.dart';
import 'package:hentai_library/features/comic_metadata/presentation/views/metadata/metadata_actions.dart';
import 'package:hentai_library/l10n/app_localizations_zh.dart';

import '../../../../../support/pump_app.dart';

void main() {
  for (final valid in [false, true]) {
    testWidgets(
      'local dictionary selection uses injected reader, valid: $valid',
      (tester) async {
        const picker = MethodChannel('miguelruivo.flutter.plugins.filepicker');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          picker,
          (_) async => [
            {'name': 'tags.json', 'path': '/isolated/tags.json', 'size': 3},
          ],
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            picker,
            null,
          ),
        );
        final importer = _Importer();
        final paths = <String?>[];
        await pumpApp(
          tester,
          overrides: [
            readTagDictionaryFileProvider.overrideWithValue(({
              Uint8List? bytes,
              String? path,
            }) async {
              paths.add(path);
              expect(bytes, isNull);
              return valid ? Uint8List.fromList([1, 2, 3]) : null;
            }),
            tagDictionaryImportViewModelProvider.overrideWith(() => importer),
          ],
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FilledButton(
                onPressed: () => importTagDictionaryFromFile(context, ref),
                child: const Text('import'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('import'));
        await tester.pumpAndSettle();
        expect(paths, ['/isolated/tags.json']);
        expect(importer.imported, valid ? [1, 2, 3] : isNull);
        if (!valid) {
          expect(
            find.text(
              AppLocalizationsZh().metadataImportTagDictionaryInvalidFile,
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Importer extends TagDictionaryImportViewModel {
  // Test fixture exposes observations/configuration, not reactive application state.
  // ignore: riverpod_lint/avoid_public_notifier_properties
  Uint8List? imported;
  @override
  Future<TagDictionaryImportResult?> importFromBytes(Uint8List bytes) async {
    imported = bytes;
    return const TagDictionaryImportResult(
      added: 1,
      skippedExisting: 0,
      skippedFilteredOrEmptyOrDedupe: 0,
    );
  }
}
