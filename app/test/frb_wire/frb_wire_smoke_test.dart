import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/src/rust/api/author.dart';
import 'package:hentai_library/src/rust/api/comic.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';
import 'package:hentai_library/src/rust/api/reader.dart';
import 'package:hentai_library/src/rust/api/reading_activity.dart';
import 'package:path/path.dart' as p;

import 'frb_wire_harness.dart';

/// FRB 线缝冒烟：只验证 Dart ↔ Rust 调用链可通（初始化、sync / async、错误 DTO），
/// 业务行为以 `cargo test` 为准（ADR-0018）。
void main() {
  setUpAll(initRustLibForWireTest);

  test('sync call returns comic ids matching the shared Rust vectors', () {
    final File vectors = File(
      p.join('..', 'core', 'tests', 'fixtures', 'comic_id_vectors.json'),
    );
    final List<dynamic> cases =
        (jsonDecode(vectors.readAsStringSync())
                as Map<String, dynamic>)['cases']
            as List<dynamic>;

    for (final dynamic entry in cases) {
      final Map<String, dynamic> vector = entry as Map<String, dynamic>;
      expect(
        comicIdFromPathFrb(rawPath: vector['raw'] as String),
        vector['expected_comic_id'],
        reason: vector['description'] as String,
      );
    }
  });

  test(
    'async call round-trips against a freshly initialised database',
    () async {
      final Directory appDataDir = Directory.systemTemp.createTempSync(
        'frb_wire_',
      );
      initDbFrb(appDataDir: appDataDir.path, dbFileName: 'frb_wire');

      expect(await countAllComicsFrb(), 0);
      final AuthorIdentityFrbDto author = await addAuthorFrb(
        name: 'Wire Author',
      );
      await renameAuthorByIdFrb(authorId: author.id, newName: 'Wire Renamed');
      final renamed = (await listAllAuthorsFrb()).single;
      expect(renamed.id, author.id);
      expect(renamed.name, 'Wire Renamed');
      await recordReadingActivityFrb(
        comicId: 'wire-comic',
        addDurationMs: 10000,
        markFinished: false,
      );
      final activity = await watchReadingActivityStatsFrb().first;
      expect(activity.finishedCount, 0);
      expect(activity.totalDurationMs.toInt(), 10000);
      final AuthorImageRefFrbDto image = await resolveAuthorImageFrb(
        authorId: author.id,
        showR18: false,
      );
      expect(image.avatarSource, AuthorImageSourceFrb.none);
      expect(image.avatarComicId, isNull);
      expect(image.avatarLinkId, isNull);
      expect(image.avatarImageUrl, isNull);
      expect(image.backgroundSource, AuthorImageSourceFrb.none);
      expect(image.backgroundComicId, isNull);
      expect(image.backgroundLinkId, isNull);
      expect(image.backgroundImageUrl, isNull);
    },
  );

  test('export comic metadata returns schema v1 json bytes', () {
    final Directory appDataDir = Directory.systemTemp.createTempSync(
      'frb_wire_export_',
    );
    initDbFrb(appDataDir: appDataDir.path, dbFileName: 'frb_wire_export');

    final List<int> bytes = exportComicMetadataFrb(
      options: const ExportComicMetadataOptionsDto(includeOrphanFacets: false),
    );
    final Map<String, dynamic> payload =
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect(payload['schema_version'], 1);
    expect(payload['comics'], isA<List<dynamic>>());
    expect(payload['comics'], isEmpty);
  });

  test('Rust errors cross the wire as HentaiErrorDto', () {
    expect(
      () => initDbFrb(appDataDir: '', dbFileName: 'frb_wire'),
      throwsA(
        isA<HentaiErrorDto>().having(
          (HentaiErrorDto error) => error.code,
          'code',
          'Validation',
        ),
      ),
    );
  });

  test(
    'Reader session errors cross the wire while prefetch stays best effort',
    () async {
      const comicId = 'wire-missing-reader-session';
      final missingSession = throwsA(
        isA<HentaiErrorDto>().having(
          (error) => error.code,
          'code',
          'ReaderSessionNotOpen',
        ),
      );
      await expectLater(loadPageListFrb(comicId: comicId), missingSession);
      await expectLater(
        loadPageBytesFrb(comicId: comicId, pageIndex: 0),
        missingSession,
      );
      await expectLater(
        loadReaderPageFrb(comicId: comicId, pageIndex: 0),
        missingSession,
      );
      await prefetchReaderPagesFrb(
        comicId: comicId,
        pageIndexes: [0],
        generation: BigInt.one,
      );
    },
  );
}
