import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_cover_editor_notifier.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/presentation/providers/cover_command_providers.dart';
import 'package:test/test.dart';

const _comic = ReaderComicRef(
  comicId: 'comic-1',
  path: '/library/comic-1.zip',
  resourceType: ResourceType.zip,
  title: 'Comic',
  pageCount: 10,
);

void main() {
  test(
    'commands are lazy and receive the original source and page parameters',
    () async {
      final calls = <Map<String, Object>>[];
      final container = _container((request) async => calls.add(request));
      final editor = container.read(readerCoverEditorProvider.notifier);
      expect(calls, isEmpty);
      await editor.setComicCover(_comic, pageIndex: 0);
      await editor.setSeriesCover(' series-1 ', _comic, pageIndex: 2);
      expect(calls, [
        {
          'comicId': 'comic-1',
          'path': '/library/comic-1.zip',
          'resourceType': ResourceType.zip,
          'pageIndex': 0,
        },
        {
          'seriesId': ' series-1 ',
          'comicId': 'comic-1',
          'path': '/library/comic-1.zip',
          'resourceType': ResourceType.zip,
          'pageIndex': 2,
        },
      ]);
    },
  );

  for (final series in [false, true]) {
    test(
      'the $series command future and failures propagate without retry',
      () async {
        final response = Completer<void>();
        final calls = <Map<String, Object>>[];
        final failure = StateError('cover write');
        final container = _container((request) {
          calls.add(request);
          return response.future;
        });
        final editor = container.read(readerCoverEditorProvider.notifier);
        final pending = series
            ? editor.setSeriesCover('series-1', _comic, pageIndex: 2)
            : editor.setComicCover(_comic, pageIndex: 4);
        expect(calls, hasLength(1));
        final assertion = expectLater(pending, throwsA(same(failure)));
        response.completeError(failure);
        await assertion;
        expect(calls, hasLength(1));
      },
    );
  }
}

ProviderContainer _container(
  Future<void> Function(Map<String, Object>) invoke,
) {
  final container = ProviderContainer(
    overrides: [
      setComicCoverFromPageCommandProvider.overrideWithValue(
        ({
          required String comicId,
          required String path,
          required ResourceType resourceType,
          required int pageIndex,
        }) => invoke({
          'comicId': comicId,
          'path': path,
          'resourceType': resourceType,
          'pageIndex': pageIndex,
        }),
      ),
      setSeriesCoverFromPageCommandProvider.overrideWithValue(
        ({
          required String seriesId,
          required String comicId,
          required String path,
          required ResourceType resourceType,
          required int pageIndex,
        }) => invoke({
          'seriesId': seriesId,
          'comicId': comicId,
          'path': path,
          'resourceType': resourceType,
          'pageIndex': pageIndex,
        }),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
