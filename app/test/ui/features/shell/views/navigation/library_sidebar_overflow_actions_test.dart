import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_sidebar_overflow_actions.dart';
import 'package:test/test.dart';

LocalLibrary _lib({required String kind}) {
  return (
    libraryId: 'lib-1',
    kind: kind,
    rootPath: kind == 'remote' ? 'https://dav.example' : r'D:\comics',
    name: 'Lib',
    enabledFormatGroups: FormatGroup.all,
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
  );
}

void main() {
  test(
    'local library: Edit immediately above Delete, refresh metadata enabled',
    () {
      expect(
        librarySidebarOverflowActions(_lib(kind: 'local')),
        <LibrarySidebarOverflowAction>[
          LibrarySidebarOverflowAction.scan,
          LibrarySidebarOverflowAction.deepScan,
          LibrarySidebarOverflowAction.refreshMetadata,
          LibrarySidebarOverflowAction.edit,
          LibrarySidebarOverflowAction.delete,
        ],
      );
    },
  );

  test('remote library: same overflow as local (edit covers connection)', () {
    expect(
      librarySidebarOverflowActions(_lib(kind: 'remote')),
      <LibrarySidebarOverflowAction>[
        LibrarySidebarOverflowAction.scan,
        LibrarySidebarOverflowAction.deepScan,
        LibrarySidebarOverflowAction.refreshMetadata,
        LibrarySidebarOverflowAction.edit,
        LibrarySidebarOverflowAction.delete,
      ],
    );
  });
}
