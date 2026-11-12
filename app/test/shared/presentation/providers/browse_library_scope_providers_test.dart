import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/presentation/providers/browse_library_scope_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('BrowseLibraryId', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('stale release after newer claim keeps the active library id', () {
      final BrowseLibraryId notifier = container.read(
        browseLibraryIdProvider.notifier,
      );

      final int oldEpoch = notifier.claim('lib-a');
      final int newEpoch = notifier.claim('lib-b');

      notifier.release(oldEpoch);
      expect(container.read(browseLibraryIdProvider), 'lib-b');

      notifier.release(newEpoch);
      expect(container.read(browseLibraryIdProvider), isNull);
    });

    test(
      'microtask clear-after-set with setId alone leaves null (legacy race)',
      () async {
        Future<void>.microtask(() {
          container.read(browseLibraryIdProvider.notifier).setId('lib-b');
        });
        Future<void>.microtask(() {
          container.read(browseLibraryIdProvider.notifier).setId(null);
        });
        await Future<void>.delayed(Duration.zero);

        expect(container.read(browseLibraryIdProvider), isNull);
      },
    );

    testWidgets(
      'same-element libraryId change keeps newer claim (sidebar switch)',
      (WidgetTester tester) async {
        // go_router pageKey is route.path (`/libraries/:libraryId`), so A→B
        // updates the same LibraryBrowsePage element; flutter_hooks then
        // schedules new claim before disposing the old effect. Epoch release
        // must ignore that stale cleanup (legacy setId(null) left scope null).
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: _BrowseScopeBinder(libraryId: 'lib-a'),
            ),
          ),
        );
        await tester.pump();
        expect(container.read(browseLibraryIdProvider), 'lib-a');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: _BrowseScopeBinder(libraryId: 'lib-b'),
            ),
          ),
        );
        await tester.pump();

        expect(
          container.read(browseLibraryIdProvider),
          'lib-b',
          reason: 'dispose release of the previous effect must not wipe the new claim',
        );
      },
    );
  });
}

/// Mirrors [LibraryBrowsePage] claim/release browse-scope lifecycle.
class _BrowseScopeBinder extends HookConsumerWidget {
  const _BrowseScopeBinder({required this.libraryId});

  final String libraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final String? scopedId = libraryId.isEmpty ? null : libraryId;
      final BrowseLibraryId scope = ref.read(browseLibraryIdProvider.notifier);
      var cancelled = false;
      int? epoch;
      Future<void>.microtask(() {
        if (cancelled) {
          return;
        }
        epoch = scope.claim(scopedId);
      });
      return () {
        cancelled = true;
        Future<void>.microtask(() {
          final int? claimed = epoch;
          if (claimed == null) {
            return;
          }
          scope.release(claimed);
        });
      };
    }, <Object?>[libraryId]);

    return const SizedBox.shrink();
  }
}
