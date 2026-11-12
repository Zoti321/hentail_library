import 'package:hentai_library/features/comic_metadata/application/named_facet_management_service.dart';
import 'package:hentai_library/features/comic_metadata/public/di/comic_metadata_repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'named_facet_management.g.dart';

@Riverpod(keepAlive: true)
NamedFacetManagementService namedFacetManagementService(Ref ref) {
  return NamedFacetManagementService(
    repository: ref.watch(namedFacetManagementRepoProvider),
  );
}
