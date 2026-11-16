/// Product presenter contract: saving includes navigation, owned by the host.
abstract interface class MetadataEditSaveActions {
  Future<void> saveAndPop();
}
