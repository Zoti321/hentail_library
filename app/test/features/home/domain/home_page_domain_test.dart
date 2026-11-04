import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/domain/home_page_domain.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

void main() {
  test('HomePageCounts.isCatalogEmpty', () {
    expect(
      const HomePageCounts(
        comicCount: 0,
        tagCount: 0,
        seriesCount: 0,
        authorCount: 0,
        libraryCount: 1,
      ).isCatalogEmpty,
      isTrue,
    );
    expect(
      const HomePageCounts(
        comicCount: 1,
        tagCount: 0,
        seriesCount: 0,
        authorCount: 0,
        libraryCount: 1,
      ).isCatalogEmpty,
      isFalse,
    );
  });

  test('HomeLibraryAlert.shouldResurfaceAfterDismiss', () {
    final HomeLibraryAlert alert = HomeLibraryAlert(
      libraryId: 'lib1',
      displayName: 'Lib',
      kind: HomeLibraryAlertKind.syncFailed,
      lastErrorMessage: 'timeout',
    );
    final String key = alert.dismissKey();
    final String fingerprint = alert.dismissFingerprint();
    expect(
      alert.shouldResurfaceAfterDismiss(
        storedDismissKey: key,
        storedFingerprint: fingerprint,
      ),
      isFalse,
    );
    expect(
      alert.shouldResurfaceAfterDismiss(
        storedDismissKey: key,
        storedFingerprint: 'other',
      ),
      isTrue,
    );
  });
}
