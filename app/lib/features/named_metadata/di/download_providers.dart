import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/named_metadata/data/services/tag_dictionary/tag_dictionary_download_service.dart';

final Provider<TagDictionaryDownloadService>
tagDictionaryDownloadServiceProvider = Provider<TagDictionaryDownloadService>(
  (Ref ref) => TagDictionaryDownloadService(),
);
