import 'package:hentai_library/features/comic_metadata/data/adapters/author_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/data/adapters/named_facet_dictionary_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/data/adapters/named_facet_management_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/data/adapters/tag_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/data/repositories/author_repository_impl.dart';
import 'package:hentai_library/features/comic_metadata/data/repositories/named_facet_dictionary_repository_impl.dart';
import 'package:hentai_library/features/comic_metadata/data/repositories/named_facet_management_repository_impl.dart';
import 'package:hentai_library/features/comic_metadata/data/repositories/tag_repository_impl.dart';
import 'package:hentai_library/features/comic_metadata/domain/author_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
AuthorRepository createAuthorRepository({
  required NamedFacetManagementRepository namedFacets,
  AuthorFrbAdapter? adapter,
}) => AuthorRepositoryImpl(namedFacets: namedFacets, adapter: adapter);

NamedFacetManagementRepository createNamedFacetManagementRepository({
  NamedFacetManagementFrbAdapter? adapter,
}) => NamedFacetManagementRepositoryImpl(adapter: adapter);

NamedFacetDictionaryRepository createNamedFacetDictionaryRepository(
  NamedFacetKind kind, {
  NamedFacetDictionaryFrbAdapter? adapter,
}) => NamedFacetDictionaryRepositoryImpl(kind, adapter: adapter);

TagRepository createTagRepository({
  required NamedFacetManagementRepository namedFacets,
  TagFrbAdapter? tagFrbAdapter,
}) => TagRepositoryImpl(namedFacets: namedFacets, tagFrbAdapter: tagFrbAdapter);
