import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_edit_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/widgets/catalog_selection_actions.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../../support/pump_localized_app.dart';

class _RecordingBulkEditPort implements ComicMetadataBulkEditCommandPort {
  _RecordingBulkEditPort(this.result);

  List<String>? lastComicIds;
  ComicMetadataBulkPatch? lastPatch;
  final ComicMetadataBulkPatchResult result;

  @override
  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  }) async {
    lastComicIds = List<String>.of(comicIds);
    lastPatch = patch;
    return result;
  }
}

void main() {
  testWidgets('applyComicMetadataBulkPatchForComicIds invokes command port', (
    WidgetTester tester,
  ) async {
    final _RecordingBulkEditPort port = _RecordingBulkEditPort((
      succeeded: 2,
      failed: 0,
      unchanged: 0,
      cancelled: false,
      errorSamples: <String>[],
    ));
    const ComicMetadataBulkPatch patch = ComicMetadataBulkPatch(
      tags: ComicMetadataBulkMultiValuePatch(
        op: ComicMetadataBulkMultiValueOp.add,
        values: <String>['shared-tag'],
      ),
    );

    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      overrides: <Override>[
        comicMetadataBulkEditCommandPortProvider.overrideWithValue(port),
      ],
      home: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          return Scaffold(
            body: FilledButton(
              onPressed: () => applyComicMetadataBulkPatchForComicIds(
                context,
                ref,
                comicIds: const <String>['c1', 'c2'],
                patch: patch,
              ),
              child: const Text('apply'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('apply'));
    await tester.pumpAndSettle();

    expect(port.lastComicIds, const <String>['c1', 'c2']);
    expect(port.lastPatch?.tags?.values, const <String>['shared-tag']);
    expect(find.textContaining('批量编辑完成'), findsOneWidget);
  });

  testWidgets(
    'applyComicMetadataBulkPatchForComicIds exits catalog selection when asked',
    (WidgetTester tester) async {
      final _RecordingBulkEditPort port = _RecordingBulkEditPort((
        succeeded: 1,
        failed: 0,
        unchanged: 0,
        cancelled: false,
        errorSamples: <String>[],
      ));
      const ComicMetadataBulkPatch patch = ComicMetadataBulkPatch(
        authors: ComicMetadataBulkMultiValuePatch(
          op: ComicMetadataBulkMultiValueOp.add,
          values: <String>['作者A'],
        ),
      );

      await pumpLocalizedApp(
        tester,
        wrapProviderScope: true,
        overrides: <Override>[
          comicMetadataBulkEditCommandPortProvider.overrideWithValue(port),
        ],
        home: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            final CatalogSelectionState selection = ref.watch(
              catalogSelectionProvider,
            );
            return Scaffold(
              body: Column(
                children: <Widget>[
                  Text('count:${selection.count}'),
                  FilledButton(
                    onPressed: () async {
                      ref.read(catalogSelectionProvider.notifier).toggle('c1');
                      await applyComicMetadataBulkPatchForComicIds(
                        context,
                        ref,
                        comicIds: const <String>['c1'],
                        patch: patch,
                        exitSelectionOnDone: true,
                      );
                    },
                    child: const Text('apply-exit'),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('count:0'), findsOneWidget);

      await tester.tap(find.text('apply-exit'));
      await tester.pumpAndSettle();

      expect(port.lastComicIds, const <String>['c1']);
      expect(find.text('count:0'), findsOneWidget);
    },
  );
}
