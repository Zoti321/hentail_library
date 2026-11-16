import 'package:hentai_library/features/resource_metadata/public/contracts.dart';

class ResourceMetadataTestGateway implements WritebackGateway {
  final Map<String, bool> enabled = {};
  final List<bool> queries = [];
  MediaOverview summary = (
    total: 24,
    disabled: 6,
    pending: 3,
    processing: 1,
    completed: 12,
    failed: 1,
    unsupported: 1,
    localLibraries: 2,
    enabledLibraries: 1,
  );
  Object? queryError;
  Future<void>? queryDelay;
  Future<void>? enabledDelay;
  int enabledReads = 0;
  int processed = 0;
  int remainingJobs = 0;
  @override
  Future<bool> isEnabled(String libraryId) async {
    enabledReads++;
    await enabledDelay;
    return enabled[libraryId] ?? false;
  }

  @override
  Future<void> setEnabled(String libraryId, bool value) async =>
      enabled[libraryId] = value;
  @override
  Future<bool> processNext() async {
    processed++;
    if (remainingJobs == 0) {
      return false;
    }
    remainingJobs--;
    return true;
  }

  @override
  Future<MediaOverview> overview({required bool showR18}) async {
    queries.add(showR18);
    await queryDelay;
    if (queryError != null) {
      throw queryError!;
    }
    return summary;
  }
}
