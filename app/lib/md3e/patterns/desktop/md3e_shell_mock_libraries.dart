/// Lab shell mock libraries (display names only; rehearsal for Current library).
abstract final class Md3eShellMockLibraries {
  static const List<String> displayNames = <String>[
    '本地归档',
    'NAS 漫画库',
    '桌面临时库',
    'WebDAV 同步库',
    '备份只读库',
  ];

  static String get defaultDisplayName => displayNames.first;
}
