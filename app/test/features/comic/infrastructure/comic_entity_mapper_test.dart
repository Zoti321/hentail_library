import 'package:hentai_library/features/comic/public/comic_metadata_types.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/infrastructure/comic_entity_mapper.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

void main() {
  test('resource fingerprint carries its own source observation through metadata edits', () {
    final mapped = mapRustComic(
      _comicDto(
        fingerprint: rust.ResourceFingerprintDto(
          digest: 'sha256-file-v1:abc',
          resourceType: 'cbz',
          modifiedMs: PlatformInt64Util.from(1600000000000),
          size: PlatformInt64Util.from(2048),
        ),
      ),
    );
    expect(mapped.resourceInfo.fingerprint?.digest, 'sha256-file-v1:abc');
    expect(mapped.resourceInfo.fingerprint?.resourceType, ResourceType.cbz);
    expect(mapped.resourceInfo.fingerprint?.observedSize, 2048);
    expect(
      mapped.resourceInfo.sourceModifiedAt,
      DateTime.fromMillisecondsSinceEpoch(1600000000000, isUtc: true),
    );
    expect(mapped.resourceInfo.sourceModifiedAt, isNot(mapped.lastUpdatedAt));
    final edited = mapped.copyWith(
      metadata: mapped.metadata.copyWith(title: 'Edited'),
    );
    expect(edited.resourceInfo.fingerprint, mapped.resourceInfo.fingerprint);
  });

  test('missing or unknown fingerprint observations stay optional', () {
    expect(mapRustComic(_comicDto()).resourceInfo.fingerprint, isNull);
    final mapped = mapRustComic(
      _comicDto(
        fingerprint: rust.ResourceFingerprintDto(
          digest: 'sha256-file-v1:abc',
          resourceType: 'cbz',
          modifiedMs: PlatformInt64Util.from(0),
          size: PlatformInt64Util.from(2048),
        ),
      ),
    );
    expect(mapped.resourceInfo.fingerprint?.digest, 'sha256-file-v1:abc');
    expect(mapped.resourceInfo.sourceModifiedAt, isNull);
  });

  test('mapRustComic maps identity facets UTC timestamps and locks', () {
    final rust.ComicDto dto = _comicDto(
      description: '简介',
      publishedAt: PlatformInt64Util.from(1600000000000),
      lastReadTimeMs: PlatformInt64Util.from(1700000900000),
    );

    final Comic mapped = mapRustComic(dto);

    expect(mapped.comicId, 'c1');
    expect(mapped.resourceInfo.path, '/lib/c1.cbz');
    expect(mapped.resourceInfo.resourceType, ResourceType.cbz);
    expect(mapped.resourceInfo.resourceSize, 2048);
    expect(mapped.metadata.title, 'Title');
    expect(mapped.metadata.contentRating, ContentRating.r18);
    expect(mapped.resourceInfo.pageCount, 12);
    expect(mapped.metadata.description, '简介');
    expect(mapped.metadata.authors.map((AuthorRef a) => a.name), <String>[
      'Alice',
      'Bob',
    ]);
    expect(mapped.metadata.authors.map((AuthorRef a) => a.id), <int?>[
      1,
      2,
    ], reason: 'Author 引用必须携带稳定 id（ADR-0024）');
    expect(mapped.metadata.tags.map((Tag t) => t.name), <String>['tag-a']);
    expect(mapped.metadata.languages, <String>['zh']);
    expect(mapped.metadata.parodies, <String>['p']);
    expect(mapped.metadata.characters, <String>['c']);

    expect(
      mapped.createdAt,
      DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
    );
    expect(mapped.createdAt.isUtc, isTrue);
    expect(
      mapped.lastUpdatedAt,
      DateTime.fromMillisecondsSinceEpoch(1700000600000, isUtc: true),
    );
    expect(
      mapped.metadata.publishedAt,
      DateTime.fromMillisecondsSinceEpoch(1600000000000, isUtc: true),
    );
    expect(
      mapped.lastReadTime,
      DateTime.fromMillisecondsSinceEpoch(1700000900000, isUtc: true),
    );

    expect(mapped.metadata.locks.title, isTrue);
    expect(mapped.metadata.locks.description, isFalse);
    expect(mapped.metadata.locks.publishedAt, isTrue);
    expect(mapped.metadata.locks.contentRating, isFalse);
    expect(mapped.metadata.locks.authors, isTrue);
    expect(mapped.metadata.locks.tags, isFalse);
    expect(mapped.metadata.locks.languages, isTrue);
    expect(mapped.metadata.locks.parodies, isFalse);
    expect(mapped.metadata.locks.characters, isTrue);
  });

  test('mapRustComic keeps absent optional metadata null', () {
    final Comic mapped = mapRustComic(_comicDto());

    expect(mapped.metadata.description, isNull);
    expect(mapped.metadata.publishedAt, isNull);
    expect(mapped.lastReadTime, isNull);
  });
}

rust.ComicDto _comicDto({
  rust.ResourceFingerprintDto? fingerprint,
  String? description,
  PlatformInt64? publishedAt,
  PlatformInt64? lastReadTimeMs,
}) {
  return rust.ComicDto(
    comicId: 'c1',
    resourceFingerprint: fingerprint,
    path: '/lib/c1.cbz',
    resourceType: 'cbz',
    resourceSize: PlatformInt64Util.from(2048),
    createdAt: PlatformInt64Util.from(1700000000000),
    lastUpdatedAt: PlatformInt64Util.from(1700000600000),
    title: 'Title',
    contentRating: 'r18',
    pageCount: 12,
    description: description,
    publishedAt: publishedAt,
    lastReadTimeMs: lastReadTimeMs,
    authors: const <rust.ComicAuthorDto>[
      rust.ComicAuthorDto(id: 1, name: 'Alice'),
      rust.ComicAuthorDto(id: 2, name: 'Bob'),
    ],
    tags: const <String>['tag-a'],
    languages: const <String>['zh'],
    parodies: const <String>['p'],
    characters: const <String>['c'],
    locks: const rust.ComicMetaLocksDto(
      title: true,
      description: false,
      publishedAt: true,
      contentRating: false,
      authors: true,
      tags: false,
      languages: true,
      parodies: false,
      characters: true,
    ),
    libraryId: 'lib-1',
  );
}
