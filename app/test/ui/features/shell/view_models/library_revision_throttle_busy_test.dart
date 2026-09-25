import 'package:hentai_library/ui/features/shell/view_models/library_revision_throttle_busy.dart';
import 'package:test/test.dart';

void main() {
  group('isLibraryRevisionThrottleBusy', () {
    test('false when sync idle and thumbnails idle', () {
      expect(
        isLibraryRevisionThrottleBusy(
          librarySyncRunning: false,
          thumbnailBackgroundActive: false,
        ),
        isFalse,
      );
    });

    test('true when library sync running alone', () {
      expect(
        isLibraryRevisionThrottleBusy(
          librarySyncRunning: true,
          thumbnailBackgroundActive: false,
        ),
        isTrue,
      );
    });

    test('true when thumbnail background active alone', () {
      expect(
        isLibraryRevisionThrottleBusy(
          librarySyncRunning: false,
          thumbnailBackgroundActive: true,
        ),
        isTrue,
      );
    });

    test('true when both sync and thumbnails busy', () {
      expect(
        isLibraryRevisionThrottleBusy(
          librarySyncRunning: true,
          thumbnailBackgroundActive: true,
        ),
        isTrue,
      );
    });
  });
}
