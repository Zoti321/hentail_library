import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';

class ImageSetMetadataEditDraft {
  const ImageSetMetadataEditDraft({
    required this.name,
    required this.nameLocked,
    required this.authors,
    required this.tags,
    required this.parodies,
    required this.characters,
  });

  factory ImageSetMetadataEditDraft.from({
    required ImageSet imageSet,
    required ImageSetFacets facets,
  }) => ImageSetMetadataEditDraft(
    name: imageSet.name,
    nameLocked: imageSet.nameLocked,
    authors: List<String>.from(facets.authors),
    tags: List<String>.from(facets.tags),
    parodies: List<String>.from(facets.parodies),
    characters: List<String>.from(facets.characters),
  );

  final String name;
  final bool nameLocked;
  final List<String> authors;
  final List<String> tags;
  final List<String> parodies;
  final List<String> characters;

  ImageSetMetadataEditDraft copyWith({
    String? name,
    bool? nameLocked,
    List<String>? authors,
    List<String>? tags,
    List<String>? parodies,
    List<String>? characters,
  }) => ImageSetMetadataEditDraft(
    name: name ?? this.name,
    nameLocked: nameLocked ?? this.nameLocked,
    authors: authors ?? List<String>.from(this.authors),
    tags: tags ?? List<String>.from(this.tags),
    parodies: parodies ?? List<String>.from(this.parodies),
    characters: characters ?? List<String>.from(this.characters),
  );
}