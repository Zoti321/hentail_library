import 'package:hentai_library/domain/models/enums.dart';

/// 库页漫画 Tab 抽屉「媒体类型」可选项。
enum LibraryMediaTypeFilterOption {
  pdf,
  epub,
  archive;

  static const List<LibraryMediaTypeFilterOption> selectableOptions =
      <LibraryMediaTypeFilterOption>[
        LibraryMediaTypeFilterOption.pdf,
        LibraryMediaTypeFilterOption.epub,
        LibraryMediaTypeFilterOption.archive,
      ];

  String get label => switch (this) {
    LibraryMediaTypeFilterOption.pdf => 'PDF',
    LibraryMediaTypeFilterOption.epub => 'EPUB',
    LibraryMediaTypeFilterOption.archive => '压缩包',
  };

  Set<ResourceType> get resourceTypes => switch (this) {
    LibraryMediaTypeFilterOption.pdf => const <ResourceType>{ResourceType.pdf},
    LibraryMediaTypeFilterOption.epub => const <ResourceType>{
      ResourceType.epub,
    },
    LibraryMediaTypeFilterOption.archive => const <ResourceType>{
      ResourceType.zip,
      ResourceType.cbz,
      ResourceType.cbr,
      ResourceType.rar,
      ResourceType.cb7,
      ResourceType.sevenZ,
    },
  };
}

/// 漫画库媒体类型多选筛选状态。
class LibraryMediaTypeFilterSelection {
  const LibraryMediaTypeFilterSelection([
    this.selected = const <LibraryMediaTypeFilterOption>{},
  ]);

  final Set<LibraryMediaTypeFilterOption> selected;

  /// 是否处于有效筛选（有选中且未全选）。
  bool get isActive =>
      selected.isNotEmpty &&
      selected.length < LibraryMediaTypeFilterOption.selectableOptions.length;

  /// 漫画列表 filter；未筛选时返回 `null`（显示全部，含 `dir`）。
  Set<ResourceType>? comicResourceTypes() {
    if (!isActive) {
      return null;
    }
    return selected
        .expand((LibraryMediaTypeFilterOption option) => option.resourceTypes)
        .toSet();
  }

  LibraryMediaTypeFilterSelection withToggled(
    LibraryMediaTypeFilterOption option,
  ) {
    final Set<LibraryMediaTypeFilterOption> next =
        Set<LibraryMediaTypeFilterOption>.from(selected);
    if (next.contains(option)) {
      next.remove(option);
    } else {
      next.add(option);
    }
    if (next.length == LibraryMediaTypeFilterOption.selectableOptions.length) {
      return const LibraryMediaTypeFilterSelection();
    }
    return LibraryMediaTypeFilterSelection(next);
  }

  static LibraryMediaTypeFilterSelection fromStorage(List<String>? raw) {
    if (raw == null || raw.isEmpty) {
      return const LibraryMediaTypeFilterSelection();
    }
    final Map<String, LibraryMediaTypeFilterOption> byName =
        LibraryMediaTypeFilterOption.values.asNameMap();
    final Set<LibraryMediaTypeFilterOption> selected = raw
        .map((String name) => byName[name])
        .whereType<LibraryMediaTypeFilterOption>()
        .toSet();
    return LibraryMediaTypeFilterSelection(selected);
  }

  List<String> toStorage() =>
      selected.map((LibraryMediaTypeFilterOption e) => e.name).toList();
}
