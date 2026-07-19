enum LibrarySeriesSortField { name, comicCount, random }

extension LibrarySeriesSortFieldX on LibrarySeriesSortField {
  bool get isImplemented => true;
}

class LibrarySeriesSortOption {
  const LibrarySeriesSortOption({
    this.field = LibrarySeriesSortField.name,
    this.descending = false,
  });

  final LibrarySeriesSortField field;
  final bool descending;

  LibrarySeriesSortOption copyWith({
    LibrarySeriesSortField? field,
    bool? descending,
  }) {
    return LibrarySeriesSortOption(
      field: field ?? this.field,
      descending: descending ?? this.descending,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LibrarySeriesSortOption &&
        other.field == field &&
        other.descending == descending;
  }

  @override
  int get hashCode => Object.hash(field, descending);
}

const LibrarySeriesSortOption kLibraryDefaultSeriesSortOption =
    LibrarySeriesSortOption();

const List<LibrarySeriesSortField> kLibrarySeriesSortFields =
    <LibrarySeriesSortField>[
      LibrarySeriesSortField.name,
      LibrarySeriesSortField.comicCount,
      LibrarySeriesSortField.random,
    ];
