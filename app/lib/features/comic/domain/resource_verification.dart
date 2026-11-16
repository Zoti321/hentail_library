import 'package:freezed_annotation/freezed_annotation.dart';

part 'resource_verification.freezed.dart';

enum ResourceVerificationMode {
  /// Compares source observations without reading content.
  quick,

  /// Recomputes content evidence without reusing cached fingerprints.
  strict,
}

enum ResourceVerificationStatus {
  /// No observation change was detected; content equality remains unproven.
  notDetected,
  observationChanged,
  contentMatches,
  contentChanged,
  missing,
  baselineUnavailable,

  /// Available evidence cannot decide, such as directory stats or unknown times.
  indeterminate,
}

@freezed
abstract class ResourceVerificationResult with _$ResourceVerificationResult {
  const factory ResourceVerificationResult({
    required ResourceVerificationStatus status,
    DateTime? observedModifiedAt,
    int? observedSize,
  }) = _ResourceVerificationResult;
}

typedef ComicResourceVerificationQuery =
    Future<ResourceVerificationResult> Function(
      String comicId,
      ResourceVerificationMode mode,
    );
