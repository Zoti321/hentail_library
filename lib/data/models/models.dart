import 'dart:io';

export 'app_settings.dart';
export 'scanned_comic_model.dart';

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
