import 'package:hentai_library/domain/library/library_tri_state_pick.dart';

typedef LibraryMetadataFilterSets = ({
  Set<String> all,
  Set<String> any,
  Set<String> exclude,
});

/// 标签/作者共用的 Komga 三态多选筛选状态。
class LibraryMetadataFilterSelection {
  const LibraryMetadataFilterSelection({
    this.picks = const <String, LibraryTriStatePick>{},
    this.includeMode = LibraryMetadataIncludeMode.any,
  });

  final Map<String, LibraryTriStatePick> picks;
  final LibraryMetadataIncludeMode includeMode;

  bool get isActive => picks.values.any(
    (LibraryTriStatePick state) => state != LibraryTriStatePick.neutral,
  );

  LibraryTriStatePick pickStateFor(String name) =>
      picks[name] ?? LibraryTriStatePick.neutral;

  Set<String> includeNames() => picks.entries
      .where(
        (MapEntry<String, LibraryTriStatePick> entry) =>
            entry.value == LibraryTriStatePick.include,
      )
      .map((MapEntry<String, LibraryTriStatePick> entry) => entry.key)
      .toSet();

  Set<String> excludeNames() => picks.entries
      .where(
        (MapEntry<String, LibraryTriStatePick> entry) =>
            entry.value == LibraryTriStatePick.exclude,
      )
      .map((MapEntry<String, LibraryTriStatePick> entry) => entry.key)
      .toSet();

  LibraryMetadataFilterSets toFilterSets() {
    final Set<String> include = includeNames();
    final Set<String> exclude = excludeNames();
    return switch (includeMode) {
      LibraryMetadataIncludeMode.all => (
        all: include,
        any: const <String>{},
        exclude: exclude,
      ),
      LibraryMetadataIncludeMode.any => (
        all: const <String>{},
        any: include,
        exclude: exclude,
      ),
    };
  }

  LibraryMetadataFilterSelection withToggled(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    final Map<String, LibraryTriStatePick> next =
        Map<String, LibraryTriStatePick>.from(picks);
    final LibraryTriStatePick current =
        next[trimmed] ?? LibraryTriStatePick.neutral;
    final LibraryTriStatePick updated = current.next;
    if (updated == LibraryTriStatePick.neutral) {
      next.remove(trimmed);
    } else {
      next[trimmed] = updated;
    }
    return LibraryMetadataFilterSelection(
      picks: next,
      includeMode: includeMode,
    );
  }

  LibraryMetadataFilterSelection withIncludeMode(
    LibraryMetadataIncludeMode mode,
  ) {
    if (includeMode == mode) {
      return this;
    }
    return LibraryMetadataFilterSelection(picks: picks, includeMode: mode);
  }

  LibraryMetadataFilterSelection cleared() =>
      LibraryMetadataFilterSelection(includeMode: includeMode);

  static LibraryMetadataFilterSelection fromStorage({
    List<String>? includeNames,
    List<String>? excludeNames,
    String? includeModeName,
  }) {
    final Map<String, LibraryTriStatePick> picks =
        <String, LibraryTriStatePick>{};
    for (final String name in includeNames ?? const <String>[]) {
      final String trimmed = name.trim();
      if (trimmed.isNotEmpty) {
        picks[trimmed] = LibraryTriStatePick.include;
      }
    }
    for (final String name in excludeNames ?? const <String>[]) {
      final String trimmed = name.trim();
      if (trimmed.isNotEmpty) {
        picks[trimmed] = LibraryTriStatePick.exclude;
      }
    }
    return LibraryMetadataFilterSelection(
      picks: picks,
      includeMode: LibraryMetadataIncludeMode.fromStorage(includeModeName),
    );
  }

  List<String> includeNamesToStorage() => includeNames().toList()..sort();

  List<String> excludeNamesToStorage() => excludeNames().toList()..sort();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LibraryMetadataFilterSelection &&
            _mapEquals(picks, other.picks) &&
            includeMode == other.includeMode;
  }

  @override
  int get hashCode => Object.hash(_mapHash(picks), includeMode);

  static bool _mapEquals(
    Map<String, LibraryTriStatePick> a,
    Map<String, LibraryTriStatePick> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (final MapEntry<String, LibraryTriStatePick> entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static int _mapHash(Map<String, LibraryTriStatePick> map) {
    return Object.hashAll(
      map.entries.map(
        (MapEntry<String, LibraryTriStatePick> e) =>
            Object.hash(e.key, e.value),
      ),
    );
  }
}
