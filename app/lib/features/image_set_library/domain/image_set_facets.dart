/// Author / Tag / Parody / Character bindings for one Image set (each name ASC).
class ImageSetFacets {
  const ImageSetFacets({
    this.authors = const <String>[],
    this.tags = const <String>[],
    this.parodies = const <String>[],
    this.characters = const <String>[],
  });

  static const ImageSetFacets empty = ImageSetFacets();

  final List<String> authors;
  final List<String> tags;
  final List<String> parodies;
  final List<String> characters;

  bool get isEmpty =>
      authors.isEmpty && tags.isEmpty && parodies.isEmpty && characters.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageSetFacets &&
          _listEq(authors, other.authors) &&
          _listEq(tags, other.tags) &&
          _listEq(parodies, other.parodies) &&
          _listEq(characters, other.characters);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(authors),
    Object.hashAll(tags),
    Object.hashAll(parodies),
    Object.hashAll(characters),
  );
}

bool _listEq(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
