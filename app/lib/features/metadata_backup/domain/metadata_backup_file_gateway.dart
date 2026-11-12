import 'dart:typed_data';

abstract interface class MetadataBackupFileGateway {
  Future<Uint8List> decode(List<int> bytes, String path);
  Future<List<int>> compress(Uint8List bytes);
  Future<void> write(String path, List<int> bytes);
  Future<String> prepareBackupDirectory();
  String backupPath(String directory, String fileName);
  void prune(String directory, {required int maxFiles});
}
