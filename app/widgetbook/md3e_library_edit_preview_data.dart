import 'package:hentai_library/shared/domain/library/resource_format_category.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

/// Widgetbook / Lab 用的 Library 编辑样例。
abstract final class Md3eLibraryEditPreviewData {
  static LocalLibrary get sampleLocalLibrary => (
    libraryId: 'lab-local-1',
    kind: 'local',
    rootPath: r'D:\library\NAS 漫画库',
    name: 'NAS 漫画库',
    enabledResourceFormatCategories: List<ResourceFormatCategory>.from(ResourceFormatCategory.all),
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
