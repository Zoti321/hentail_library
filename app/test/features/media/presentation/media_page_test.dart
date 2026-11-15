import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/media/public/widgets.dart';
import 'package:hentai_library/features/resource_metadata/public/providers.dart';
import 'package:hentai_library/features/resource_metadata/public/widgets.dart';
import 'package:hentai_library/features/library_admin/public/providers.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/l10n/app_localizations.dart';

import '../../../support/fakes/resource_metadata_test_gateway.dart';
import '../../../support/fakes/settings_test_fakes.dart';
import '../../../support/pump_localized_app.dart';

class _Libraries extends LibrariesNotifier {
  @override
  Future<LibrariesState> build() async => const LibrariesState(libraries: []);
}

Future<void> _pump(
  WidgetTester tester,
  ResourceMetadataTestGateway gateway, {
  Future<void> Function(String)? edit,
}) async {
  await pumpLocalizedApp(
    tester,
    overrides: [
      writebackGatewayProvider.overrideWithValue(gateway),
      librariesProvider.overrideWith(_Libraries.new),
      settingsProvider.overrideWith(() => FakeSettingsNotifier()),
    ],
    home: MediaPage(
      onEdit: (context, ref, id) async {
        await edit?.call(id);
      },
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'automatic lifecycle ticks while active and stops after disposal',
    (tester) async {
      final gateway = ResourceMetadataTestGateway();
      await pumpLocalizedApp(
        tester,
        overrides: [writebackGatewayProvider.overrideWithValue(gateway)],
        home: const WritebackLifecycle(child: SizedBox.shrink()),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(gateway.processed, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      expect(gateway.processed, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(gateway.processed, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      expect(gateway.processed, 2);
    },
  );
  testWidgets(
    'metadata detail shows state and reuses editing without manual writes',
    (tester) async {
      final gateway = ResourceMetadataTestGateway();
      gateway.items = [
        (
          comicId: 'c1',
          libraryId: 'lib',
          libraryName: 'Local',
          path: '/book.cbz',
          title: 'Book',
          format: 'cbz',
          state: 'failed',
          error: 'Read only',
          lastSuccessAt: null,
          metadata: {'title': 'Book', 'authors': 'Author'},
        ),
      ];
      String? edited;
      await _pump(
        tester,
        gateway,
        edit: (id) async {
          edited = id;
        },
      );
      expect(find.textContaining('Read only'), findsOneWidget);
      await tester.tap(find.text('Book'));
      await tester.pumpAndSettle();
      expect(find.textContaining('/book.cbz'), findsOneWidget);
      expect(find.textContaining('Author'), findsOneWidget);
      final l10n = AppLocalizations.of(tester.element(find.byType(MediaPage)));
      await tester.tap(find.text(l10n.mediaEdit));
      await tester.pumpAndSettle();
      expect(edited, 'c1');
      expect(gateway.processed, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('filter queries state and empty/error states remain visible', (
    tester,
  ) async {
    final gateway = ResourceMetadataTestGateway();
    await _pump(tester, gateway);
    final l10n = AppLocalizations.of(tester.element(find.byType(MediaPage)));
    expect(find.text(l10n.mediaEmpty), findsOneWidget);
    await tester.tap(find.text(l10n.mediaAllStates));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.writebackFailed).last);
    await tester.pumpAndSettle();
    expect(gateway.queries.last.state, 'failed');
    gateway.queryError = StateError('unavailable');
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(MediaPage)),
    );
    scope.read(writebackRevisionProvider.notifier).changed();
    await tester.pumpAndSettle();
    expect(find.text(l10n.shellLoadFailed), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'opt in needs affirmative explanation and shares the persisted setting',
    (tester) async {
      final gateway = ResourceMetadataTestGateway();
      await pumpLocalizedApp(
        tester,
        overrides: [writebackGatewayProvider.overrideWithValue(gateway)],
        home: const Scaffold(body: WritebackSetting(libraryId: 'lib')),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(WritebackSetting)),
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text(l10n.writebackConfirmTitle), findsOneWidget);
      expect(gateway.enabled['lib'], isNull);
      await tester.tap(find.text(l10n.writebackEnable));
      await tester.pumpAndSettle();
      expect(gateway.enabled['lib'], isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    },
  );
}
