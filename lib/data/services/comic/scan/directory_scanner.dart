import 'dart:io';

class DirectoryScanner {
  const DirectoryScanner();

  Stream<FileSystemEntity> scanDirectory(Directory dir) {
    return dir.list(recursive: false, followLinks: false);
  }
}

