import 'package:hentai_library/features/named_metadata/data/repositories/author_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/named_facet_dictionary_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/named_facet_management_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/data/repositories/tag_repository_impl.dart';
import 'package:hentai_library/features/named_metadata/domain/author_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/named_metadata/domain/tag_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
AuthorRepository createAuthorRepository() => const AuthorRepositoryImpl();

NamedFacetManagementRepository createNamedFacetManagementRepository() =>
    const NamedFacetManagementRepositoryImpl();

NamedFacetDictionaryRepository createNamedFacetDictionaryRepository(
  NamedFacetKind kind,
) => NamedFacetDictionaryRepositoryImpl(kind);

TagRepository createTagRepository({
  required NamedFacetManagementRepository namedFacets,
}) => TagRepositoryImpl(namedFacets: namedFacets);
