import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/metadata_management_preferences_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/comic_metadata/presentation/views/metadata/metadata_page.dart';
import 'package:hentai_library/l10n/app_localizations_zh.dart';
import 'package:hentai_library/shared/application/contracts/app_navigator.dart';
import 'package:hentai_library/shared/presentation/providers/app_navigator_provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../support/pump_app.dart';

void main() {
  for (final initiallySkipped in [false, true]) {
    testWidgets(
      'merge reads and saves injected confirmation preference: $initiallySkipped',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final selection = _Selection();
        var skipped = initiallySkipped;
        final l10n = AppLocalizationsZh();
        await pumpApp(
          tester,
          overrides: [
            appNavigatorProvider.overrideWithValue(_Navigator()),
            namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag)
                .overrideWith(() => selection),
            mergeConfirmationSkippedQueryProvider.overrideWithValue(
              () async => skipped,
            ),
            setMergeConfirmationSkippedCommandProvider.overrideWithValue((
              value,
            ) async {
              skipped = value;
            }),
          ],
          home: const Scaffold(body: MetadataManagementPage()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.metadataMergeSelectionLabel(2)));
        await tester.pumpAndSettle();
        if (!initiallySkipped) {
          expect(selection.merged, isEmpty);
          expect(find.text(l10n.metadataMergeConfirmTitle), findsOneWidget);
          await tester.tap(find.byType(M3ECheckbox).last);
          await tester.pumpAndSettle();
          expect(skipped, isTrue);
          await tester.tap(find.text(l10n.commonCancel).last);
          await tester.pumpAndSettle();
          expect(selection.merged, isEmpty);
          await tester.tap(find.text(l10n.metadataMergeSelectionLabel(2)));
          await tester.pumpAndSettle();
        }
        expect(find.text(l10n.metadataMergeConfirmTitle), findsNothing);
        expect(selection.merged, ['source']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Selection extends NamedFacetManagementViewModel {
  final merged = <String>[];
  @override
  NamedFacetManagementState build(ManagedNamedFacetKind kind) =>
      const NamedFacetManagementState(
        query: '',
        items: ['target', 'source'],
        totalCount: 2,
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        mergeTarget: 'target',
        mergeSources: {'source'},
      );
  @override
  Future<void> merge({
    required String targetName,
    required List<String> sourceNames,
  }) async {
    merged.addAll(sourceNames);
    state = state.copyWith(clearMergeTarget: true, mergeSources: {});
  }
}

class _Navigator implements AppNavigator {
  @override
  String? queryParameter(String key) => 'tags';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
