import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_metadata/public.dart';
import 'package:hentai_library/features/reading_stats/data/repositories/home_page_counts_repository_impl.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_repository.dart';

HomePageCountsRepository createHomePageCountsRepository(Ref ref) {
  final NamedFacetDictionaryRepository parodyRepository = ref.read(
    parodyRepoProvider,
  );
  final NamedFacetDictionaryRepository characterRepository = ref.read(
    characterRepoProvider,
  );
  return HomePageCountsRepositoryImpl(
    parodyRepository: parodyRepository,
    characterRepository: characterRepository,
  );
}
