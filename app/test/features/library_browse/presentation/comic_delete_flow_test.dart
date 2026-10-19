import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/presentation/comic_delete_flow.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../support/pump_localized_app.dart';

class _RecordingComicTrashCommandPort implements ComicTrashCommandPort {
  final List<List<String>> trashed = <List<String>>[];

  @override
  Future<void> trash(List<String> comicIds) async {
    trashed.add(List<String>.of(comicIds));
  }
}

Comic _comic() {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return Comic(
    comicId: 'comic-1',
    path: '/library/comic-1',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: now,
    lastUpdatedAt: now,
    title: '本子A',
    contentRating: ContentRating.safe,
    authors: const [],
    tags: const [],
    languages: const [],
    parodies: const [],
    characters: const [],
    pageCount: 1,
  );
}

class _DeleteTrigger extends ConsumerWidget {
  const _DeleteTrigger({required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => confirmAndTrashComic(context, ref, comic),
          child: const Text('trigger'),
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _RecordingComicTrashCommandPort port,
) async {
  final List<Override> overrides = <Override>[
    comicTrashCommandPortProvider.overrideWithValue(port),
  ];
  await pumpLocalizedApp(
    tester,
    overrides: overrides,
    home: _DeleteTrigger(comic: _comic()),
  );
  await tester.tap(find.text('trigger'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirming the dialog trashes the comic through the port', (
    WidgetTester tester,
  ) async {
    final _RecordingComicTrashCommandPort port =
        _RecordingComicTrashCommandPort();
    await _pump(tester, port);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(port.trashed, <List<String>>[
      <String>['comic-1'],
    ]);
  });

  testWidgets('cancelling the dialog does not touch the trash port', (
    WidgetTester tester,
  ) async {
    final _RecordingComicTrashCommandPort port =
        _RecordingComicTrashCommandPort();
    await _pump(tester, port);

    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    expect(port.trashed, isEmpty);
  });
}
