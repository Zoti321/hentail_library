import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/domain/resource_verification.dart';
import 'package:hentai_library/features/comic/infrastructure/resource_verification_frb_adapter.dart';
import 'package:hentai_library/src/rust/api/resource_verification.dart' as rust;

void main() {
  test('verification mapping preserves distinct evidence outcomes', () {
    const cases = [
      (
        rust.ResourceVerificationStatusDto.notDetected,
        ResourceVerificationStatus.notDetected,
      ),
      (
        rust.ResourceVerificationStatusDto.observationChanged,
        ResourceVerificationStatus.observationChanged,
      ),
      (
        rust.ResourceVerificationStatusDto.contentMatches,
        ResourceVerificationStatus.contentMatches,
      ),
      (
        rust.ResourceVerificationStatusDto.contentChanged,
        ResourceVerificationStatus.contentChanged,
      ),
      (
        rust.ResourceVerificationStatusDto.missing,
        ResourceVerificationStatus.missing,
      ),
      (
        rust.ResourceVerificationStatusDto.baselineUnavailable,
        ResourceVerificationStatus.baselineUnavailable,
      ),
      (
        rust.ResourceVerificationStatusDto.indeterminate,
        ResourceVerificationStatus.indeterminate,
      ),
    ];
    for (final (wire, expected) in cases) {
      final result = mapResourceVerificationResult(
        rust.ResourceVerificationResultDto(
          status: wire,
          observedModifiedMs: PlatformInt64Util.from(1700000000000),
          observedSize: PlatformInt64Util.from(3000),
        ),
      );
      expect(result.status, expected);
      expect(result.observedModifiedAt, DateTime.utc(2023, 11, 14, 22, 13, 20));
      expect(result.observedSize, 3000);
    }
    expect(
      mapResourceVerificationMode(ResourceVerificationMode.quick),
      rust.ResourceVerificationModeDto.quick,
    );
    expect(
      mapResourceVerificationMode(ResourceVerificationMode.strict),
      rust.ResourceVerificationModeDto.strict,
    );
  });

  test(
    'unknown source observations remain unknown instead of epoch timestamps',
    () {
      for (final modified in [null, PlatformInt64Util.from(0)]) {
        final result = mapResourceVerificationResult(
          rust.ResourceVerificationResultDto(
            status: rust.ResourceVerificationStatusDto.indeterminate,
            observedModifiedMs: modified,
          ),
        );
        expect(result.observedModifiedAt, isNull);
        expect(result.observedSize, isNull);
      }
    },
  );
}
