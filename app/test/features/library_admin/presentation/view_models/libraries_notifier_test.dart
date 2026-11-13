import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/application/delete_library_use_case.dart';
import 'package:hentai_library/features/library_admin/application/load_libraries_use_case.dart';
import 'package:hentai_library/features/library_admin/application/submit_library_form_use_case.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_write_use_case_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/load_libraries_use_case_provider.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/libraries_notifier.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:test/test.dart';

class _Load implements LoadLibrariesUseCase {
  final results = <Future<LibrariesState>>[];
  var calls = 0;
  @override
  Future<LibrariesState> call() {
    calls++;
    return results.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements LibraryRepository {
  final results = <Future<List<LocalLibrary>>>[];
  var calls = 0;
  @override
  Future<List<LocalLibrary>> updateSidebarLayout(
    List<LibrarySidebarPlacement> placements,
  ) {
    calls++;
    return results.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Submit implements SubmitLibraryFormUseCase {
  final pending = Completer<LibraryFormApplyResult>();
  var calls = 0;
  @override
  Future<LibraryFormApplyResult> call(
    LibraryForm form, {
    LocalLibrary? original,
  }) {
    calls++;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Delete implements DeleteLibraryUseCase {
  final pending = Completer<void>();
  var calls = 0;
  @override
  Future<void> call(String libraryId) {
    calls++;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LibrariesState _state(String name) => LibrariesState(
  libraries: [
    (
      libraryId: name,
      kind: 'local',
      rootPath: '/$name',
      name: name,
      enabledResourceFormatCategories: ResourceFormatCategory.all,
      username: '',
      allowHttp: false,
      scanOnStartup: false,
      scanInterval: ScanInterval.disabled,
      pinned: true,
      sidebarOrder: 0,
    ),
  ],
);

void main() {
  late _Load load;
  late _Repository repo;
  late _Submit submit;
  late _Delete delete;
  late ProviderContainer container;
  var disposed = false;
  setUp(() {
    disposed = false;
    load = _Load();
    repo = _Repository();
    submit = _Submit();
    delete = _Delete();
    container = ProviderContainer(
      overrides: [
        loadLibrariesUseCaseProvider.overrideWithValue(load),
        libraryRepoProvider.overrideWithValue(repo),
        submitLibraryFormUseCaseProvider.overrideWithValue(submit),
        deleteLibraryUseCaseProvider.overrideWithValue(delete),
      ],
    );
    addTearDown(() {
      if (!disposed) container.dispose();
    });
  });
  LibrariesNotifier notifier() => container.read(librariesProvider.notifier);
  LibrariesState current() => container.read(librariesProvider).requireValue;
  Future<void> initialize() async {
    load.results.add(Future.value(_state('initial')));
    await container.read(librariesProvider.future);
  }

  for (final fail in [false, true]) {
    for (final sidebar in [false, true]) {
      test(
        'older refresh cannot replace a newer projection: sidebar=$sidebar fail=$fail',
        () async {
          await initialize();
          final old = Completer<LibrariesState>();
          load.results.add(old.future);
          final first = notifier().refresh();
          final next = _state('latest');
          if (sidebar) {
            repo.results.add(Future.value(next.libraries));
            await notifier().updateSidebarLayout([]);
          } else {
            load.results.add(Future.value(next));
            await notifier().refresh();
          }
          if (fail) {
            old.completeError(StateError('old load'));
          } else {
            old.complete(_state('old'));
          }
          await first;
          expect(current().libraries.single.libraryId, 'latest');
        },
      );
    }

    test('disposed refresh retains guard behavior: fail=$fail', () async {
      await initialize();
      final pending = Completer<LibrariesState>();
      load.results.add(pending.future);
      final result = notifier().refresh();
      container.dispose();
      disposed = true;
      if (fail) {
        pending.completeError(StateError('load'));
      } else {
        pending.complete(_state('late'));
      }
      await result;
    });

    test('disposed sidebar write preserves its result: fail=$fail', () async {
      await initialize();
      final pending = Completer<List<LocalLibrary>>();
      repo.results.add(pending.future);
      final result = notifier().updateSidebarLayout([]);
      final error = StateError('write');
      final checked = fail ? expectLater(result, throwsA(same(error))) : null;
      container.dispose();
      disposed = true;
      if (fail) {
        pending.completeError(error);
        await checked;
      } else {
        pending.complete(_state('late').libraries);
        await result;
      }
      expect(repo.calls, 1);
    });
  }

  for (final sidebar in [false, true]) {
    for (final oldFails in [false, true]) {
      test(
        'pending initial build adopts a replacement without rerunning load: sidebar=$sidebar oldFails=$oldFails',
        () async {
          final old = Completer<LibrariesState>();
          load.results.add(old.future);
          final subscription = container.listen(librariesProvider, (_, _) {});
          addTearDown(subscription.close);
          final next = _state('replacement');
          if (sidebar) {
            repo.results.add(Future.value(next.libraries));
            await notifier().updateSidebarLayout([]);
          } else {
            load.results.add(Future.value(next));
            await notifier().refresh();
          }
          if (oldFails) {
            old.completeError(StateError('obsolete initial load'));
          } else {
            old.complete(_state('obsolete'));
          }
          await Future<void>.delayed(Duration.zero);
          final result = await container.read(librariesProvider.future);
          expect(result.libraries, same(next.libraries));
          expect(load.calls, sidebar ? 1 : 2);
        },
      );
    }
  }

  for (final isDelete in [false, true]) {
    test(
      'owner write failure retains its cause after disposal: delete=$isDelete',
      () async {
        await initialize();
        final oldNotifier = notifier();
        final Future<Object?> result = isDelete
            ? oldNotifier.deleteLibrary('initial')
            : oldNotifier.submitLibraryForm(LibraryForm.createLocal());
        final error = StateError('owner failure');
        final expectation = expectLater(result, throwsA(same(error)));
        container.dispose();
        disposed = true;
        if (isDelete) {
          delete.pending.completeError(error);
        } else {
          submit.pending.completeError(error);
        }
        await expectation;
        expect(isDelete ? delete.calls : submit.calls, 1);
        expect(load.calls, 1);
      },
    );

    for (final rebuild in [false, true]) {
      test(
        'accepted owner write skips a replaced UI: delete=$isDelete rebuild=$rebuild',
        () async {
          await initialize();
          final oldNotifier = notifier();
          final Future<Object?> result = isDelete
              ? oldNotifier.deleteLibrary('initial')
              : oldNotifier.submitLibraryForm(LibraryForm.createLocal());
          if (rebuild) {
            load.results.add(Future.value(_state('new-build')));
            container.invalidate(librariesProvider);
            await container.read(librariesProvider.future);
          } else {
            container.dispose();
            disposed = true;
          }
          final success = const LibraryFormApplySucceeded();
          if (isDelete) {
            delete.pending.complete();
          } else {
            submit.pending.complete(success);
          }
          expect(await result, isDelete ? isNull : same(success));
          expect(load.calls, rebuild ? 2 : 1);
          if (rebuild) {
            expect(current().libraries.single.libraryId, 'new-build');
          }
          expect(isDelete ? delete.calls : submit.calls, 1);
        },
      );
    }
  }

  test('replacement refresh error retains its cause and stack without retrying load', () async {
    final initial = Completer<LibrariesState>();
    load.results.add(initial.future);
    final subscription = container.listen(librariesProvider, (_, _) {});
    addTearDown(subscription.close);
    final replacement = Completer<LibrariesState>();
    load.results.add(replacement.future);
    final refreshing = notifier().refresh();
    final error = Exception('replacement load');
    final stack = StackTrace.fromString('replacement-origin');
    replacement.completeError(error, stack);
    await refreshing;
    initial.complete(_state('obsolete'));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final value = container.read(librariesProvider);
    expect(value.error, same(error));
    expect(value.stackTrace.toString(), stack.toString());
    expect(load.calls, 2);
  });

  test(
    'refresh failure stays in state and owner deletion is not retried',
    () async {
      await initialize();
      final pending = Completer<LibrariesState>();
      load.results.add(pending.future);
      final result = notifier().deleteLibrary('initial');
      delete.pending.complete();
      await Future<void>.delayed(Duration.zero);
      final error = StateError('projection');
      pending.completeError(error);
      await result;
      expect(container.read(librariesProvider).error, same(error));
      expect(delete.calls, 1);
    },
  );

  test('adoption build does not invalidate a newer pending refresh', () async {
    final initial = Completer<LibrariesState>();
    load.results.add(initial.future);
    final subscription = container.listen(librariesProvider, (_, _) {});
    addTearDown(subscription.close);
    final controller = notifier();
    load.results.add(Future.value(_state('adopted')));
    await controller.refresh();
    final latest = Completer<LibrariesState>();
    load.results.add(latest.future);
    final refreshing = controller.refresh();
    await container.read(librariesProvider.future);
    latest.complete(_state('latest'));
    await refreshing;
    initial.complete(_state('obsolete'));
    await Future<void>.delayed(Duration.zero);
    expect(current().libraries.single.libraryId, 'latest');
    expect(load.calls, 3);
  });

  test('failed initial load waits for explicit refresh without retrying migrations', () async {
    final initial = Completer<LibrariesState>();
    load.results.add(initial.future);
    final subscription = container.listen(librariesProvider, (_, _) {});
    addTearDown(subscription.close);
    final error = Exception('initial load');
    initial.completeError(error);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(container.read(librariesProvider).error, same(error));
    expect(load.calls, 1);
    load.results.add(Future.value(_state('recovered')));
    await notifier().refresh();
    expect(current().libraries.single.libraryId, 'recovered');
    expect(load.calls, 2);
  });

  test(
    'internal projection adoption preserves accepted submit completion refresh',
    () async {
      final initial = Completer<LibrariesState>();
      load.results.add(initial.future);
      final subscription = container.listen(librariesProvider, (_, _) {});
      addTearDown(subscription.close);
      final controller = notifier();
      final submitting = controller.submitLibraryForm(
        LibraryForm.createLocal(),
      );
      load.results.add(Future.value(_state('before-commit')));
      await controller.refresh();
      await container.read(librariesProvider.future);
      load.results.add(Future.value(_state('after-commit')));
      submit.pending.complete(const LibraryFormApplySucceeded());
      await submitting;
      initial.complete(_state('obsolete'));
      await Future<void>.delayed(Duration.zero);
      expect(current().libraries.single.libraryId, 'after-commit');
      expect(load.calls, 3);
      expect(submit.calls, 1);
    },
  );
}
