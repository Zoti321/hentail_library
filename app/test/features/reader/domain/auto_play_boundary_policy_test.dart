import 'package:hentai_library/features/reader/domain/auto_play_boundary_policy.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:test/test.dart';

void main() {
  group('AutoPlayBoundaryPolicy.resolve', () {
    const String current = 'vol-1';

    test('comicOnce always stops', () {
      expect(
        AutoPlayBoundaryPolicy.resolve(
          mode: AutoPlayMode.comicOnce,
          currentComicId: current,
          nextComicId: 'vol-2',
          firstComicId: 'vol-1',
        ),
        isA<AutoPlayBoundaryStop>(),
      );
    });

    test('comicLoop always jumps to first page', () {
      expect(
        AutoPlayBoundaryPolicy.resolve(
          mode: AutoPlayMode.comicLoop,
          currentComicId: current,
          nextComicId: 'vol-2',
          firstComicId: 'vol-1',
        ),
        isA<AutoPlayBoundaryJumpToFirstPage>(),
      );
    });

    test('seriesOnce switches to next when available', () {
      final AutoPlayBoundaryDecision decision = AutoPlayBoundaryPolicy.resolve(
        mode: AutoPlayMode.seriesOnce,
        currentComicId: current,
        nextComicId: 'vol-2',
        firstComicId: 'vol-1',
      );
      expect(decision, isA<AutoPlayBoundarySwitchComic>());
      expect((decision as AutoPlayBoundarySwitchComic).comicId, 'vol-2');
    });

    test('seriesOnce stops on last volume', () {
      expect(
        AutoPlayBoundaryPolicy.resolve(
          mode: AutoPlayMode.seriesOnce,
          currentComicId: 'vol-2',
          nextComicId: null,
          firstComicId: 'vol-1',
        ),
        isA<AutoPlayBoundaryStop>(),
      );
    });

    test('seriesOnce without series context degrades to comicOnce', () {
      expect(
        AutoPlayBoundaryPolicy.resolve(
          mode: AutoPlayMode.seriesOnce,
          currentComicId: current,
          nextComicId: null,
          firstComicId: null,
        ),
        isA<AutoPlayBoundaryStop>(),
      );
    });

    test('seriesLoop switches to next when available', () {
      final AutoPlayBoundaryDecision decision = AutoPlayBoundaryPolicy.resolve(
        mode: AutoPlayMode.seriesLoop,
        currentComicId: current,
        nextComicId: 'vol-2',
        firstComicId: 'vol-1',
      );
      expect(decision, isA<AutoPlayBoundarySwitchComic>());
      expect((decision as AutoPlayBoundarySwitchComic).comicId, 'vol-2');
    });

    test('seriesLoop on last volume switches to first volume', () {
      final AutoPlayBoundaryDecision decision = AutoPlayBoundaryPolicy.resolve(
        mode: AutoPlayMode.seriesLoop,
        currentComicId: 'vol-2',
        nextComicId: null,
        firstComicId: 'vol-1',
      );
      expect(decision, isA<AutoPlayBoundarySwitchComic>());
      expect((decision as AutoPlayBoundarySwitchComic).comicId, 'vol-1');
    });

    test('seriesLoop without series context degrades to comicLoop', () {
      expect(
        AutoPlayBoundaryPolicy.resolve(
          mode: AutoPlayMode.seriesLoop,
          currentComicId: current,
          nextComicId: null,
          firstComicId: null,
        ),
        isA<AutoPlayBoundaryJumpToFirstPage>(),
      );
    });

    test('seriesLoop with single-volume series jumps to first page', () {
      expect(
        AutoPlayBoundaryPolicy.resolve(
          mode: AutoPlayMode.seriesLoop,
          currentComicId: current,
          nextComicId: null,
          firstComicId: current,
        ),
        isA<AutoPlayBoundaryJumpToFirstPage>(),
      );
    });
  });
}
