import 'package:hentai_library/features/comic_metadata/infrastructure/adapters/author_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/adapters/named_facet_dictionary_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/adapters/named_facet_management_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/adapters/tag_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/repositories/author_repository_impl.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/repositories/named_facet_dictionary_repository_impl.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/repositories/named_facet_management_repository_impl.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/repositories/tag_repository_impl.dart';
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
