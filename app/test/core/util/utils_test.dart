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
}
