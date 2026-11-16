import 'package:hentai_library/core/async/cancellation_token.dart';
import 'package:hentai_library/features/comic_metadata/application/tag_dictionary_download_gateway.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';

final class TagDictionaryImportFailure implements Exception {
  const TagDictionaryImportFailure(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
}

class ImportTagDictionaryUseCase {
  const ImportTagDictionaryUseCase({
    required this.downloadGateway,
    required this.repository,
  });

  final TagDictionaryDownloadGateway downloadGateway;
  final TagRepository repository;

  Future<TagDictionaryImportResult> call({
    required String url,
    CancellationToken? cancelToken,
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    final bytes = await downloadGateway.download(
      url: url,
      cancelToken: cancelToken,
      onProgress: onDownloadProgress,
    );
    try {
      return await repository.importTagDictionary(bytes);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TagDictionaryImportFailure(error, stackTrace),
        stackTrace,
      );
    }
  }
}
