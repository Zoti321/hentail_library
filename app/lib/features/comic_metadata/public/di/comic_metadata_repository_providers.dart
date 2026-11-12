import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_metadata/domain/author_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

/// comic_metadata owner 的 Repository token（#515；实现由 bootstrap 注入）。

final Provider<TagRepository> tagRepoProvider = injectedDi('tagRepoProvider');

final Provider<AuthorRepository> authorRepoProvider = injectedDi(
  'authorRepoProvider',
);

final Provider<NamedFacetManagementRepository>
namedFacetManagementRepoProvider = injectedDi(
  'namedFacetManagementRepoProvider',
);

final Provider<NamedFacetDictionaryRepository> parodyRepoProvider = injectedDi(
  'parodyRepoProvider',
);

final Provider<NamedFacetDictionaryRepository> characterRepoProvider =
    injectedDi('characterRepoProvider');
