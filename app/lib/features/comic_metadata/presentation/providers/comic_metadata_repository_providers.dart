import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_listing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_metadata/domain/author_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

/// comic_metadata owner 的 Repository token（#515；实现由 bootstrap 注入）。

final Provider<TagRepository> tagRepoProvider = requiredProvider(
  'tagRepoProvider',
);

final Provider<AuthorRepository> authorRepoProvider = requiredProvider(
  'authorRepoProvider',
);

final Provider<NamedFacetManagementRepository>
namedFacetManagementRepoProvider = requiredProvider(
  'namedFacetManagementRepoProvider',
);

final Provider<NamedFacetDictionaryRepository> parodyRepoProvider =
    requiredProvider('parodyRepoProvider');

final Provider<NamedFacetDictionaryRepository> characterRepoProvider =
    requiredProvider('characterRepoProvider');

final Provider<NamedFacetFormListing> namedFacetFormListingProvider =
    requiredProvider('namedFacetFormListingProvider');
