typedef MediaOverview = ({
  int total,
  int disabled,
  int pending,
  int processing,
  int completed,
  int failed,
  int unsupported,
  int localLibraries,
  int enabledLibraries,
});

abstract interface class WritebackGateway {
  Future<bool> isEnabled(String libraryId);
  Future<void> setEnabled(String libraryId, bool enabled);
  Future<bool> processNext();
  Future<MediaOverview> overview({required bool showR18});
}
