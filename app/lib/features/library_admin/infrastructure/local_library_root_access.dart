import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Request native filesystem access used by Local Resource access.
///
/// Desktop is always granted. Android 11+ opens the all-files access settings
/// page when needed; older Android uses legacy storage permission.
Future<bool> ensureLocalFilesystemAccess() async {
  if (kIsWeb || !Platform.isAndroid) {
    return true;
  }
  final PermissionStatus manage = await Permission.manageExternalStorage
      .request();
  if (manage.isGranted) {
    return true;
  }
  final PermissionStatus storage = await Permission.storage.request();
  return storage.isGranted;
}

/// Whether [path] is a directory this process can list via `dart:io`
/// (same class of access Rust `std::fs` uses).
Future<bool> isLocalLibraryRootReadable(String path) async {
  final String trimmed = path.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (kIsWeb) {
    return false;
  }
  final Directory dir = Directory(trimmed);
  try {
    if (!await dir.exists()) {
      return false;
    }
    await dir.list(followLinks: false).take(1).toList();
    return true;
  } on FileSystemException {
    return false;
  }
}
