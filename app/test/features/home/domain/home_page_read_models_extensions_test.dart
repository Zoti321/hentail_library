import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models_extensions.dart';

void main() {
  test('HomeLibraryAlertDismissSpecification.shouldResurfaceAfterDismiss', () {
    final HomeLibraryAlert alert = HomeLibraryAlert(
      libraryId: 'lib1',
      displayName: 'Lib',
      kind: HomeLibraryAlertKind.syncFailed,
      lastErrorMessage: 'timeout',
    );
    final String key = alert.dismissKey();
    final String fingerprint = alert.dismissFingerprint();
    expect(
      HomeLibraryAlertDismissSpecification.shouldResurfaceAfterDismiss(
        alert: alert,
        storedDismissKey: key,
        storedFingerprint: fingerprint,
      ),
      isFalse,
    );
    expect(
      HomeLibraryAlertDismissSpecification.shouldResurfaceAfterDismiss(
        alert: alert,
        storedDismissKey: key,
        storedFingerprint: 'other',
      ),
      isTrue,
    );
  });
}
