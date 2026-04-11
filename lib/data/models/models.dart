import 'dart:io';

class DirectoryScanResult {
  final List<File> images;
  final List<Directory> subDirs;
  final bool isManga;

  DirectoryScanResult({
    required this.images,
    required this.subDirs,
    required this.isManga,
  });
}
