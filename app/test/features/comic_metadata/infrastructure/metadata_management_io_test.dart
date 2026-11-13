import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/metadata_management_preferences.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/services/tag_dictionary/read_tag_dictionary_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('merge confirmation retains its existing key and default', () async {
    SharedPreferences.setMockInitialValues({'unrelated': true});
    expect(await loadMergeConfirmationSkipped(), isFalse);
    await saveMergeConfirmationSkipped(true);
    expect(await loadMergeConfirmationSkipped(), isTrue);
    await saveMergeConfirmationSkipped(false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('metadata_merge_confirm_skip'), isFalse);
    expect(prefs.getBool('unrelated'), isTrue);
  });

  test(
    'selected bytes are copied and take precedence over a file path',
    () async {
      final selected = Uint8List.fromList([1, 2, 3]);
      final loaded = await readTagDictionaryFile(
        bytes: selected,
        path: 'missing.json',
      );
      selected[0] = 9;
      expect(loaded, [1, 2, 3]);
      expect(await readTagDictionaryFile(), isNull);
      expect(
        await readTagDictionaryFile(bytes: Uint8List(0), path: ''),
        isNull,
      );
    },
  );

  test('empty selected bytes fall back to the file and unreadable paths return null', () async {
    final directory = await Directory.systemTemp.createTemp(
      'tag_dictionary_reader_',
    );
    final file = File.fromUri(directory.uri.resolve('dictionary.json'));
    try {
      await file.writeAsBytes([1, 2, 3]);
      expect(
        await readTagDictionaryFile(bytes: Uint8List(0), path: file.path),
        [1, 2, 3],
      );
      await file.writeAsBytes([]);
      expect(await readTagDictionaryFile(path: file.path), isEmpty);
      expect(
        await readTagDictionaryFile(
          path: File.fromUri(directory.uri.resolve('missing.json')).path,
        ),
        isNull,
      );
    } finally {
      if (await file.exists()) await file.delete();
      await directory.delete();
    }
  });
}
