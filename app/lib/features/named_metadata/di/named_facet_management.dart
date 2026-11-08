import 'package:hentai_library/features/named_metadata/application/named_facet_management_service.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'named_facet_management.g.dart';

@Riverpod(keepAlive: true)
NamedFacetManagementService namedFacetManagementService(Ref ref) {
  return NamedFacetManagementService(
    repository: ref.watch(namedFacetManagementRepoProvider),
  );
}
