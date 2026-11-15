import 'package:hentai_library/features/resource_metadata/public/contracts.dart';

class ResourceMetadataTestGateway implements WritebackGateway {
  final Map<String, bool> enabled = {};
  final List<({String? libraryId, String? state, bool showR18, int offset})>
  queries = [];
  List<MediaResource> items = [];
  Object? queryError;
  int processed = 0;
  @override
  Future<bool> isEnabled(String libraryId) async => enabled[libraryId] ?? false;
  @override
  Future<void> setEnabled(String libraryId, bool value) async {
    enabled[libraryId] = value;
  }

  @override
  Future<bool> processNext() async {
    processed++;
    return false;
  }

  @override
  Future<MediaResult> query({
    String? libraryId,
    String? state,
    required bool showR18,
    required int offset,
  }) async {
    queries.add((
      libraryId: libraryId,
      state: state,
      showR18: showR18,
      offset: offset,
    ));
    if (queryError != null) {
      throw queryError!;
    }
    final filtered = items
        .where(
          (item) =>
              (libraryId == null || item.libraryId == libraryId) &&
              (state == null || item.state == state),
        )
        .toList();
    return (
      items: filtered.skip(offset).take(50).toList(),
      total: filtered.length,
    );
  }
}
