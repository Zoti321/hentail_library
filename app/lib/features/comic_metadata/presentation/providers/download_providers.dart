import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_metadata/application/tag_dictionary_download_gateway.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<TagDictionaryDownloadGateway>
tagDictionaryDownloadGatewayProvider = requiredProvider(
  'tagDictionaryDownloadGatewayProvider',
);
