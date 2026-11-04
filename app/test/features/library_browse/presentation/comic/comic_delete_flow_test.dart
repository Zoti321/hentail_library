import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/comic_delete_flow.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

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

Finder _dialogAction(AppLocalizations l10n, String label) {
  return find.descendant(
    of: find.byType(M3EDialog),
    matching: find.text(label),
  );
}

void main() {
  testWidgets('trash confirm uses M3EDialog without destructive styling', (
    WidgetTester tester,
  ) async {
    final _RecordingComicTrashCommandPort port =
        _RecordingComicTrashCommandPort();
    final AppLocalizations l10n = await _pumpAndL10n(tester, port);

    expect(find.byType(M3EDialog), findsOneWidget);
    expect(find.textContaining('将移入「已删除」'), findsOneWidget);
    expect(find.byType(M3ECheckbox), findsNothing);

    await tester.tap(_dialogAction(l10n, l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(port.trashed, isEmpty);
  });

  testWidgets('confirming the dialog trashes the comic through the port', (
    WidgetTester tester,
  ) async {
    final _RecordingComicTrashCommandPort port =
        _RecordingComicTrashCommandPort();
    final AppLocalizations l10n = await _pumpAndL10n(tester, port);

    await tester.tap(_dialogAction(l10n, l10n.commonDelete));
    await tester.pumpAndSettle();

    expect(port.trashed, <List<String>>[
      <String>['comic-1'],
    ]);
    expect(find.text(l10n.comicTrashedToast), findsOneWidget);
    expect(find.byType(M3ESnackbar), findsOneWidget);
  });

  testWidgets('cancelling the dialog does not touch the trash port', (
    WidgetTester tester,
  ) async {
    final _RecordingComicTrashCommandPort port =
        _RecordingComicTrashCommandPort();
    final AppLocalizations l10n = await _pumpAndL10n(tester, port);

    await tester.tap(_dialogAction(l10n, l10n.commonCancel));
    await tester.pumpAndSettle();

    expect(port.trashed, isEmpty);
  });
}

Future<AppLocalizations> _pumpAndL10n(
  WidgetTester tester,
  _RecordingComicTrashCommandPort port,
) async {
  await _pump(tester, port);
  return AppLocalizations.of(tester.element(find.byType(M3EDialog)))!;
}
