import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';

/// Widgetbook / Lab 用的 Library 编辑样例。
abstract final class LibraryEditPreviewData {
  static LocalLibrary get sampleLocalLibrary => (
    libraryId: 'lab-local-1',
    kind: 'local',
    rootPath: r'D:\library\NAS 漫画库',
    name: 'NAS 漫画库',
    enabledResourceFormatCategories: List<ResourceFormatCategory>.from(
      ResourceFormatCategory.all,
    ),
    username: '',
    allowHttp: false,
    scanOnStartup: true,
    scanInterval: ScanInterval.daily,
    pinned: true,
    sidebarOrder: 0,
  );

  static LocalLibrary get sampleRemoteLibrary => (
    libraryId: 'lab-remote-1',
    kind: 'remote',
    rootPath: 'https://nas.example/dav/comics',
    name: 'WebDAV 同步库',
    enabledResourceFormatCategories: ResourceFormatCategory.all
        .where((ResourceFormatCategory g) => g != ResourceFormatCategory.folder)
        .toList(growable: false),
    username: 'reader',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.every12Hours,
    pinned: false,
    sidebarOrder: 1,
  );

  static LibraryForm editLocalForm() =>
      LibraryForm.fromLibrary(sampleLocalLibrary);

  static LibraryForm editRemoteForm() =>
      LibraryForm.fromLibrary(sampleRemoteLibrary);
}
