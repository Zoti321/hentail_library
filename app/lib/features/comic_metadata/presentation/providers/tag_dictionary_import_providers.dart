import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_metadata/application/import_tag_dictionary_use_case.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/comic_metadata_repository_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/download_providers.dart';

final importTagDictionaryUseCaseProvider = Provider<ImportTagDictionaryUseCase>(
  (ref) => ImportTagDictionaryUseCase(
    downloadGateway: ref.read(tagDictionaryDownloadGatewayProvider),
    repository: ref.read(tagRepoProvider),
  ),
);
