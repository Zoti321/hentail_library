import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/domain/library/format_group.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/shared/domain/repositories/library_repository.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/localized_test_app.dart';

/// [LibraryManagementPort.deleteLibrary] 端到端：经真实 adapter + GoRouter 验证
/// `wasViewing` 判定与删除后的导航（与 `afterLibraryDeleteNavigation` 纯函数配合）。
const List<String> _ids = <String>['a', 'b', 'c'];

LocalLibrary _library(String id) {
  return (
    libraryId: id,
    kind: 'local',
    rootPath: '/$id',
    name: id,
    enabledFormatGroups: const <FormatGroup>[],
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: true,
    sidebarOrder: 0,
  );
}

/// 与 `crud.rs::delete_library` 对齐：删当前库 → 剩余首个或 null。
class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository(this.libraries, {String? currentId})
    : _currentId = currentId;

  final List<LocalLibrary> libraries;
  String? _currentId;

  @override
  Future<List<LocalLibrary>> list() async => List<LocalLibrary>.from(libraries);

  @override
  Future<String?> getCurrentId() async => _currentId;

  @override
  Future<void> setCurrentId(String? libraryId) async {
    _currentId = libraryId;
  }

  @override
  Future<void> delete(String libraryId) async {
    libraries.removeWhere((LocalLibrary l) => l.libraryId == libraryId);
    if (_currentId == libraryId) {
      _currentId = libraries.isEmpty ? null : libraries.first.libraryId;
    }
  }

  String? get currentId => _currentId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentRevisionPort implements LibraryRevisionPort {
  @override
  Stream<void> watchRevision() => const Stream<void>.empty();
}

/// 宿主页：为每个库渲染一个按钮，点击以对应 Library 调用 `deleteLibrary`。
class _DeleteHost extends ConsumerWidget {
  const _DeleteHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          for (final String id in _ids)
            TextButton(
              key: ValueKey<String>('delete-$id'),
              onPressed: () => ref
                  .read(libraryManagementPortProvider)
                  .deleteLibrary(context, _library(id)),
              child: Text('delete-$id'),
            ),
        ],
      ),
    );
  }
}

GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/libraries/all',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('ALL')),
      ),
      GoRoute(
        path: '/libraries/:id',
        builder: (BuildContext context, GoRouterState state) =>
            const _DeleteHost(),
      ),
    ],
  );
}

class _Harness {
  _Harness(this.container, this.router, this.repo);

  final ProviderContainer container;
  final GoRouter router;
  final _FakeLibraryRepository repo;

  String get path => router.routeInformationProvider.value.uri.path;

  String? get currentIdInState =>
      container.read(currentLibraryProvider).requireValue.currentId;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required List<String> libraryIds,
  required String? currentId,
  required String initialLocation,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'migrated_enabled_format_groups_to_libraries_v1': true,
    'migrated_auto_scan_to_libraries_v1': true,
  });
  final _FakeLibraryRepository repo = _FakeLibraryRepository(
    libraryIds.map(_library).toList(),
    currentId: currentId,
  );
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      libraryRepoProvider.overrideWithValue(repo),
      libraryRevisionPortProvider.overrideWithValue(_SilentRevisionPort()),
      ...sharedLibraryStateOverrides(),
    ],
  );
  addTearDown(container.dispose);
  await container.read(currentLibraryProvider.future);
  final GoRouter router = _router(initialLocation);
  addTearDown(router.dispose);
  final config = localizedTestAppConfig();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: config.locale,
        localizationsDelegates: config.delegates,
        supportedLocales: config.locales,
        theme: buildAppTheme(Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container, router, repo);
}

Future<void> _tapDelete(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey<String>('delete-$id')));
  await tester.pumpAndSettle();
}

Future<void> _confirmRemove(WidgetTester tester) async {
  await tester.tap(find.byType(DestructiveFilledButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'deleting the viewed current library navigates to the first remaining one',
    (WidgetTester tester) async {
      final _Harness h = await _pump(
        tester,
        libraryIds: <String>['a', 'b', 'c'],
        currentId: 'a',
        initialLocation: '/libraries/a',
      );

      await _tapDelete(tester, 'a');
      await _confirmRemove(tester);

      expect(h.repo.libraries.map((LocalLibrary l) => l.libraryId), <String>[
        'b',
        'c',
      ]);
      expect(h.repo.currentId, 'b');
      expect(h.currentIdInState, 'b');
      expect(h.path, '/libraries/b');
    },
  );

  testWidgets(
    'deleting a library that is neither viewed nor current does not navigate',
    (WidgetTester tester) async {
      final _Harness h = await _pump(
        tester,
        libraryIds: <String>['a', 'b', 'c'],
        currentId: 'a',
        initialLocation: '/libraries/b',
      );

      await _tapDelete(tester, 'c');
      await _confirmRemove(tester);

      expect(h.repo.libraries.map((LocalLibrary l) => l.libraryId), <String>[
        'a',
        'b',
      ]);
      expect(h.currentIdInState, 'a');
      expect(h.path, '/libraries/b');
    },
  );

  testWidgets('cancel keeps the library and the current selection', (
    WidgetTester tester,
  ) async {
    final _Harness h = await _pump(
      tester,
      libraryIds: <String>['a', 'b'],
      currentId: 'a',
      initialLocation: '/libraries/a',
    );

    await _tapDelete(tester, 'a');
    await tester.tap(
      find
          .descendant(
            of: find.byType(HentaiDialog),
            matching: find.byType(TextButton),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(h.repo.libraries.length, 2);
    expect(h.currentIdInState, 'a');
    expect(h.path, '/libraries/a');
  });

  testWidgets('deleting the last library navigates to all libraries', (
    WidgetTester tester,
  ) async {
    final _Harness h = await _pump(
      tester,
      libraryIds: <String>['a'],
      currentId: 'a',
      initialLocation: '/libraries/a',
    );

    await _tapDelete(tester, 'a');
    await _confirmRemove(tester);

    expect(h.repo.libraries, isEmpty);
    expect(h.repo.currentId, isNull);
    expect(h.path, '/libraries/all');
    expect(find.text('ALL'), findsOneWidget);
  });
}
