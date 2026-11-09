import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/named_metadata/public.dart';
import 'package:hentai_library/features/reading_stats/data/repositories/home_page_counts_repository_impl.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/library/home_page_counts.dart';
import 'package:hentai_library/shared/domain/ports/home_page_counts_port.dart';

class _HomePageCountsPortAdapter implements HomePageCountsPort {
  _HomePageCountsPortAdapter(this._repository);

  final HomePageCountsRepository _repository;

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return _repository.watchHomePageCounts(excludeR18: excludeR18);
  }
}

HomePageCountsPort createHomePageCountsPort(Ref ref) {
  final NamedFacetDictionaryRepository parodyRepository = ref.read(
    parodyRepoProvider,
  );
  final NamedFacetDictionaryRepository characterRepository = ref.read(
    characterRepoProvider,
  );
  return _HomePageCountsPortAdapter(
    HomePageCountsRepositoryImpl(
      parodyRepository: parodyRepository,
      characterRepository: characterRepository,
    ),
  );
}
