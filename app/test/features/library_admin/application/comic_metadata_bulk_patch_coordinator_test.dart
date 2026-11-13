import 'dart:async';

import 'package:hentai_library/features/library_admin/application/comic_metadata_bulk_patch_coordinator.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_port.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:test/test.dart';

void main() {
  group('ComicMetadataBulkPatchCoordinator', () {
    for (final scenario in [
      (
        name: 'epoch replacement with tags and authors',
        patch: ComicMetadataBulkPatch(
          publishedAt: ComicMetadataBulkPublishedAtPatch.replace(
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ),
          tags: const ComicMetadataBulkMultiValuePatch(
            op: ComicMetadataBulkMultiValueOp.add,
            values: ['new-tag'],
          ),
          authors: const ComicMetadataBulkMultiValuePatch(
            op: ComicMetadataBulkMultiValueOp.replace,
            values: ['author'],
          ),
        ),
        tags: true,
        authors: true,
        parodies: false,
        characters: false,
      ),
      (
        name: 'date clear with parodies and characters',
        patch: const ComicMetadataBulkPatch(
          publishedAt: ComicMetadataBulkPublishedAtPatch.clear(),
          description: ComicMetadataBulkDescriptionPatch.clear(),
          parodies: ComicMetadataBulkMultiValuePatch(
            op: ComicMetadataBulkMultiValueOp.remove,
            values: ['parody'],
          ),
          characters: ComicMetadataBulkMultiValuePatch(
            op: ComicMetadataBulkMultiValueOp.replace,
            values: [],
          ),
        ),
        tags: false,
        authors: false,
        parodies: true,
        characters: true,
      ),
    ]) {
      test(
        'forwards ${scenario.name} once and publishes after commit',
        () async {
          final committed = Completer<ComicMetadataBulkPatchResult>();
          final adapter = _RecordingPort(() => committed.future);
          final events = _RecordingPublisher();
          final coordinator = ComicMetadataBulkPatchCoordinator(
            adapter: adapter,
            events: events,
          );
          final ids = ['comic-2', 'comic-1', 'comic-3'];
          final result = (
            succeeded: 1,
            failed: 1,
            unchanged: 1,
            cancelled: false,
            errorSamples: ['comic-1: unavailable'],
          );

          final pending = coordinator.apply(
            comicIds: ids,
            patch: scenario.patch,
          );

          expect(adapter.calls, hasLength(1));
          expect(adapter.calls.single.comicIds, same(ids));
          expect(adapter.calls.single.patch, same(scenario.patch));
          expect(events.events, isEmpty);
          committed.complete(result);
          final actual = await pending;

          expect(actual, result);
          expect(actual.errorSamples, same(result.errorSamples));
          expect(adapter.calls, hasLength(1));
          expect(adapter.cancelCount, 0);
          expect(events.events, hasLength(1));
          final event = events.events.single as ComicMetadataPersisted;
          expect(event.tagsWritten, scenario.tags);
          expect(event.authorsWritten, scenario.authors);
          expect(event.parodiesWritten, scenario.parodies);
          expect(event.charactersWritten, scenario.characters);
          expect(event.dictionariesWritten, isTrue);
        },
      );
    }

    for (final result in [
      (
        succeeded: 0,
        failed: 2,
        unchanged: 0,
        cancelled: false,
        errorSamples: ['write failed'],
      ),
      (
        succeeded: 0,
        failed: 0,
        unchanged: 2,
        cancelled: false,
        errorSamples: <String>[],
      ),
      (
        succeeded: 0,
        failed: 0,
        unchanged: 0,
        cancelled: true,
        errorSamples: <String>[],
      ),
    ]) {
      test('does not publish with no committed success: $result', () async {
        final adapter = _RecordingPort(() async => result);
        final events = _RecordingPublisher();
        final coordinator = ComicMetadataBulkPatchCoordinator(
          adapter: adapter,
          events: events,
        );

        final actual = await coordinator.apply(
          comicIds: ['comic-1', 'comic-2'],
          patch: const ComicMetadataBulkPatch(
            publishedAt: ComicMetadataBulkPublishedAtPatch.clear(),
          ),
        );

        expect(actual, result);
        expect(adapter.calls, hasLength(1));
        expect(events.events, isEmpty);
      });
    }

    test('cancelled batch still publishes its committed success', () async {
      final result = (
        succeeded: 1,
        failed: 0,
        unchanged: 0,
        cancelled: true,
        errorSamples: <String>[],
      );
      final adapter = _RecordingPort(() async => result);
      final events = _RecordingPublisher();
      final coordinator = ComicMetadataBulkPatchCoordinator(
        adapter: adapter,
        events: events,
      );

      final actual = await coordinator.apply(
        comicIds: ['comic-1', 'comic-2'],
        patch: const ComicMetadataBulkPatch(
          publishedAt: ComicMetadataBulkPublishedAtPatch.clear(),
        ),
      );

      expect(actual, result);
      expect(adapter.calls, hasLength(1));
      expect(events.events, hasLength(1));
      final event = events.events.single as ComicMetadataPersisted;
      expect(event.tagsWritten, isFalse);
      expect(event.authorsWritten, isFalse);
      expect(event.parodiesWritten, isFalse);
      expect(event.charactersWritten, isFalse);
      expect(event.dictionariesWritten, isFalse);
    });

    test('adapter failure propagates without retry or publication', () async {
      final failure = StateError('adapter failed');
      final adapter = _RecordingPort(() async => throw failure);
      final events = _RecordingPublisher();
      final coordinator = ComicMetadataBulkPatchCoordinator(
        adapter: adapter,
        events: events,
      );

      await expectLater(
        coordinator.apply(
          comicIds: ['comic-1'],
          patch: const ComicMetadataBulkPatch(
            publishedAt: ComicMetadataBulkPublishedAtPatch.clear(),
          ),
        ),
        throwsA(same(failure)),
      );

      expect(adapter.calls, hasLength(1));
      expect(adapter.cancelCount, 0);
      expect(events.events, isEmpty);
    });

    test('publisher failure does not repeat the committed write', () async {
      final failure = StateError('publisher failed');
      final adapter = _RecordingPort(
        () async => (
          succeeded: 1,
          failed: 0,
          unchanged: 0,
          cancelled: false,
          errorSamples: <String>[],
        ),
      );
      final events = _RecordingPublisher(failure: failure);
      final coordinator = ComicMetadataBulkPatchCoordinator(
        adapter: adapter,
        events: events,
      );

      await expectLater(
        coordinator.apply(
          comicIds: ['comic-1'],
          patch: const ComicMetadataBulkPatch(contentRating: 'safe'),
        ),
        throwsA(same(failure)),
      );

      expect(adapter.calls, hasLength(1));
      expect(adapter.cancelCount, 0);
      expect(events.events, hasLength(1));
      expect(events.events.single, isA<ComicMetadataPersisted>());
    });
  });
}

class _RecordingPort implements ComicMetadataBulkPatchPort {
  _RecordingPort(this.respond);

  final Future<ComicMetadataBulkPatchResult> Function() respond;
  final calls = <({List<String> comicIds, ComicMetadataBulkPatch patch})>[];
  int cancelCount = 0;

  @override
  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  }) {
    calls.add((comicIds: comicIds, patch: patch));
    return respond();
  }

  @override
  void cancelActive() => cancelCount++;
}

class _RecordingPublisher implements DomainEventPublisher {
  _RecordingPublisher({this.failure});

  final Object? failure;
  final events = <DomainEvent>[];

  @override
  void publish(DomainEvent event) {
    events.add(event);
    if (failure case final failure?) throw failure;
  }
}
