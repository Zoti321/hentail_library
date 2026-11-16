import 'package:hentai_library/features/comic/domain/resource_verification.dart';
import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/resource_verification.dart' as rust;

Future<ResourceVerificationResult> verifyComicResource(
  String comicId,
  ResourceVerificationMode mode,
) async => mapResourceVerificationResult(
  await guardFrb(
    () => rust.verifyComicResourceFrb(
      comicId: comicId,
      mode: mapResourceVerificationMode(mode),
    ),
    fallbackMessage: '检查漫画资源失败',
  ),
);

rust.ResourceVerificationModeDto mapResourceVerificationMode(
  ResourceVerificationMode mode,
) => switch (mode) {
  ResourceVerificationMode.quick => rust.ResourceVerificationModeDto.quick,
  ResourceVerificationMode.strict => rust.ResourceVerificationModeDto.strict,
};

ResourceVerificationResult mapResourceVerificationResult(
  rust.ResourceVerificationResultDto result,
) => ResourceVerificationResult(
  status: switch (result.status) {
    rust.ResourceVerificationStatusDto.notDetected =>
      ResourceVerificationStatus.notDetected,
    rust.ResourceVerificationStatusDto.observationChanged =>
      ResourceVerificationStatus.observationChanged,
    rust.ResourceVerificationStatusDto.contentMatches =>
      ResourceVerificationStatus.contentMatches,
    rust.ResourceVerificationStatusDto.contentChanged =>
      ResourceVerificationStatus.contentChanged,
    rust.ResourceVerificationStatusDto.missing =>
      ResourceVerificationStatus.missing,
    rust.ResourceVerificationStatusDto.baselineUnavailable =>
      ResourceVerificationStatus.baselineUnavailable,
    rust.ResourceVerificationStatusDto.indeterminate =>
      ResourceVerificationStatus.indeterminate,
  },
  observedModifiedAt:
      result.observedModifiedMs == null ||
          result.observedModifiedMs!.toInt() <= 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          result.observedModifiedMs!.toInt(),
          isUtc: true,
        ),
  observedSize: result.observedSize?.toInt(),
);
