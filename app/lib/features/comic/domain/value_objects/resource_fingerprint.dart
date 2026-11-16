import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

part 'resource_fingerprint.freezed.dart';

@freezed
abstract class ResourceFingerprint with _$ResourceFingerprint {
  const factory ResourceFingerprint({
    /// The versioned SHA-256 evidence, including its scheme prefix.
    ///
    /// `sha256-file-v1` covers all file bytes; `sha256-pages-v1` combines
    /// image bytes in reading order. Neither is a Comic identity.
    required String digest,
    required ResourceType resourceType,
    required int observedSize,

    /// The saved observation's modification time, or `null` when unknown.
    DateTime? sourceModifiedAt,
  }) = _ResourceFingerprint;
}
