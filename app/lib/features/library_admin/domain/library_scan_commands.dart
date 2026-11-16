import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';

typedef StartLibraryScanCommand = Future<void> Function({
  ScanMode mode,
  bool syncAll,
  String? targetLibraryId,
  bool silent,
});
typedef CancelLibraryScanCommand = void Function();
