/// 跨 feature 只读类型（真源仍在 owner `domain/`，此处 re-export，ADR-0034）。
library;

export 'package:hentai_library/features/named_metadata/domain/author_repository.dart';
export 'package:hentai_library/features/named_metadata/domain/named_facet_dictionary_repository.dart';
export 'package:hentai_library/features/named_metadata/domain/named_facet_form_candidate.dart';
export 'package:hentai_library/features/named_metadata/domain/managed_named_facet_kind.dart';
export 'package:hentai_library/features/named_metadata/domain/named_facet_form_listing.dart';
export 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
export 'package:hentai_library/features/named_metadata/domain/tag_repository.dart';
