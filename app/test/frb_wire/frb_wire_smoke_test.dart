import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/src/rust/api/comic.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';
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
      addTearDown(() {
        try {
          appDataDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows 下 SQLite 连接在进程结束前仍持有文件句柄。
        }
      });

      initDbFrb(appDataDir: appDataDir.path, dbFileName: 'frb_wire');

      expect(await countAllComicsFrb(), 0);
    },
  );

  test('export comic metadata returns schema v1 json bytes', () {
    final Directory appDataDir = Directory.systemTemp.createTempSync(
      'frb_wire_export_',
    );
    addTearDown(() {
      try {
        appDataDir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows 下 SQLite 连接在进程结束前仍持有文件句柄。
      }
    });

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
}
