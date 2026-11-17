import 'package:hentai_library/features/library_admin/domain/library_scan_mode.dart';

typedef LibraryScanActivityState = ({
  bool running,
  ScanMode scanMode,
  /// null when idle or scanning all libraries.
  String? targetLibraryId,
});
