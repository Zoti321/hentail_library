import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/library_sidebar_layout.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_reorder_mode.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_sidebar_reorder_pane.dart';
import 'package:riverpod/misc.dart' show Override;

LocalLibrary _lib(String id, String name, {bool pinned = true}) => (
  libraryId: id,
  kind: 'local',
  rootPath: '/$id',
  name: name,
  enabledFormatGroups: const <FormatGroup>[],
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: pinned,
  sidebarOrder: 0,
);

Future<ProviderContainer> _pumpPane(
  WidgetTester tester,
  _FakeCurrentLibraryNotifier fake,
) async {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[currentLibraryProvider.overrideWith(() => fake)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SizedBox(
            width: 256,
            height: 640,
            child: LibrariesSidebarReorderPane(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('reorder pane shows title, both sections, and library names', (
    WidgetTester tester,
  ) async {
    await _pumpPane(
      tester,
      _FakeCurrentLibraryNotifier(
        libraries: <LocalLibrary>[
          _lib('a', 'Alpha'),
          _lib('b', 'Beta', pinned: false),
        ],
      ),
    );

    expect(find.text('重新排序'), findsOneWidget);
    expect(find.text('已固定'), findsOneWidget);
    expect(find.text('未固定'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('首页'), findsNothing);
  });

  testWidgets('exit control leaves library reorder mode', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpPane(
      tester,
      _FakeCurrentLibraryNotifier(
        libraries: <LocalLibrary>[_lib('a', 'Alpha')],
      ),
    );
    container.read(libraryReorderModeProvider.notifier).enter();
    await tester.pump();

    await tester.tap(find.byTooltip('退出排序'));
    await tester.pump();

    expect(container.read(libraryReorderModeProvider), isFalse);
  });
}

class _FakeCurrentLibraryNotifier extends CurrentLibraryNotifier {
  _FakeCurrentLibraryNotifier({required this.libraries});

  final List<LocalLibrary> libraries;

  @override
  Future<CurrentLibraryState> build() async {
    return CurrentLibraryState(
      libraries: libraries,
      currentId: libraries.first.libraryId,
    );
  }

  @override
  Future<void> updateSidebarLayout(
    List<LibrarySidebarPlacement> placements,
  ) async {}
}
