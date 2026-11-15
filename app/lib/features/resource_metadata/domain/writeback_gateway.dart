typedef MediaResource = ({
  String comicId,
  String libraryId,
  String libraryName,
  String path,
  String title,
  String format,
  String state,
  String? error,
  DateTime? lastSuccessAt,
  Map<String, String> metadata,
});

typedef MediaResult = ({List<MediaResource> items, int total});

abstract interface class WritebackGateway {
  Future<bool> isEnabled(String libraryId);
  Future<void> setEnabled(String libraryId, bool enabled);
  Future<bool> processNext();
  Future<MediaResult> query({
    String? libraryId,
    String? state,
    required bool showR18,
    required int offset,
  });
}
