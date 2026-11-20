/// Replace-all facet patch for Image set metadata edit (`null` = leave unchanged).
class ImageSetFacetsPatch {
  const ImageSetFacetsPatch({
    this.authors,
    this.tags,
    this.parodies,
    this.characters,
  });

  final List<String>? authors;
  final List<String>? tags;
  final List<String>? parodies;
  final List<String>? characters;
}