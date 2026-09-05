import 'package:hentai_library/core/util/utils.dart';
import 'package:test/test.dart';

void main() {
  group('shouldTreatExplorerSelectAsFailure', () {
    test('windows exit code 1 is not a failure', () {
      expect(
        shouldTreatExplorerSelectAsFailure(isWindows: true, exitCode: 1),
        isFalse,
      );
    });

    test('windows exit code 0 is not a failure', () {
      expect(
        shouldTreatExplorerSelectAsFailure(isWindows: true, exitCode: 0),
        isFalse,
      );
    });

    test('non-windows non-zero exit code is a failure', () {
      expect(
        shouldTreatExplorerSelectAsFailure(isWindows: false, exitCode: 1),
        isTrue,
      );
    });

    test('non-windows zero exit code is not a failure', () {
      expect(
        shouldTreatExplorerSelectAsFailure(isWindows: false, exitCode: 0),
        isFalse,
      );
    });
  });

  group('toWindowsExplorerPath', () {
    test(
      'converts posix separators so explorer does not treat them as switches',
      () {
        expect(
          toWindowsExplorerPath(r'D:/library/Series A'),
          r'D:\library\Series A',
        );
      },
    );

    test('leaves native windows separators unchanged', () {
      expect(
        toWindowsExplorerPath(r'D:\library\Series A'),
        r'D:\library\Series A',
      );
    });

    test('handles mixed separators', () {
      expect(
        toWindowsExplorerPath(r'D:/library\Series A/vol1.cbz'),
        r'D:\library\Series A\vol1.cbz',
      );
    });
  });
}
